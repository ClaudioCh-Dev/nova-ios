import UIKit
import CoreData

class EmergencyHistoryViewController: UIViewController {

    @IBOutlet weak var historyTableView: UITableView!
    private var eventos: [EmergencyEventResponse] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        historyTableView.delegate = self
        historyTableView.dataSource = self
        cargarEventos()
    }

    // MARK: - Navegación Segura
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "detalleEmergenciaSegue",
               let destino = segue.destination as? EmergencyDetailViewController {
                if let evento = sender as? EmergencyEventResponse {
                    destino.evento = evento
                }
                else if let cell = sender as? UITableViewCell,
                        let indexPath = historyTableView.indexPath(for: cell) {
                    destino.evento = eventos[indexPath.row]
                }
            }
        }

    private var token: String? { UserDefaults.standard.string(forKey: "userToken") }
    private var userId: Int { UserDefaults.standard.integer(forKey: "userId") }

    private func cargarEventos() {
        guard let tk = token, userId != 0 else {
            cargarHistorialOffline()
            return
        }

        EmergencyEventService.shared.obtenerEventosPorUsuario(userId: userId, token: tk) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let lista):
                    self?.eventos = lista.sorted(by: { $0.id > $1.id })
                    self?.historyTableView.reloadData()
                case .failure:
                    self?.cargarHistorialOffline()
                }
            }
        }
    }

    private func cargarHistorialOffline() {
        let fetchRequest: NSFetchRequest<HistorialEntity> = HistorialEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "fecha", ascending: false)]
        
        do {
            let locales = try CoreDataManager.shared.context.fetch(fetchRequest)
            
            let isoFormatter = ISO8601DateFormatter()
            
            self.eventos = locales.map { entity in
                return EmergencyEventResponse(
                    id: Int(entity.eventId),
                    userId: self.userId,
                    status: "OFFLINE",
                    createdAt: isoFormatter.string(from: entity.fecha ?? Date()),
                    resolvedAt: nil,
                    type: entity.tipo ?? "Emergencia",
                    description: "Registro guardado localmente",
                    latitude: entity.latitude,
                    longitude: entity.longitude
                )
            }
            self.historyTableView.reloadData()
        } catch {
            print("Error CoreData: \(error)")
        }
    }

    private func formatearFecha(_ iso: String, formato: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var fecha = isoFormatter.date(from: iso)
        
        if fecha == nil {
            let alt = ISO8601DateFormatter()
            alt.formatOptions = [.withInternetDateTime]
            fecha = alt.date(from: iso)
        }
        
        guard let date = fecha else { return iso }
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_PE")
        df.dateFormat = formato
        return df.string(from: date)
    }
}

extension EmergencyHistoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellHistory")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cellHistory")

        let evt = eventos[indexPath.row]
        
        let fechaFormateada = formatearFecha(evt.createdAt, formato: "dd MMM yyyy - HH:mm")
        
        cell.textLabel?.text = "Alerta:"
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        cell.textLabel?.textColor = UIColor(red: 6/255, green: 78/255, blue: 59/255, alpha: 1.0)
        
        cell.detailTextLabel?.text = "\(fechaFormateada) • \(evt.status ?? "")"
        cell.detailTextLabel?.textColor = .darkGray
        
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let evt = eventos[indexPath.row]
        performSegue(withIdentifier: "detalleEmergenciaSegue", sender: evt)
    }
}
