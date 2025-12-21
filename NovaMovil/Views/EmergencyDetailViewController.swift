//
//  EmergencyDetailViewController.swift
//  NovaMovil
//
//  Created by user288878 on 12/15/25.
//

import UIKit
import MapKit

class EmergencyDetailViewController: UIViewController {
    
    var evento: EmergencyEventSummary?
    
    
    @IBOutlet weak var dayLabel: UILabel!
    
    
    @IBOutlet weak var scheduleLabel: UILabel!
    
    @IBOutlet weak var mapMapView: MKMapView!
    
    
    	
    override func viewDidLoad() {
        super.viewDidLoad()
        configurarVista()
    }
    

    @IBAction func pdfButtonTapped(_ sender: Any) {
        let renderer = UIGraphicsPDFRenderer(bounds: view.bounds)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            view.layer.render(in: ctx.cgContext)
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("DetalleEmergencia.pdf")
        do {
            try data.write(to: tempURL)
            let av = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            present(av, animated: true)
        } catch { }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

private extension EmergencyDetailViewController {
    func configurarVista() {
        guard let evt = evento else { return }

        let fechaTexto = formatearFecha(evt.activatedAt ?? "", formato: "EEEE, d 'de' MMMM")
        dayLabel.text = fechaTexto

        let horaTexto = formatearFecha(evt.activatedAt ?? "", formato: "HH:mm")
        scheduleLabel.text = horaTexto

        // Carga opcional de ubicación más reciente para el evento
        cargarUltimaUbicacion(eventId: evt.id)
    }

    func formatearFecha(_ iso: String, formato: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var fecha = isoFormatter.date(from: iso)
        if fecha == nil {
            let alt = DateFormatter()
            alt.locale = Locale(identifier: "en_US_POSIX")
            alt.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            fecha = alt.date(from: iso)
        }

        guard let date = fecha else { return iso }
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_PE")
        df.dateFormat = formato
        return df.string(from: date).capitalized
    }
}

// MARK: - Ubicación del evento
private extension EmergencyDetailViewController {
    var token: String? { UserDefaults.standard.string(forKey: "userToken") }

    func cargarUltimaUbicacion(eventId: Int) {
        guard let tk = token else { return }
        EmergencyLocationService.shared.obtenerUbicacionesPorEvento(eventId: eventId, token: tk) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let locations):
                    var datos = locations

                    if datos.isEmpty {
                        // PRUEBA: datos vacíos -> usamos ubicaciones de ejemplo para validar recorrido
                        let formatter = ISO8601DateFormatter()
                        let now = formatter.string(from: Date())
                        datos = [
                            EmergencyLocationResponse(id: 1, emergencyEventId: eventId, latitude: -12.04637, longitude: -77.04279, capturedAt: now),
                            EmergencyLocationResponse(id: 2, emergencyEventId: eventId, latitude: -12.04845, longitude: -77.03199, capturedAt: now)
                        ]
                        // FIN PRUEBA
                    }

                    var lastCoord: CLLocationCoordinate2D?
                    for loc in datos {
                        let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                        lastCoord = coord
                        let pin = MKPointAnnotation()
                        pin.coordinate = coord
                        pin.title = "Ubicación capturada"
                        pin.subtitle = self?.formatearFecha(loc.capturedAt, formato: "dd/MM/yyyy HH:mm")
                        self?.mapMapView.addAnnotation(pin)
                    }

                    if let coord = lastCoord {
                        let region = MKCoordinateRegion(center: coord, latitudinalMeters: 500, longitudinalMeters: 500)
                        self?.mapMapView.setRegion(region, animated: false)
                    }
                case .failure:
                    break
                }
            }
        }
    }
}
