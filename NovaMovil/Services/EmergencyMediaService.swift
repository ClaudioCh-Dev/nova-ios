import Foundation

class EmergencyMediaService {

    static let shared = EmergencyMediaService()

    // MARK: - CREATE MEDIA
    func crearMediaEmergencia(
        datos: CreateEmergencyMediaRequest,
        token: String,
        completion: @escaping (Result<EmergencyMediaResponse, Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-media"
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

        realizarPeticion(request: request, tipo: EmergencyMediaResponse.self, completion: completion)
    }

    // MARK: - GET MEDIA BY ID
    func obtenerMediaPorId(
        id: Int,
        token: String,
        completion: @escaping (Result<EmergencyMediaResponse, Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-media/\(id)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: EmergencyMediaResponse.self, completion: completion)
    }

    // MARK: - GET MEDIA BY EVENT
    func obtenerMediaPorEvento(
        eventId: Int,
        token: String,
        completion: @escaping (Result<[EmergencyMediaResponse], Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-media/event/\(eventId)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: [EmergencyMediaResponse].self, completion: completion)
    }

    // MARK: - GET MEDIA BY TYPE
    func obtenerMediaPorTipo(
        mediaType: String,
        token: String,
        completion: @escaping (Result<[EmergencyMediaResponse], Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-media/type/\(mediaType)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: [EmergencyMediaResponse].self, completion: completion)
    }

    // MARK: - DELETE MEDIA
    func eliminarMedia(
        id: Int,
        token: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/emergency-media/\(id)"
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
                let errorMsg = "Error al eliminar media"
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

