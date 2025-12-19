import Foundation

class EmergencyLocationService {

    static let shared = EmergencyLocationService()

    // MARK: - CREATE LOCATION
    func crearUbicacionEmergencia(
        datos: CreateEmergencyLocationRequest,
        token: String,
        completion: @escaping (Result<EmergencyLocationResponse, Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-locations"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONEncoder().encode(datos)
        } catch {
            completion(.failure(error))
            return
        }

        realizarPeticion(request: request, tipo: EmergencyLocationResponse.self, completion: completion)
    }

    // MARK: - GET LOCATION BY ID
    func obtenerUbicacionPorId(
        id: Int,
        token: String,
        completion: @escaping (Result<EmergencyLocationResponse, Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-locations/\(id)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: EmergencyLocationResponse.self, completion: completion)
    }

    // MARK: - GET ALL LOCATIONS
    func obtenerTodasLasUbicaciones(
        token: String,
        completion: @escaping (Result<[EmergencyLocationResponse], Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-locations"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: [EmergencyLocationResponse].self, completion: completion)
    }

    // MARK: - GET LOCATIONS BY EVENT
    func obtenerUbicacionesPorEvento(
        eventId: Int,
        token: String,
        completion: @escaping (Result<[EmergencyLocationResponse], Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-locations/event/\(eventId)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: [EmergencyLocationResponse].self, completion: completion)
    }

    // MARK: - DELETE LOCATION
    func eliminarUbicacion(
        id: Int,
        token: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-locations/\(id)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { _, response, error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 204 else {
                let errorMsg = "Error al eliminar ubicación"
                completion(.failure(
                    NSError(
                        domain: "",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: errorMsg]
                    )
                ))
                return
            }

            completion(.success(()))
        }.resume()
    }

    // MARK: - PETICIÓN GENÉRICA
    private func realizarPeticion<T: Codable>(
        request: URLRequest,
        tipo: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else { return }

            guard httpResponse.statusCode == 200 else {
                let errorMsg = "Fallo del servidor. Código: \(httpResponse.statusCode)"
                completion(.failure(
                    NSError(
                        domain: "",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: errorMsg]
                    )
                ))
                return
            }

            guard let data = data else { return }

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
