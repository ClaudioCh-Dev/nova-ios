import Foundation

struct CreateEmergencyEventRequest: Codable {
    let userId: Int
    let type: String
    let description: String
    let latitude: Double
    let longitude: Double
}

import Foundation

struct EmergencyEventResponse: Codable {
    let id: Int
    let userId: Int
    let type: String
    let description: String
    let latitude: Double
    let longitude: Double
    let status: String
    let createdAt: String
    let resolvedAt: String?
}

