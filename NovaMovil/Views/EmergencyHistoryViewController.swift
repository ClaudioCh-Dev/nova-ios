//
//  EmergencyHistoryViewController.swift
//  NovaMovil
//

import UIKit

class EmergencyHistoryViewController: UIViewController {

    @IBOutlet weak var historyTableView: UITableView!
    private var eventos: [EmergencyEventSummary] = []

    // MARK: - Ciclo de vida
    override func viewDidLoad() {
        super.viewDidLoad()
        historyTableView.delegate = self
        historyTableView.dataSource = self
        // Si usas prototipo en storyboard, no registres celda aquí.
        cargarEventos()
    }

    // MARK: - Navegación
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailEmergencySegue",
           let destino = segue.destination as? EmergencyDetailViewController,
           let evento = sender as? EmergencyEventSummary {
            destino.evento = evento
        }
    }

    // MARK: - Funciones privadas
    private var token: String? { UserDefaults.standard.string(forKey: "userToken") }
    private var userId: Int { UserDefaults.standard.integer(forKey: "userId") }

    private func cargarEventos() {
        guard let tk = token, userId != 0 else { return }

        // Aquí puedes mostrar un indicador de carga si quieres
        EmergencyEventService.shared.obtenerEventosPorUsuarioResumen(userId: userId, token: tk) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let lista):
                    self?.eventos = lista
                    self?.historyTableView.reloadData()
                case .failure(let error):
                    // Manejo del error
                    print("Error al cargar eventos: \(error.localizedDescription)")
                }
            }
        }
    }   

    private func formatearFecha(_ iso: String, formato: String) -> String {
        // Intento 1: ISO8601 con fracción
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var fecha = isoFormatter.date(from: iso)
        // Intento 2: "yyyy-MM-dd'T'HH:mm:ss" (LocalDateTime sin zona)
        if fecha == nil {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            fecha = df.date(from: iso)
        }
        // Intento 3: "yyyy-MM-dd'T'HH:mm:ss.SSS" (con milisegundos)
        if fecha == nil {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            fecha = df.date(from: iso)
        }
        // Intento 4: con zona "Z"
        if fecha == nil {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            fecha = df.date(from: iso)
        }
        guard let date = fecha else { return iso }
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_PE")
        df.dateFormat = formato
        return df.string(from: date)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension EmergencyHistoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "EventCell")

        let evt = eventos[indexPath.row]
        let creadaTxt = formatearFecha(evt.activatedAt ?? "", formato: "dd/MM/yyyy HH:mm")
        let cerradaTxt = formatearFecha(evt.closedAt ?? "", formato: "dd/MM/yyyy HH:mm")
        cell.textLabel?.text = (creadaTxt.isEmpty ? "—" : creadaTxt)
        cell.detailTextLabel?.text = (evt.status ?? "—") + " • " + (cerradaTxt.isEmpty ? "—" : cerradaTxt)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let evt = eventos[indexPath.row]
        performSegue(withIdentifier: "detailEmergencySegue", sender: evt)
    }
}