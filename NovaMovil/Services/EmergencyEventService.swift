import Foundation

class EmergencyEventService {

    static let shared = EmergencyEventService()

    // MARK: - CREATE EVENT
    func crearEvento(
        datos: CreateEmergencyEventRequest,
        token: String,
        completion: @escaping (Result<EmergencyEventResponse, Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-events"
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

        realizarPeticion(request: request, tipo: EmergencyEventResponse.self, completion: completion)
    }

    // MARK: - GET EVENT BY ID
    func obtenerEventoPorId(
        id: Int,
        token: String,
        completion: @escaping (Result<EmergencyEventResponse, Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-events/\(id)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: EmergencyEventResponse.self, completion: completion)
    }

    // MARK: - GET ALL EVENTS
    func obtenerTodosLosEventos(
        token: String,
        completion: @escaping (Result<[EmergencyEventResponse], Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-events"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: [EmergencyEventResponse].self, completion: completion)
    }

    // MARK: - GET EVENTS BY USER
    func obtenerEventosPorUsuario(
        userId: Int,
        token: String,
        completion: @escaping (Result<[EmergencyEventResponse], Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-events/user/\(userId)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: [EmergencyEventResponse].self, completion: completion)
    }

    // MARK: - GET ACTIVE EVENTS
    func obtenerEventosActivos(
        token: String,
        completion: @escaping (Result<[EmergencyEventResponse], Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-events/active"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: [EmergencyEventResponse].self, completion: completion)
    }

    // MARK: - GET RESOLVED EVENTS
    func obtenerEventosResueltos(
        token: String,
        completion: @escaping (Result<[EmergencyEventResponse], Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-events/resolved"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: [EmergencyEventResponse].self, completion: completion)
    }

    // MARK: - RESOLVE EVENT
    func resolverEvento(
        id: Int,
        token: String,
        completion: @escaping (Result<EmergencyEventResponse, Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-events/\(id)/resolve"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: EmergencyEventResponse.self, completion: completion)
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
