//
//  EmergencyHistoryViewController.swift
//  NovaMovil
//
//  Created by user288878 on 12/15/25.
//

import UIKit

class EmergencyHistoryViewController: UIViewController {

    @IBOutlet weak var historyTableView: UITableView!
    var eventos: [EmergencyEventResponse] = []
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        historyTableView.delegate = self
        historyTableView.dataSource = self
        historyTableView.register(UITableViewCell.self, forCellReuseIdentifier: "EventCell")
        cargarEventos()
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

extension EmergencyHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
        let evt = eventos[indexPath.row]
        cell.textLabel?.text = "\(evt.type) • \(formatearFecha(evt.createdAt, formato: "dd/MM/yyyy HH:mm"))"
        cell.detailTextLabel?.text = evt.status
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let evt = eventos[indexPath.row]

        if let vc = storyboard?.instantiateViewController(withIdentifier: "EmergencyDetailViewController") as? EmergencyDetailViewController {
            vc.evento = evt
            navigationController?.pushViewController(vc, animated: true)
        } else {
            performSegue(withIdentifier: "detalleEmergenciaSegue", sender: evt)
        }
    }
}

private extension EmergencyHistoryViewController {
    var token: String? { UserDefaults.standard.string(forKey: "userToken") }
    var userId: Int { UserDefaults.standard.integer(forKey: "userId") }

    func cargarEventos() {
        guard let tk = token, userId != 0 else { return }
        EmergencyEventService.shared.obtenerEventosPorUsuario(userId: userId, token: tk) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let lista):
                    self?.eventos = lista
                    self?.historyTableView.reloadData()
                case .failure:
                    break
                }
            }
        }
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
        return df.string(from: date)
    }
}

// Estado
