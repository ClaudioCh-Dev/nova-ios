
import Foundation

struct UserDetail: Codable {
    let id: Int
    let fullName: String
    let email: String
    let phone: String
    let status: String
}


struct UpdateUserRequest: Codable {
    let fullName: String
    let email: String
    let phone: String
}








