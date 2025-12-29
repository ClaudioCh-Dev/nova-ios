import UIKit
import CoreData
import MapKit
import CoreLocation
import AudioToolbox
import AVFoundation
import Contacts

class HomeViewController: UIViewController, MKMapViewDelegate, AVAudioRecorderDelegate {

    var usuarioSesion: UserDetail?

    @IBOutlet weak var bottomSheetBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnConfiguracion: UIButton!
    @IBOutlet weak var btnPerfil: UIButton!
    @IBOutlet weak var btnModoDiscreto: UIButton!
    @IBOutlet weak var btnDesactivar: UIButton!
    @IBOutlet weak var btnAgregarContacto: UIButton!
    @IBOutlet weak var panelContactos: UICollectionView!

    let locationManager = CLLocationManager()
    private var isOpen = false
    
    var isServiceActive: Bool = false
    var soundTimer: Timer?
    var contactos: [ContactoUI] = []
    var currentEventId: Int?
    var locationUpdateTimer: Timer?
    var contactosGuardados: [ContactoEntity] = []
    private var lastSentAt: Date?
    private let minSendInterval: TimeInterval = 10
    private var lastSentCoord: CLLocationCoordinate2D?
    private let minDistanceMeters: CLLocationDistance = 10
    private var bgTaskId: UIBackgroundTaskIdentifier = .invalid
    
    var audioRecorder: AVAudioRecorder?
    var nombreArchivoAudioActual: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupCollectionView()
        actualizarEstiloModoDiscreto()
        actualizarUIBotonPrincipal()
        cargarContactosLocales()
        NotificationCenter.default.addObserver(self, selector: #selector(handleEmergencyShortcut), name: NSNotification.Name("TriggerNovaEmergency"), object: nil)
        solicitarPermisosAudio()
    }
    
