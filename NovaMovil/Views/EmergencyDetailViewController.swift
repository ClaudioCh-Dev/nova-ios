import UIKit
import MapKit

class EmergencyDetailViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: - Variables
    var evento: EmergencyEventResponse?
    private var rutaCoordenadas: [CLLocationCoordinate2D] = []
    
    // MARK: - Outlets
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var scheduleLabel: UILabel!
    @IBOutlet weak var mapMapView: MKMapView!
    
    // MARK: - Ciclo de Vida
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Configurar Delegado del Mapa (Vital para dibujar líneas)
        mapMapView.delegate = self
        
        // 2. Mostrar textos (Fecha/Hora) que SÍ vienen en el evento
        configurarTextos()
        
        // 3. Ir a buscar las coordenadas al otro endpoint
        cargarRutaDesdeAPI()
        if let e = evento {
                print("🔍 DETALLE RECIBIÓ EVENTO: ID \(e.id), Fecha: \(e.createdAt)")
            } else {
                print("⚠️ DETALLE RECIBIÓ NIL")
            }
    }
    
    // MARK: - Lógica Visual
    func configurarTextos() {
        guard let evt = evento else { return }
        
        // Fecha
        let fechaString = evt.createdAt ?? ISO8601DateFormatter().string(from: Date())
        dayLabel.text = formatearFecha(fechaString, formato: "EEEE, d 'de' MMMM yyyy")
        
        // Horario
        let horaInicio = formatearFecha(fechaString, formato: "HH:mm")
        var horaFin = "En curso"
        if let fin = evt.resolvedAt {
            horaFin = formatearFecha(fin, formato: "HH:mm")
        }
        scheduleLabel.text = "Inicio: \(horaInicio) - Fin: \(horaFin)"
    }
    
    // MARK: - Lógica de Red (API)
    func cargarRutaDesdeAPI() {
        guard let evt = evento,
              let token = UserDefaults.standard.string(forKey: "userToken") else { return }
        
        print("🌍 Buscando coordenadas para evento ID: \(evt.id)")
        
        // Llamamos al endpoint corregido
        EmergencyLocationService.shared.obtenerUbicacionesPorEvento(eventId: evt.id, token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let listaPuntos):
                    print("✅ Se recibieron \(listaPuntos.count) puntos de ubicación.")
                    self?.dibujarMapa(puntos: listaPuntos)
                    
                case .failure(let error):
                    print("❌ Error cargando ruta: \(error)")
                    // Si falla, podrías intentar mostrar coordenadas locales si las tuvieras en CoreData
                }
            }
        }
    }
    
    // MARK: - Dibujar en Mapa
    func dibujarMapa(puntos: [EmergencyLocationResponse]) {
        guard !puntos.isEmpty else {
            print("⚠️ El evento existe, pero no tiene puntos GPS registrados.")
            return
        }
        
        // 1. Mapear respuesta API a Coordenadas de Mapa
        let coordenadas = puntos.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        
        // 2. Crear la línea (Polyline)
        let polyline = MKPolyline(coordinates: coordenadas, count: coordenadas.count)
        mapMapView.addOverlay(polyline)
        
        // 3. Pines de Inicio y Fin
        let inicio = MKPointAnnotation()
        inicio.coordinate = coordenadas.first!
        inicio.title = "Inicio"
        mapMapView.addAnnotation(inicio)
        
        if coordenadas.count > 1 {
            let fin = MKPointAnnotation()
            fin.coordinate = coordenadas.last!
            fin.title = "Fin"
            mapMapView.addAnnotation(fin)
        }
        
        // 4. Zoom automático para que se vea toda la ruta
        let rect = polyline.boundingMapRect
        mapMapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
    }
    
    // MARK: - MKMapViewDelegate (Dibuja la línea)
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1.0) // Tu verde
            renderer.lineWidth = 4
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    // MARK: - Botón PDF
    @IBAction func pdfButtonTapped(_ sender: Any) {
        let renderer = UIGraphicsPDFRenderer(bounds: view.bounds)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            view.layer.render(in: ctx.cgContext)
        }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Reporte_\(evento?.id ?? 0).pdf")
        do {
            try data.write(to: tempURL)
            let av = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            present(av, animated: true)
        } catch { print("Error PDF") }
    }
    
    // MARK: - Helpers
    func formatearFecha(_ iso: String, formato: String) -> String {
        // Intento 1: ISO completo
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Intento 2: ISO simple (Java suele mandar este)
        let simpleIso = ISO8601DateFormatter()
        simpleIso.formatOptions = [.withInternetDateTime]
        
        // Intento 3: Manual
        let manualFormatter = DateFormatter()
        manualFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        var date = isoFormatter.date(from: iso)
        if date == nil { date = simpleIso.date(from: iso) }
        if date == nil { date = manualFormatter.date(from: String(iso.prefix(19))) }
        
        guard let fechaValida = date else { return iso }
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_PE")
        df.dateFormat = formato
        return df.string(from: fechaValida).capitalized
    }
}
