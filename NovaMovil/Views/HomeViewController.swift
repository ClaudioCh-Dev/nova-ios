import UIKit
import MapKit
import CoreLocation

class HomeViewController: UIViewController, MKMapViewDelegate {

    // MARK: - Usuario en sesión
    var usuarioSesion: UserDetail?

    // MARK: - IBOutlets
    @IBOutlet weak var bottomSheetBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnConfiguracion: UIButton!
    @IBOutlet weak var btnPerfil: UIButton!
    @IBOutlet weak var btnModoDiscreto: UIButton!
    @IBOutlet weak var btnDesactivar: UIButton!
    @IBOutlet weak var btnAgregarContacto: UIButton!
    @IBOutlet weak var panelContactos: UICollectionView!

    // MARK: - Propiedades
    let locationManager = CLLocationManager()
    private var isOpen = false

    var contactos: [ContactoUI] = [] // Array solo de contactos reales

    // MARK: - Ciclo de vida
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let usuario = usuarioSesion {
            print("Usuario logueado:", usuario.fullName)
        }

        setupMap()
        setupCollectionView()
    }

    // MARK: - Setup Map
    private func setupMap() {
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true

        // Overlay semitransparente
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        overlayView.isUserInteractionEnabled = false
        mapView.addSubview(overlayView)
    }

    // MARK: - Setup CollectionView
    private func setupCollectionView() {
        panelContactos.delegate = self
        panelContactos.dataSource = self
        // Registrar celda si usas XIB
        // panelContactos.register(UINib(nibName: "ContactoCell", bundle: nil), forCellWithReuseIdentifier: "celdaContacto")
    }

    // MARK: - Bottom Sheet
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

    // MARK: - Botones
    @IBAction func funcionBtnConfiguracion(){
        performSegue(withIdentifier: "configuracionSegue", sender: nil)
    }

    @IBAction func funcionBtnDesactivar(){
        // Lógica para activar/desactivar app
    }

    @IBAction func funcionBtnModoDiscreto(){
        let actual = UserDefaults.standard.bool(forKey: "modoDiscreto")
        let nuevoEstado = !actual
        UserDefaults.standard.set(nuevoEstado, forKey: "modoDiscreto")
        print(nuevoEstado ? "Modo discreto activado" : "Modo discreto desactivado")
    }

    @IBAction func funcionBtnPerfil(_ sender: UIButton){
        guard let usuario = usuarioSesion else { return }
        performSegue(withIdentifier: "perfilSegue", sender: usuario)
    }

    // MARK: - Botón Agregar Contacto
    @IBAction func funcionBtnAgregarContacto(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let contactsVC = storyboard.instantiateViewController(withIdentifier: "ContactsViewController") as? ContactsViewController {
            contactsVC.usuarioSesion = self.usuarioSesion
            
            // Closure para recibir contacto seleccionado
            contactsVC.contactoSeleccionado = { [weak self] contact in
                guard let self = self else { return }
                
                // Evitar duplicados usando identifier
                if !self.contactos.contains(where: { $0.id == contact.identifier }) {
                    let nuevoContacto = ContactoUI(nombre: "\(contact.givenName) \(contact.familyName)", id: contact.identifier)
                    self.contactos.append(nuevoContacto)
                    self.panelContactos.reloadData()
                } else {
                    print("El contacto ya está agregado")
                }
            }
            
            contactsVC.modalPresentationStyle = .pageSheet
            present(contactsVC, animated: true)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              location.coordinate.latitude.isFinite,
              location.coordinate.longitude.isFinite else { return }

        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        mapView.setRegion(region, animated: true)
    }
}

// MARK: - UICollectionViewDelegate & DataSource
extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contactos.count // Solo contactos reales
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "celdaContacto", for: indexPath) as! ContactCellCollectionViewCell
        
        let contacto = contactos[indexPath.item]
        cell.lblNombre.text = contacto.nombre
        cell.lblLetrsNombre.text = String(contacto.nombre.prefix(1))
        
        return cell
    }
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 60, height: 60)
    }
}
