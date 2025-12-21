import Foundation

struct CreateEmergencyLocationRequest: Codable {
    let eventId: Int
    let latitude: Double
    let longitude: Double
    let timestamp: String
}

struct EmergencyLocationResponse: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: String?
}
