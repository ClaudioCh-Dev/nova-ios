//
//  HomeViewController.swift
//  NovaMovil
//
//  Created by DAMII on 29/11/25.
//

import UIKit
import MapKit
import CoreLocation


class HomeViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    
    let locationManager = CLLocationManager()
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegados
        mapView.delegate = self
        locationManager.delegate = self
        
        // Solicitar permisos
        locationManager.requestWhenInUseAuthorization()
        
        // Iniciar actualización de ubicación
        locationManager.startUpdatingLocation()
        
        // Mostrar la ubicación del usuario en el mapa
        mapView.showsUserLocation = true
    }
}


// MARK: - CLLocationManagerDelegate
extension HomeViewController: CLLocationManagerDelegate {
    
    // Se llama cada vez que la ubicación cambia
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        mapView.setRegion(region, animated: true)
    }
    
    // Se llama cuando cambian los permisos de ubicación
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied || status == .restricted {
            print("Permiso de ubicación denegado")
        }
    }
}
