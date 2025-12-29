//
//  EmergencyDetailViewController.swift
//  NovaMovil
//

import UIKit
import MapKit
import CoreData
import AVFoundation

class EmergencyDetailViewController: UIViewController {
    
    // MARK: - Variables y Outlets
    var evento: EmergencyEventSummary?
    var audioPlayer: AVAudioPlayer?
    var rutaAudioEncontrada: URL?
    
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var scheduleLabel: UILabel!
    @IBOutlet weak var mapMapView: MKMapView!
    @IBOutlet weak var btnReproducirAudio: UIButton!
    
    // MARK: - Ciclo de Vida
    override func viewDidLoad() {
        super.viewDidLoad()
        mapMapView.delegate = self
        
        configurarVista()
        buscarAudioLocal()
    }
    
    // MARK: - Lógica de Audio
    func buscarAudioLocal() {
        guard let eventId = evento?.id else {
            ocultarBotonAudio()
            return
        }
        
        let fetch: NSFetchRequest<HistorialEntity> = HistorialEntity.fetchRequest()
        fetch.predicate = NSPredicate(format: "eventId == %d", Int64(eventId))
        fetch.fetchLimit = 1
        
        do {
            let resultados = try CoreDataManager.shared.context.fetch(fetch)
            
            if let historial = resultados.first,
               let audioName = historial.audioPath,
               !audioName.isEmpty {
                
                let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(audioName)
                
                if FileManager.default.fileExists(atPath: path.path) {
                    self.rutaAudioEncontrada = path
                    print("Audio encontrado en: \(path.lastPathComponent)")
                    mostrarBotonAudio()
                } else {
                    print("El registro en BD existe, pero el archivo de audio no.")
                    ocultarBotonAudio()
                }
            } else {
                ocultarBotonAudio()
            }
        } catch {
            print("Error buscando audio: \(error)")
            ocultarBotonAudio()
        }
    }
    
    func mostrarBotonAudio() {
        guard let btn = btnReproducirAudio else { return }
        btn.isHidden = false
        btn.setTitle("Escuchar Evidencia", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 8
        btn.setTitleColor(.white, for: .normal)
    }
    
    func ocultarBotonAudio() {
        if let btn = btnReproducirAudio {
            btn.isHidden = true
        }
    }
    
    @IBAction func accionReproducirAudio(_ sender: UIButton) {
        guard let url = rutaAudioEncontrada else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            
            sender.setTitle("Reproduciendo...", for: .normal)
            sender.backgroundColor = .systemGreen
            
            let duracion = audioPlayer?.duration ?? 0
            Timer.scheduledTimer(withTimeInterval: duracion, repeats: false) { _ in
                sender.setTitle("Escuchar Evidencia", for: .normal)
                sender.backgroundColor = .systemBlue
            }
            
        } catch {
            print("Error reproduciendo: \(error)")
            let alert = UIAlertController(title: "Error", message: "No se pudo reproducir el audio.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            present(alert, animated: true)
        }
    }
}

// MARK: - Configuración de Vista y Fechas
private extension EmergencyDetailViewController {
    
    func configurarVista() {
        guard let evt = evento else { return }

        // Fecha
        let fechaTexto = formatearFecha(evt.activatedAt ?? "", formato: "dd/MM/yyyy")
        dayLabel.text = "Fecha: " + (fechaTexto.isEmpty ? "—" : fechaTexto)

        // Hora
        let horaTexto = formatearFecha(evt.activatedAt ?? "", formato: "HH:mm a")
        scheduleLabel.text = "Hora: " + (horaTexto.isEmpty ? "—" : horaTexto)

        cargarUltimaUbicacion(eventId: evt.id)
    }

    func formatearFecha(_ iso: String, formato: String) -> String {
        guard !iso.isEmpty else { return "—" }

        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        inputFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        var date = inputFormatter.date(from: iso)

        if date == nil {
            let inputSimple = ISO8601DateFormatter()
            inputSimple.formatOptions = [.withInternetDateTime]
            inputSimple.timeZone = TimeZone(secondsFromGMT: 0)
            date = inputSimple.date(from: iso)
        }
        
        if date == nil {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            df.timeZone = TimeZone(secondsFromGMT: 0)
            date = df.date(from: String(iso.prefix(19)))
        }
        
        guard let fechaValida = date else { return iso }

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "es_PE")
        outputFormatter.timeZone = TimeZone.current
        outputFormatter.dateFormat = formato
        
        return outputFormatter.string(from: fechaValida).capitalized
    }
}

// MARK: - Mapa y API de Ubicaciones
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
                        let formatter = ISO8601DateFormatter()
                        let now = formatter.string(from: Date())
                        datos = [
                            EmergencyLocationResponse(id: 1, emergencyEventId: eventId, latitude: -12.04637, longitude: -77.04279, capturedAt: now),
                            EmergencyLocationResponse(id: 2, emergencyEventId: eventId, latitude: -12.04845, longitude: -77.03199, capturedAt: now)
                        ]
                    }

                    var lastCoord: CLLocationCoordinate2D?
                    var coords: [CLLocationCoordinate2D] = []
                    
                    for loc in datos {
                        let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                        lastCoord = coord
                        coords.append(coord)
                        
                        let pin = MKPointAnnotation()
                        pin.coordinate = coord
                        pin.title = "Ubicación"
                        pin.subtitle = self?.formatearFecha(loc.capturedAt, formato: "HH:mm")
                        self?.mapMapView.addAnnotation(pin)
                    }

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

// MARK: - MKMapViewDelegate
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
