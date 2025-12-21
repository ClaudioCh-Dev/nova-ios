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

// Modelo resumido que solo usa los campos necesarios en la vista de historial
struct EmergencyEventSummary: Codable {
    let id: Int
    let userId: Int?
    let status: String?
    let activatedAt: String?
    let closedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, userId, status, activatedAt, closedAt
    }
}

