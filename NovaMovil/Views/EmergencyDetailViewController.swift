//
//  EmergencyDetailViewController.swift
//  NovaMovil
//
//  Created by user288878 on 12/15/25.
//

import UIKit
import MapKit

class EmergencyDetailViewController: UIViewController {
    
    var evento: EmergencyEventResponse?
    
    
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

        let fechaTexto = formatearFecha(evt.createdAt, formato: "EEEE, d 'de' MMMM")
        dayLabel.text = fechaTexto

        let horaTexto = formatearFecha(evt.createdAt, formato: "HH:mm")
        scheduleLabel.text = horaTexto

        let coord = CLLocationCoordinate2D(latitude: evt.latitude, longitude: evt.longitude)
        let region = MKCoordinateRegion(center: coord, latitudinalMeters: 500, longitudinalMeters: 500)
        mapMapView.setRegion(region, animated: false)

        let pin = MKPointAnnotation()
        pin.coordinate = coord
        pin.title = evt.type
        pin.subtitle = evt.description
        mapMapView.addAnnotation(pin)
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
