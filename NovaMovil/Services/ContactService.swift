//
//  ContactService.swift
//  NovaMovil
//
//  Created by user288878 on 12/19/25.
//
import Foundation

class ContactService {

    static let shared = ContactService()

    // MARK: - CREATE CONTACT
    func crearContacto(
        datos: CreateContactRequest,
        token: String,
        completion: @escaping (Result<ContactResponse, Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/contacts"
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

        realizarPeticion(request: request, tipo: ContactResponse.self, completion: completion)
    }

    // MARK: - GET CONTACT BY ID
    func obtenerContactoPorId(
        id: Int,
        token: String,
        completion: @escaping (Result<ContactResponse, Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/contacts/\(id)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: ContactResponse.self, completion: completion)
    }

    // MARK: - GET ALL CONTACTS
    func obtenerTodosLosContactos(
        token: String,
        completion: @escaping (Result<[ContactResponse], Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/contacts"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: [ContactResponse].self, completion: completion)
    }

    // MARK: - GET CONTACTS BY USER
    func obtenerContactosPorUsuario(
        userId: Int,
        token: String,
        completion: @escaping (Result<[ContactResponse], Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/contacts/user/\(userId)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        realizarPeticion(request: request, tipo: [ContactResponse].self, completion: completion)
    }

    // MARK: - DELETE CONTACT
    func eliminarContacto(
        id: Int,
        token: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let urlString = "\(Conexion.baseURL)/api/contacts/\(id)"
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
                let errorMsg = "Error al eliminar contacto"
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
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
