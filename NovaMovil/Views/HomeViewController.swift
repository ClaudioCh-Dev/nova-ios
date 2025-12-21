import UIKit
import CoreData
import MapKit
import CoreLocation
import AudioToolbox

class HomeViewController: UIViewController, MKMapViewDelegate {

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupCollectionView()
        actualizarEstiloModoDiscreto()
        actualizarUIBotonPrincipal()
        cargarContactosLocales()
        NotificationCenter.default.addObserver(self, selector: #selector(handleEmergencyShortcut), name: NSNotification.Name("TriggerNovaEmergency"), object: nil)
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
            self.panelContactos.reloadData()
        } catch {
            print("Error cargando contactos: \(error)")
        }
    }

    func guardarContactoEnCoreData(nombre: String, telefono: String, id: String) {
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
        locationManager.requestWhenInUseAuthorization()
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
        let alerta = UIAlertController(
            title: "Atención",
            message: mensaje,
            preferredStyle: .alert
        )
        alerta.addAction(UIAlertAction(title: "Aceptar", style: .default))
        present(alerta, animated: true)
    }

    @IBAction func funcionBtnModoDiscreto(_ sender: UIButton){
        let estadoActual = UserDefaults.standard.bool(forKey: "modoDiscreto")
        let nuevoEstado = !estadoActual
        UserDefaults.standard.set(nuevoEstado, forKey: "modoDiscreto")
        
        actualizarEstiloModoDiscreto()
        
        let mensaje = nuevoEstado
            ? "Modo Discreto ACTIVADO. La alarma será silenciosa."
            : "Modo Discreto DESACTIVADO. La alarma emitirá sonido."
        
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
            print("🚨 INICIANDO PROTOCOLO DE EMERGENCIA")
            
            if !modoDiscreto { iniciarAlarmaSistema() }
            
            activarEmergenciaAPI()
            enviarMensajesWhatsApp()
            
            actualizarUIBotonPrincipal()
            
        } else {
            print("✅ FINALIZANDO EMERGENCIA")
            
            detenerAlarmaSistema()
            locationUpdateTimer?.invalidate()
            
            if let eventId = currentEventId {
                cerrarEmergenciaAPI(eventId: eventId)
            }
            
            actualizarUIBotonPrincipal()
        }
    }
    
    func activarEmergenciaAPI() {
        guard let token = UserDefaults.standard.string(forKey: "userToken"),
              let userId = UserDefaults.standard.integer(forKey: "userId") as? Int,
              let location = locationManager.location else {
            print("❌ Datos faltantes para API")
            return
        }

        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
        
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
                print("✅ Evento creado ID: \(response.id)")
                
                self?.guardarHistorialLocal(id: Int64(response.id), tipo: "Pánico")
                DispatchQueue.main.async {
                    self?.locationManager.allowsBackgroundLocationUpdates = true
                    if #available(iOS 11.0, *) { self?.locationManager.showsBackgroundLocationIndicator = true }
                    self?.locationManager.desiredAccuracy = kCLLocationAccuracyBest
                }
                self?.iniciarRastreoUbicacion()
                
            case .failure(let error):
                print("❌ Error creando evento: \(error)")
            }
        }
    }
    
    func iniciarRastreoUbicacion() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil

        guard ConfiguracionViewController.isLocationEnabled() else {
            print("⚠️ Rastreo no iniciado: ubicación desactivada en ajustes de la app")
            return
        }
        let status = locationManager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else {
            print("⚠️ Rastreo no iniciado: permisos de ubicación no concedidos")
            return
        }

        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.enviarUbicacionActual()
        }
    }
    
    func enviarUbicacionActual() {
        guard isServiceActive else { return }
        guard let eventId = currentEventId,
              let location = locationManager.location,
              let token = UserDefaults.standard.string(forKey: "userToken") else { return }
        enviarUbicacionActual(location)
    }

    private func enviarUbicacionActual(_ location: CLLocation) {
        guard let eventId = currentEventId,
              let token = UserDefaults.standard.string(forKey: "userToken") else { return }

        let now = Date()
        if let last = lastSentAt, now.timeIntervalSince(last) < minSendInterval {
            return
        }
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
                print("📍 Trace enviado")
            case .failure(let error):
                print("⚠️ Error enviando trace: \(error)")
            }
        }
    }

    func cerrarEmergenciaAPI(eventId: Int) {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else { return }
        
        EmergencyEventService.shared.resolverEvento(id: eventId, token: token) { result in
            switch result {
            case .success: print("✅ Evento cerrado en servidor")
            case .failure(let error): print("❌ Error cerrando evento: \(error)")
            }
        }
    }

    func guardarHistorialLocal(id: Int64, tipo: String) {
        let historial = HistorialEntity(context: CoreDataManager.shared.context)
        historial.eventId = id
        historial.fecha = Date()
        historial.tipo = tipo
        CoreDataManager.shared.saveContext()
    }

    func enviarMensajesWhatsApp() {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else { return }
        let numeros = contactosGuardados.compactMap { $0.telefono }
        
        guard !numeros.isEmpty else { return }
        
        let url = URL(string: "\(Conexion.baseURL)/api/notifications/broadcast")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let lat = locationManager.location?.coordinate.latitude ?? 0.0
        let lon = locationManager.location?.coordinate.longitude ?? 0.0
        let link = "https://maps.google.com/?q=\(lat),\(lon)"
        
        let body: [String: Any] = [
            "phoneNumbers": numeros,
            "userName": "Usuario Nova",
            "googleMapsLink": link
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if error == nil {
                print("✅ Alerta de WhatsApp enviada al backend")
            } else {
                print("❌ Error enviando alerta: \(error!)")
            }
        }.resume()
    }
    
    private func actualizarUIBotonPrincipal() {
        if isServiceActive {
            btnDesactivar.setTitle("DESACTIVAR", for: .normal)
            btnDesactivar.backgroundColor = .systemRed
        } else {
            btnDesactivar.setTitle("ACTIVAR", for: .normal)
            btnDesactivar.backgroundColor = UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1.0)
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
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let contactsVC = storyboard.instantiateViewController(withIdentifier: "ContactsViewController") as? ContactsViewController {
            contactsVC.usuarioSesion = self.usuarioSesion
            
            contactsVC.contactoSeleccionado = { [weak self] contact in
                let nombreCompleto = "\(contact.givenName) \(contact.familyName)"
                let telefono = contact.phoneNumbers.first?.value.stringValue ?? ""
                let id = contact.identifier
                
                self?.guardarContactoEnCoreData(nombre: nombreCompleto, telefono: telefono, id: id)
            }
            contactsVC.modalPresentationStyle = .pageSheet
            present(contactsVC, animated: true)
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
        
        // Extraer iniciales del nombre completo
        let nombreCompleto = (contacto.nombre ?? "").trimmingCharacters(in: .whitespaces)
        let palabras = nombreCompleto.components(separatedBy: " ").filter { !$0.isEmpty }
        var iniciales = ""
        
        if palabras.count >= 2 {
            // Si hay nombre y apellido, tomar primera letra de cada uno
            iniciales = String(palabras[0].prefix(1)) + String(palabras[1].prefix(1))
        } else if !palabras.isEmpty {
            // Si solo hay una palabra, tomar las dos primeras letras
            iniciales = String(palabras[0].prefix(2))
        }
        
        // Mostrar solo el primer nombre
        let primerNombre = palabras.first ?? (contacto.nombre ?? "")
        
        // Configurar el label de nombre (debajo del círculo)
        cell.lblNombre.text = primerNombre
        cell.lblNombre.font = UIFont.systemFont(ofSize: 11)
        cell.lblNombre.textAlignment = .center
        cell.lblNombre.numberOfLines = 1
        cell.lblNombre.adjustsFontSizeToFitWidth = true
        cell.lblNombre.minimumScaleFactor = 0.8
        cell.lblNombre.textColor = .label
        
        // Configurar el círculo con las iniciales
        cell.lblLetrsNombre.text = iniciales.uppercased()
        cell.lblLetrsNombre.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        cell.lblLetrsNombre.textColor = .white
        cell.lblLetrsNombre.textAlignment = .center
        cell.lblLetrsNombre.backgroundColor = UIColor(red: 0.06, green: 0.42, blue: 0.31, alpha: 1.0) // Verde oscuro
        
        // Hacer el círculo después de que la celda tenga su tamaño final
        DispatchQueue.main.async {
            cell.lblLetrsNombre.layer.cornerRadius = cell.lblLetrsNombre.frame.width / 2
            cell.lblLetrsNombre.clipsToBounds = true
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 70, height: 90)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}
