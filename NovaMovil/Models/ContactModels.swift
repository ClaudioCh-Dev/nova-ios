
import Foundation

struct ContactResponse: Codable {
    let id: Int
    let userId: Int
    let fullName: String
    let phoneNumber: String?
    let email: String
    let enableWhatsapp: Bool?
    let emergencyContact: Bool?
}

struct CreateContactRequest: Codable {
    let userId: Int
    let fullName: String
    let phoneNumber: String?
    let email: String
    let enableWhatsapp: Bool?
}

struct ContactoUI {
    let nombre: String
    let id: String? // opcional si usas identificador CNContact
}
