import Foundation

struct Conexion {
    

    static let baseURL = "https://nova-api-angxeebpfffycrcf.brazilsouth-01.azurewebsites.net"
    
    struct Endpoints {
        static let login = "/auth/login"
        static let usuarios = "/api/users"
    }
}
