import Foundation

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String
    let userId: Int
    let email: String
}
struct RegisterRequest: Codable {
    let fullName: String
    let email: String
    let phone: String
    let password: String
}
