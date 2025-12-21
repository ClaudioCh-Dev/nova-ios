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
    let userId: Int?
    let status: String
    let createdAt: String
    let resolvedAt: String?

    // Campos opcionales que podrían no venir del API actual
    let type: String?
    let description: String?
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case status
        // Mapear nombres del backend a los usados en la app
        case createdAt = "activatedAt"
        case resolvedAt = "closedAt"
        case type
        case description
        case latitude
        case longitude
    }
}

