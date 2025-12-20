import Foundation

struct Conexion {

    static let baseURL = "https://nova-api-angxeebpfffycrcf.brazilsouth-01.azurewebsites.net"

    struct Endpoints {

        // 🔐 Auth
        static let login = "/auth/login"
        static let register = "/auth/register"

        // 👤 Users
        static let users = "/api/users"
        static func userById(_ id: Int) -> String {
            return "/api/users/\(id)"
        }

        // 📇 Contacts
        static let contacts = "/api/contacts"
        static func contactsByUser(_ userId: Int) -> String {
            return "/api/users/\(userId)/contacts"
        }

        // 🚨 Emergency Events
        static let emergencyEvents = "/api/emergency-events"
        static func emergencyEventsByUser(_ userId: Int) -> String {
            return "/api/users/\(userId)/emergency-events"
        }

        // 📍 Emergency Locations
        static func emergencyLocations(_ eventId: Int) -> String {
            return "/api/emergency-events/\(eventId)/locations"
        }

        // 🎥 Emergency Media
        static func emergencyMedia(_ eventId: Int) -> String {
            return "/api/emergency-events/\(eventId)/media"
        }
    }
}
