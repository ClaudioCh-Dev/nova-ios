import Foundation

// MARK: - Request (Lo que envías)
// Esto se queda igual porque el backend SÍ pide estos datos para crear
struct CreateEmergencyEventRequest: Codable {
    let userId: Int
    let type: String
    let description: String
    let latitude: Double
    let longitude: Double
}

// MARK: - Response (Lo que recibes)
struct EmergencyEventResponse: Codable {
    let id: Int
    let userId: Int
    let status: String?
    let createdAt: String
    let resolvedAt: String?
    let type: String?
    let description: String?
    let latitude: Double?
    let longitude: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, userId, status
        case createdAt = "activatedAt"
        case resolvedAt = "closedAt"
        case type, description, latitude, longitude
    }
}
