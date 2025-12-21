import Foundation

struct CreateEmergencyMediaRequest: Codable {
    let emergencyEventId: Int
    let mediaType: String   // PHOTO, VIDEO, AUDIO
    let storageUrl: String
}

struct EmergencyMediaResponse: Codable {
    let id: Int
    let emergencyEventId: Int
    let mediaType: String
    let storageUrl: String
}
