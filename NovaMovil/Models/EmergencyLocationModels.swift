import Foundation

struct CreateEmergencyLocationRequest: Codable {
    let emergencyEventId: Int
    let latitude: Double
    let longitude: Double
}

struct EmergencyLocationResponse: Codable {
    let id: Int
    let emergencyEventId: Int
    let latitude: Double
    let longitude: Double
    let capturedAt: String
}
