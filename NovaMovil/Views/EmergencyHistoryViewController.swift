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
                    // 1) Filtrar solo eventos inactivos/cerrados
                    let inactivos = lista.filter { self?.esInactivo($0) ?? false }
                    // 2) Ordenar de más reciente a más antiguo
                    let ordenados = inactivos.sorted { (a, b) in
                        let da = self?.parseISODate(a.activatedAt) ?? Date.distantPast
                        let db = self?.parseISODate(b.activatedAt) ?? Date.distantPast
                        return da > db
                    }
                    self?.eventos = ordenados
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
    
    private func esInactivo(_ evt: EmergencyEventSummary) -> Bool {
        if let s = evt.status?.lowercased() {
            // Abarcar variantes posibles del backend
            if ["inactive", "inactivo", "resolved", "resuelto", "closed", "cerrado", "finalized", "finalizado"].contains(s) {
                return true
            }
            if ["active", "activo"].contains(s) { return false }
        }
        // Fallback lógico: si tiene fecha de cierre, lo consideramos inactivo
        return (evt.closedAt?.isEmpty == false)
    }

    private func parseISODate(_ iso: String?) -> Date? {
        guard let iso = iso, !iso.isEmpty else { return nil }
        // Intento 1: ISO8601 con fracción
        let iso1 = ISO8601DateFormatter()
        iso1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso1.date(from: iso) { return d }
        // Intento 2: ISO8601 simple
        let iso2 = ISO8601DateFormatter()
        iso2.formatOptions = [.withInternetDateTime]
        if let d = iso2.date(from: iso) { return d }
        // Intento 3: "yyyy-MM-dd'T'HH:mm:ss"
        let df1 = DateFormatter()
        df1.locale = Locale(identifier: "en_US_POSIX")
        df1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let d = df1.date(from: iso) { return d }
        // Intento 4: con milisegundos
        let df2 = DateFormatter()
        df2.locale = Locale(identifier: "en_US_POSIX")
        df2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        if let d = df2.date(from: iso) { return d }
        // Intento 5: con zona Z
        let df3 = DateFormatter()
        df3.locale = Locale(identifier: "en_US_POSIX")
        df3.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return df3.date(from: iso)
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