    func solicitarPermisosAudio() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { allowed in
                if !allowed {
                    print("Permiso de micrófono denegado (iOS 17+)")
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                if !allowed {
                    print("Permiso de micrófono denegado (Legacy)")
                }
            }
        }
    }
    
    @objc func handleEmergencyShortcut() {
        if !isServiceActive {
            funcionBtnDesactivar(btnDesactivar)
        }
    }

    func cargarContactosLocales() {
        let fetchRequest: NSFetchRequest<ContactoEntity> = ContactoEntity.fetchRequest()
        do {
            contactosGuardados = try CoreDataManager.shared.context.fetch(fetchRequest)
            DispatchQueue.main.async {
                self.panelContactos.reloadData()
                self.panelContactos.layoutIfNeeded()
            }
        } catch {
            print("Error cargando contactos: \(error)")
        }
    }

    func guardarContactoEnCoreData(nombre: String, telefono: String, id: String) {
        if contactoExiste(telefono: telefono, id: id) {
            presentarAlerta(mensaje: "Este contacto ya fue agregado.")
            return
        }

        let nuevoContacto = ContactoEntity(context: CoreDataManager.shared.context)
        nuevoContacto.nombre = nombre
        nuevoContacto.telefono = telefono
        nuevoContacto.id = id
        CoreDataManager.shared.saveContext()
        cargarContactosLocales()
    }

    private func setupMap() {
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true

        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        overlayView.isUserInteractionEnabled = false
        mapView.addSubview(overlayView)
    }

    private func setupCollectionView() {
        panelContactos.delegate = self
        panelContactos.dataSource = self
        if let layout = panelContactos.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumInteritemSpacing = 10
            layout.minimumLineSpacing = 10
            layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        }
    }

    @IBAction func panelTapped(_ sender: UITapGestureRecognizer) {
        togglePanel()
    }

    private func togglePanel() {
        guard bottomSheetBottomConstraint != nil else { return }
        bottomSheetBottomConstraint.constant = isOpen ? -200 : 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        isOpen.toggle()
    }

    @IBAction func funcionBtnConfiguracion(){
        guard usuarioSesion != nil else { return }
        performSegue(withIdentifier: "configuracionSegue", sender: nil)
    }
    
    @IBAction func funcionBtnPerfil(_ sender: UIButton){
        guard let usuario = usuarioSesion else { return }
        performSegue(withIdentifier: "perfilSegue", sender: usuario)
    }

    private func presentarAlerta(mensaje: String) {
        DispatchQueue.main.async {
            let alerta = UIAlertController(title: "Atención", message: mensaje, preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default))
            self.present(alerta, animated: true)
        }
    }

    @IBAction func funcionBtnModoDiscreto(_ sender: UIButton){
        let estadoActual = UserDefaults.standard.bool(forKey: "modoDiscreto")
        let nuevoEstado = !estadoActual
        UserDefaults.standard.set(nuevoEstado, forKey: "modoDiscreto")
        actualizarEstiloModoDiscreto()
        let mensaje = nuevoEstado ? "Modo Discreto ACTIVADO. La alarma será silenciosa." : "Modo Discreto DESACTIVADO. La alarma emitirá sonido."
        presentarAlerta(mensaje: mensaje)
    }
    
    private func actualizarEstiloModoDiscreto() {
        let activo = UserDefaults.standard.bool(forKey: "modoDiscreto")
        btnModoDiscreto.alpha = activo ? 1.0 : 0.5
    }

    @IBAction func funcionBtnDesactivar(_ sender: UIButton) {
        isServiceActive = !isServiceActive
        let modoDiscreto = UserDefaults.standard.bool(forKey: "modoDiscreto")
        
        if isServiceActive {
            if !modoDiscreto { iniciarAlarmaSistema() }
            activarEmergenciaAPI()
            iniciarGrabacionAudio()
            actualizarUIBotonPrincipal()
        } else {
            detenerAlarmaSistema()
            locationUpdateTimer?.invalidate()
            detenerGrabacionAudio()
            if let eventId = currentEventId {
                cerrarEmergenciaAPI(eventId: eventId)
                guardarHistorialLocal(id: Int64(eventId), tipo: "Pánico", audioPath: nombreArchivoAudioActual)
            }
            lastSentAt = nil
            lastSentCoord = nil
            nombreArchivoAudioActual = nil
            actualizarUIBotonPrincipal()
        }
    }
    
    func iniciarGrabacionAudio() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let fechaString = dateFormatter.string(from: Date())
            nombreArchivoAudioActual = "audio_\(fechaString).m4a"
            
            let path = getDocumentsDirectory().appendingPathComponent(nombreArchivoAudioActual!)
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: path, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            print("🎙️ Grabando audio en: \(path)")
        } catch {
            print("❌ Error al iniciar grabación: \(error)")
        }
    }
    
    func detenerGrabacionAudio() {
        audioRecorder?.stop()
        audioRecorder = nil
        print("🛑 Grabación detenida")
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func activarEmergenciaAPI() {
        guard let token = UserDefaults.standard.string(forKey: "userToken"),
              let userId = UserDefaults.standard.integer(forKey: "userId") as? Int,
              let location = locationManager.location else { return }

        let request = CreateEmergencyEventRequest(
            userId: userId,
            type: "TAP",
            description: "Emergencia activada por usuario",
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        EmergencyEventService.shared.crearEvento(datos: request, token: token) { [weak self] result in
            switch result {
            case .success(let response):
                self?.currentEventId = response.id
                DispatchQueue.main.async {
                    self?.locationManager.allowsBackgroundLocationUpdates = true
                    if #available(iOS 11.0, *) { self?.locationManager.showsBackgroundLocationIndicator = true }
                    self?.locationManager.desiredAccuracy = kCLLocationAccuracyBest
                }
                self?.iniciarRastreoUbicacion()
                self?.enviarUbicacionActual()
            case .failure(let error):
                print("Error creando evento: \(error)")
            }
        }
    }
    
    func iniciarRastreoUbicacion() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        guard ConfiguracionViewController.isLocationEnabled() else { return }
        let status = locationManager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }

        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.enviarUbicacionActual()
        }
    }
    
    func enviarUbicacionActual() {
        guard isServiceActive else { return }
        guard let location = locationManager.location else { return }
        enviarUbicacionActual(location)
    }

    private func enviarUbicacionActual(_ location: CLLocation) {
        guard let eventId = currentEventId,
              let token = UserDefaults.standard.string(forKey: "userToken") else { return }

        let now = Date()
        if let last = lastSentAt, now.timeIntervalSince(last) < minSendInterval { return }
        
        if let lastCoord = lastSentCoord {
            let lastLocation = CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude)
            let distance = lastLocation.distance(from: location)
            if distance < minDistanceMeters { return }
        }

        let request = CreateEmergencyLocationRequest(
            emergencyEventId: eventId,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        if bgTaskId == .invalid {
            bgTaskId = UIApplication.shared.beginBackgroundTask(withName: "SendEmergencyLocation") { [weak self] in
                if let id = self?.bgTaskId { UIApplication.shared.endBackgroundTask(id) }
                self?.bgTaskId = .invalid
            }
        }

        EmergencyLocationService.shared.crearUbicacionEmergencia(datos: request, token: token) { [weak self] result in
            defer {
                if let id = self?.bgTaskId, id != .invalid {
                    UIApplication.shared.endBackgroundTask(id)
                    self?.bgTaskId = .invalid
                }
            }
            switch result {
            case .success:
                self?.lastSentAt = now
                self?.lastSentCoord = location.coordinate
                self?.enviarMensajesWhatsApp(location: location)
            case .failure(let error):
                print("Error enviando trace: \(error)")
            }
        }
    }

    func cerrarEmergenciaAPI(eventId: Int) {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else { return }
        EmergencyEventService.shared.resolverEvento(id: eventId, token: token) { result in
            switch result {
            case .success: break
            case .failure(let error): print("Error cerrando evento: \(error)")
            }
        }
    }

    func guardarHistorialLocal(id: Int64, tipo: String, audioPath: String?) {
        let historial = HistorialEntity(context: CoreDataManager.shared.context)
        historial.eventId = id
        historial.fecha = Date()
        historial.tipo = tipo
        historial.audioPath = audioPath
        CoreDataManager.shared.saveContext()
        print("💾 Historial guardado con audio: \(audioPath ?? "Ninguno")")
    }

    func enviarMensajesWhatsApp(location: CLLocation) {
        guard let token = UserDefaults.standard.string(forKey: "userToken"),
              let userId = UserDefaults.standard.object(forKey: "userId") as? Int else {
            print("⚠️ Faltan datos de sesión para enviar alerta")
            return
        }
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let linkGoogleMaps = "https://www.google.com/maps/search/?api=1&query=\(lat),\(lon)"
        let encodedLocation = linkGoogleMaps.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? linkGoogleMaps
        let urlString = "\(Conexion.baseURL)/api/contacts/emergency/alert?location=\(encodedLocation)&userId=\(userId)"
        
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("📤 Enviando alerta a: \(urlString)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error de red enviando alerta: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Estado HTTP Backend: \(httpResponse.statusCode)")
                if !(200...299).contains(httpResponse.statusCode) {
                    if let data = data, let body = String(data: data, encoding: .utf8) {
                        print("⚠️ Error del Backend: \(body)")
                    }
                } else {
                    print("✅ Alerta enviada exitosamente al Backend.")
                }
            }
        }.resume()
    }
    
    private func actualizarUIBotonPrincipal() {
        DispatchQueue.main.async {
            if self.isServiceActive {
                self.btnDesactivar.setTitle("DESACTIVAR", for: .normal)
                self.btnDesactivar.backgroundColor = .systemRed
            } else {
                self.btnDesactivar.setTitle("ACTIVAR", for: .normal)
                self.btnDesactivar.backgroundColor = UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1.0)
            }
        }
    }
    
    func iniciarAlarmaSistema() {
        reproducirSonidoYVibracion()
        soundTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.reproducirSonidoYVibracion()
        }
    }
    
    func detenerAlarmaSistema() {
        soundTimer?.invalidate()
        soundTimer = nil
    }
    
    func contactoExiste(telefono: String, id: String) -> Bool {
        let fetch: NSFetchRequest<ContactoEntity> = ContactoEntity.fetchRequest()
        let telPred = NSPredicate(format: "telefono == %@", telefono)
        let idPred = NSPredicate(format: "id == %@", id)
        fetch.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [telPred, idPred])
        do {
            let count = try CoreDataManager.shared.context.count(for: fetch)
            return count > 0
        } catch {
            return false
        }
    }

    func eliminarContactoLocal(_ contacto: ContactoEntity) {
        CoreDataManager.shared.context.delete(contacto)
        CoreDataManager.shared.saveContext()
        cargarContactosLocales()
    }

    func eliminarContactoRemoto(telefono: String, completion: @escaping (Bool) -> Void) {
        guard let userId = UserDefaults.standard.object(forKey: "userId") as? Int,
              let token = UserDefaults.standard.string(forKey: "userToken") else {
            completion(false)
            return
        }

        ContactService.shared.obtenerContactosPorUsuario(userId: userId, token: token) { result in
            switch result {
            case .success(let contactosBD):
                let objetivo = contactosBD.first { self.normalizarNumero($0.phoneNumber ?? "") == self.normalizarNumero(telefono) }
                guard let id = objetivo?.id else { completion(false); return }
                ContactService.shared.eliminarContacto(id: id, token: token) { delResult in
                    switch delResult {
                    case .success: completion(true)
                    case .failure: completion(false)
                    }
                }
            case .failure:
                completion(false)
            }
        }
    }

    private func normalizarNumero(_ numero: String) -> String {
        let chars = numero.filter { ("+".contains($0)) || ($0.isNumber) }
        return chars
    }

    func reproducirSonidoYVibracion() {
        AudioServicesPlaySystemSound(1005)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    func formatearFecha(_ iso: String, formato: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let isoFormatterSimple = ISO8601DateFormatter()
        isoFormatterSimple.formatOptions = [.withInternetDateTime]
        isoFormatterSimple.timeZone = TimeZone(secondsFromGMT: 0)
        
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        simpleFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        var fecha: Date? = isoFormatter.date(from: iso)
        if fecha == nil { fecha = isoFormatterSimple.date(from: iso) }
        if fecha == nil { fecha = simpleFormatter.date(from: String(iso.prefix(19))) }
        
        guard let date = fecha else { return iso }

        let df = DateFormatter()
        df.locale = Locale(identifier: "es_PE")
        df.dateFormat = formato
        
        return df.string(from: date).capitalized
    }

    @IBAction func funcionBtnAgregarContacto(_ sender: UIButton) {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let contactsVC = storyboard.instantiateViewController(withIdentifier: "ContactsViewController") as? ContactsViewController {
                        contactsVC.usuarioSesion = self.usuarioSesion
                        contactsVC.contactoSeleccionado = { [weak self] contact in
                            DispatchQueue.main.async {
                                guard let self = self else { return }
                                
                                let nombreCompleto = "\(contact.givenName) \(contact.familyName)"
                                let telefonoOriginal = contact.phoneNumbers.first?.value.stringValue ?? ""
                                let id = contact.identifier
                                let email = (contact.emailAddresses.first?.value as String?)?.trimmingCharacters(in: .whitespacesAndNewlines)
                                let emailValido = (email?.isEmpty == false) ? email! : "unknown@novamovil.local"

                                if self.contactoExiste(telefono: telefonoOriginal, id: id) {
                                    self.presentarAlerta(mensaje: "Este contacto ya está en tu red de seguridad.")
                                    return
                                }

                                self.guardarContactoEnCoreData(nombre: nombreCompleto, telefono: telefonoOriginal, id: id)

                                if let userId = UserDefaults.standard.object(forKey: "userId") as? Int,
                                   let token = UserDefaults.standard.string(forKey: "userToken") {
                                    let req = CreateContactRequest(
                                        userId: userId,
                                        fullName: nombreCompleto,
                                        phoneNumber: telefonoOriginal.isEmpty ? nil : telefonoOriginal,
                                        email: emailValido,
                                        enableWhatsapp: true
                                    )
                                    ContactService.shared.crearContacto(datos: req, token: token) { result in
                                        switch result {
                                        case .success: print("✅ Contacto sincronizado en BD")
                                        case .failure(let error): print("❌ Error sincronizando contacto: \(error)")
                                        }
                                    }
                                }
                            }
                        }
                        contactsVC.modalPresentationStyle = .pageSheet
                        self.present(contactsVC, animated: true)
                    }
                } else {
                    self.presentarAlerta(mensaje: "La app necesita acceso a contactos para agregar tu red de seguridad.")
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "perfilSegue",
           let nav = segue.destination as? UINavigationController,
           let destino = nav.topViewController as? ProfileViewController,
           let usuario = sender as? UserDetail {
            destino.usuario = usuario
        }
    }
}

extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        if isServiceActive && ConfiguracionViewController.isLocationEnabled() {
            enviarUbicacionActual(location)
        }
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contactosGuardados.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "celdaContacto", for: indexPath) as! ContactCellCollectionViewCell
        let contacto = contactosGuardados[indexPath.item]
        
        let nombreCompleto = (contacto.nombre ?? "").trimmingCharacters(in: .whitespaces)
        let palabras = nombreCompleto.components(separatedBy: " ").filter { !$0.isEmpty }
        var iniciales = ""
        
        if palabras.count >= 2 {
            iniciales = String(palabras[0].prefix(1)) + String(palabras[1].prefix(1))
        } else if !palabras.isEmpty {
            iniciales = String(palabras[0].prefix(2))
        }
        
        let primerNombre = palabras.first ?? (contacto.nombre ?? "")
        
        cell.lblNombre.text = primerNombre
        cell.lblNombre.font = UIFont.systemFont(ofSize: 11)
        cell.lblNombre.textAlignment = .center
        cell.lblNombre.numberOfLines = 1
        cell.lblNombre.adjustsFontSizeToFitWidth = true
        cell.lblNombre.minimumScaleFactor = 0.8
        cell.lblNombre.textColor = .label
        
        cell.lblLetrsNombre.text = iniciales.uppercased()
        cell.lblLetrsNombre.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        cell.lblLetrsNombre.textColor = .white
        cell.lblLetrsNombre.textAlignment = .center
        cell.lblLetrsNombre.backgroundColor = UIColor(red: 0.06, green: 0.42, blue: 0.31, alpha: 1.0)
        
        cell.layoutIfNeeded()
        cell.lblLetrsNombre.layer.cornerRadius = cell.lblLetrsNombre.frame.width / 2
        cell.lblLetrsNombre.clipsToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 70, height: 90)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let contacto = contactosGuardados[indexPath.item]
        let alerta = UIAlertController(title: "Quitar contacto", message: "¿Deseas quitar a \(contacto.nombre ?? "este contacto") de tu red de seguridad?", preferredStyle: .actionSheet)
        let eliminar = UIAlertAction(title: "Eliminar", style: .destructive) { _ in
            let telefono = contacto.telefono ?? ""
            self.eliminarContactoRemoto(telefono: telefono) { ok in
                DispatchQueue.main.async {
                    if ok { self.eliminarContactoLocal(contacto) }
                    else { self.presentarAlerta(mensaje: "No se pudo eliminar en el servidor. Inténtalo nuevamente.") }
                }
            }
        }
        let cancelar = UIAlertAction(title: "Cancelar", style: .cancel)
        alerta.addAction(eliminar)
        alerta.addAction(cancelar)
        present(alerta, animated: true)
    }
}

