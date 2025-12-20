import UIKit
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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupCollectionView()
        actualizarEstiloModoDiscreto()
        actualizarUIBotonPrincipal()
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
            if !modoDiscreto {
                iniciarAlarmaSistema()
            }
        } else {
            detenerAlarmaSistema()
        }
        
        actualizarUIBotonPrincipal()
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

    @IBAction func funcionBtnAgregarContacto(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let contactsVC = storyboard.instantiateViewController(withIdentifier: "ContactsViewController") as? ContactsViewController {
            contactsVC.usuarioSesion = self.usuarioSesion
            
            contactsVC.contactoSeleccionado = { [weak self] contact in
                guard let self = self else { return }
                
                if !self.contactos.contains(where: { $0.id == contact.identifier }) {
                    let nuevoContacto = ContactoUI(
                        nombre: "\(contact.givenName) \(contact.familyName)",
                        id: contact.identifier
                    )
                    self.contactos.append(nuevoContacto)
                    self.panelContactos.reloadData()
                }
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
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contactos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "celdaContacto", for: indexPath) as! ContactCellCollectionViewCell
        let contacto = contactos[indexPath.item]
        cell.lblNombre.text = contacto.nombre
        cell.lblLetrsNombre.text = String(contacto.nombre.prefix(1))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 60)
    }
}
