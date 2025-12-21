import UIKit
import MapKit

class EmergencyDetailViewController: UIViewController, MKMapViewDelegate {
    
    var evento: EmergencyEventSummary?
    
    // MARK: - Outlets
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var scheduleLabel: UILabel!
    @IBOutlet weak var mapMapView: MKMapView!
    
    // MARK: - Ciclo de Vida
    override func viewDidLoad() {
        super.viewDidLoad()
        // Mostrar recorridos (polilíneas) y pines en el mapa
        mapMapView.delegate = self
        configurarVista()
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

        let fechaTexto = formatearFecha(evt.activatedAt ?? "", formato: "dd/MM/yyyy")
        dayLabel.text = "Fecha: " + (fechaTexto.isEmpty ? "—" : fechaTexto)

        let horaTexto = formatearFecha(evt.activatedAt ?? "", formato: "HH:mm")
        scheduleLabel.text = "Hora: " + (horaTexto.isEmpty ? "—" : horaTexto)

        // Carga opcional de ubicación más reciente para el evento
        cargarUltimaUbicacion(eventId: evt.id)
    }
    
    // MARK: - Helpers
    func formatearFecha(_ iso: String, formato: String) -> String {
        guard !iso.isEmpty else { return "" }

        // Intento 1: ISO8601 con fracción
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var fecha = isoFormatter.date(from: iso)

        // Intento 2: LocalDateTime sin zona
        if fecha == nil {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            fecha = df.date(from: iso)
        }

        // Intento 3: LocalDateTime con milisegundos sin zona
        if fecha == nil {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            fecha = df.date(from: iso)
        }

        // Intento 4: Con zona Z 
        if fecha == nil {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            fecha = df.date(from: iso)
        }

        // Intento 5: Con milisegundos y zona Z
        if fecha == nil {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            fecha = df.date(from: iso)
        }

        guard let date = fecha else { return iso }
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_PE")
        df.dateFormat = formato
        return df.string(from: date)
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
                    var coords: [CLLocationCoordinate2D] = []
                    for loc in datos {
                        let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                        lastCoord = coord
                        coords.append(coord)
                        let pin = MKPointAnnotation()
                        pin.coordinate = coord
                        pin.title = "Ubicación capturada"
                        pin.subtitle = self?.formatearFecha(loc.capturedAt, formato: "dd/MM/yyyy HH:mm")
                        self?.mapMapView.addAnnotation(pin)
                    }

                    // Dibujar recorrido como polilínea si hay al menos 2 puntos
                    if coords.count >= 2 {
                        let ruta = MKPolyline(coordinates: coords, count: coords.count)
                        self?.mapMapView.addOverlay(ruta)
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

// MARK: - MKMapViewDelegate (Render del recorrido)
extension EmergencyDetailViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 3
            renderer.lineJoin = .round
            renderer.lineCap = .round
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
