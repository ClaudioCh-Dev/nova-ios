import AppIntents
import UIKit

struct ActivarEmergenciaIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Activar Emergencia Nova"
    static var description = IntentDescription("Activa la alarma y envía ubicación inmediatamente sin abrir la app.")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        
        NotificationCenter.default.post(name: NSNotification.Name("TriggerNovaEmergency"), object: nil)
        
 
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        return .result()
    }
}

struct NovaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ActivarEmergenciaIntent(),
            phrases: ["Activar emergencia en \(.applicationName)", "Ayuda \(.applicationName)"],
            shortTitle: "Pánico Nova",
            systemImageName: "exclamationmark.triangle.fill"
        )
    }
}
