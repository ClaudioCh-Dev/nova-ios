import UIKit
import MapKit
import CoreLocation
import Contacts
import ContactsUI

class HomeViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var bottomSheetBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnConfiguracion: UIButton!
    @IBOutlet weak var btnPerfil: UIButton!
    @IBOutlet weak var btnModoDiscreto: UIButton!
    @IBOutlet weak var btnDesactivar: UIButton!
    @IBOutlet weak var panelContactos: UICollectionView!
    
    // MARK: - Propiedades
    let locationManager = CLLocationManager()
    private var isOpen = false
    private var contactos: [CNContact] = [] // Antes estaba solo dentro del closure

    // MARK: - Ciclo de vida
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMap()
        setupCollectionView()
        requestContactsAccess()
    }
    
    // MARK: - Setup
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
    
    private func setupCollectionView() {
        panelContactos.dataSource = self
        panelContactos.delegate = self
    }
    
    // MARK: - Acceso a contactos
    private func requestContactsAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            if granted {
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                
                var fetchedContacts: [CNContact] = []
                do {
                    try store.enumerateContacts(with: request) { contact, stop in
                        fetchedContacts.append(contact)
                    }
                    
                    DispatchQueue.main.async {
                        self.contactos = fetchedContacts
                        self.panelContactos.reloadData()
                    }
                    
                } catch {
                    print("Error al leer contactos:", error)
                }
            } else {
                print("Permiso denegado")
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contactos.count + 1 // +1 para la celda de agregar
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
             let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AgregarCelda", for: indexPath) as! AgregarContactoCell
             return cell
        } else {
           let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "celdaContacto", for: indexPath) as! ContactoCell
           let contacto = contactos[indexPath.item - 1]
           cell.configurarCon(contacto)
           return cell
        }
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            print("Agregar contacto")
            // Aquí podrías abrir la vista de agregar contacto
        }
    }
    
    // MARK: - Bottom Sheet
    @IBAction func panelTapped(_ sender: UITapGestureRecognizer) {
        togglePanel()
    }
    
    private func togglePanel() {
        // Si está cerrado → abrir, si está abierto → cerrar
        bottomSheetBottomConstraint.constant = isOpen ? -200 : 0
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.5,
            options: .curveEaseInOut
        ) {
            self.view.layoutIfNeeded()
        }
        
        isOpen.toggle()
    }
}

// MARK: - CLLocationManagerDelegate
extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let region = MKCoordinateRegion(center: location.coordinate,
                                        latitudinalMeters: 500,
                                        longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
    }
}

