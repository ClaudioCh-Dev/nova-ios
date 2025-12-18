import UIKit
import CoreLocation

class ConfiguracionViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var locationSwitch: UISwitch!
    @IBOutlet weak var recordingSwitch: UISwitch!
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private let defaults = UserDefaults.standard
    
    // Keys para UserDefaults
    private let locationEnabledKey = "locationEnabled"
    private let recordingEnabledKey = "recordingEnabled"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupSwitches()
        loadSavedSettings()
    }
    
    // MARK: - Setup Methods
    private func setupNavigationBar() {
        title = "Configuración"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func setupSwitches() {
        locationSwitch.addTarget(self, action: #selector(locationSwitchChanged(_:)), for: .valueChanged)
        recordingSwitch.addTarget(self, action: #selector(recordingSwitchChanged(_:)), for: .valueChanged)
        
        locationSwitch.onTintColor = .systemTeal
        recordingSwitch.onTintColor = .systemTeal
    }
    
    private func loadSavedSettings() {
        // Cargar configuraciones guardadas
        let locationEnabled = defaults.bool(forKey: locationEnabledKey)
        let recordingEnabled = defaults.bool(forKey: recordingEnabledKey)
        
        if !defaults.bool(forKey: "hasLaunchedBefore") {
            locationSwitch.isOn = true
            recordingSwitch.isOn = true
            defaults.set(true, forKey: "hasLaunchedBefore")
            saveSettings()
        } else {
            locationSwitch.isOn = locationEnabled
            recordingSwitch.isOn = recordingEnabled
        }
        
        updateLocationStatus()
    }
    
    private func saveSettings() {
        defaults.set(locationSwitch.isOn, forKey: locationEnabledKey)
        defaults.set(recordingSwitch.isOn, forKey: recordingEnabledKey)
        defaults.synchronize()
    }
    
    // MARK: - Switch Actions
    @objc private func locationSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            enableLocation()
        } else {
            disableLocation()
        }
        saveSettings()
    }
    
    @objc private func recordingSwitchChanged(_ sender: UISwitch) {

    }
    
    // MARK: - Location Methods
    private func enableLocation() {
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .notDetermined:
            // Primera vez, pedir permiso
            locationManager.requestWhenInUseAuthorization()
            
        case .denied, .restricted:
            showLocationPermissionAlert()
            locationSwitch.setOn(false, animated: true)
            
        case .authorizedWhenInUse, .authorizedAlways:
            print("Ubicación activada")
            NotificationCenter.default.post(name: .locationSettingChanged, object: true)
            
        @unknown default:
            break
        }
    }
    
    private func disableLocation() {
        print("Ubicación desactivada")
        NotificationCenter.default.post(name: .locationSettingChanged, object: false)
    }
    
    private func updateLocationStatus() {
        let status = CLLocationManager.authorizationStatus()
        
        // Si el usuario negó permisos del sistema, desactivar switch
        if status == .denied || status == .restricted {
            locationSwitch.isOn = false
            saveSettings()
        }
    }
    
    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "Permiso de Ubicación",
            message: "Para usar esta función, necesitas habilitar el acceso a la ubicación en Configuración.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Ir a Configuración", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - Recording Methods
    private func enableRecording() {
        print("Grabación automática activada")
        
        // Aquí puedes agregar lógica adicional para la grabación
    }

    // MARK: - Public Methods
    /// Obtiene el estado actual de la configuración de ubicación
    static func isLocationEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "locationEnabled")
    }
    
    /// Obtiene el estado actual de la configuración de grabación
    static func isRecordingEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "recordingEnabled")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let locationSettingChanged = Notification.Name("locationSettingChanged")
    static let recordingSettingChanged = Notification.Name("recordingSettingChanged")
}
