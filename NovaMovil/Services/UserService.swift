import Foundation

class UserService {
    
    static let shared = UserService()

    
    func obtenerUsuario(id: Int, token: String, completion: @escaping (Result<UserDetail, Error>) -> Void) {
        let urlString = "\(Conexion.baseURL)/api/users/\(id)"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") //
        realizarPeticion(request: request, tipo: UserDetail.self, completion: completion)
    }
    
    func registrarUsuario(datos: RegisterRequest, completion: @escaping (Result<UserDetail, Error>) -> Void) {
            let urlString = "\(Conexion.baseURL)/api/users"
            guard let url = URL(string: urlString) else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST" // Importante
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                request.httpBody = try JSONEncoder().encode(datos)
            } catch {
                completion(.failure(error))
                return
            }
            
            realizarPeticion(request: request, tipo: UserDetail.self, completion: completion)
        }
    
    
    private func realizarPeticion<T: Codable>(request: URLRequest, tipo: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else { return }
            
            guard httpResponse.statusCode == 200 else {
                let errorMsg = "Fallo del servidor. Código: \(httpResponse.statusCode)"
                completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedObject))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
