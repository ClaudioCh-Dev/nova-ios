
import Foundation

class AuthService{
    static let shared = AuthService()
    
    func login(req: LoginRequest, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        let urlString = Conexion.baseURL + Conexion.Endpoints.login
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(req)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "InvalidResponse", code: 0, userInfo: nil)))
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMsg = "Error del servidor. Código: \(httpResponse.statusCode)"
                completion(.failure(NSError(domain: "ServerErr", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                return
            }
            
            guard let data = data else { return }
            
            do {
                let responseObj = try JSONDecoder().decode(LoginResponse.self, from: data)
                completion(.success(responseObj))
            } catch {
                completion(.failure(error))
            }
            
        }.resume()
    }
}
