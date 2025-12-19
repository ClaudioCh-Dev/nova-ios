import Foundation

struct CreateEmergencyMediaRequest: Codable {
    let eventId: Int
    let mediaType: String   // PHOTO, VIDEO, AUDIO
    let mediaUrl: String
}

struct EmergencyMediaResponse: Codable {
    let id: Int
    let eventId: Int
    let mediaType: String
    let mediaUrl: String
    let createdAt: String
}
