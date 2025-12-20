
import Foundation

struct ContactResponse: Codable {
    let id: Int
    let userId: Int
    let name: String
    let phone: String
    let email: String?
}

struct CreateContactRequest: Codable {
    let userId: Int
    let name: String
    let phone: String
    let email: String?
}

struct ContactoUI {
    let nombre: String
    let id: String? // opcional si usas identificador CNContact
}
