import UIKit
import CoreLocation

class ConfiguracionViewController: UIViewController {
    
    var usuario: UserDetail?
    // MARK: - IBOutlets
    @IBOutlet weak var locationSwitch: UISwitch!
    @IBOutlet weak var recordingSwitch: UISwitch!
    
    @IBOutlet weak var dropdownButton: UIButton!
    @IBOutlet weak var dropdownChevron: UIImageView!
    @IBOutlet weak var dropdownPanel: UIView!
    @IBOutlet weak var audioOptionButton: UIButton!
    @IBOutlet weak var photoOptionButton: UIButton!
    @IBOutlet weak var dropdownContainer: UIView!
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private let defaults = UserDefaults.standard
    
    private let locationEnabledKey = "locationEnabled"
    private let recordingEnabledKey = "recordingEnabled"
    private let selectedTypeKey = "selectedType"
    
    private var isMonitoringScreen = false
    private var isDropdownOpen = false
    private var dropdownContainerHeightConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupLocationManager()
        setupSwitches()
        setupDropdown()
        loadSavedSettings()
        setupScreenCaptureMonitoring()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLocationStatus()
        updateScreenRecordingStatus()
    }
    
    // MARK: - Setup Methods
    private func setupNavigationBar() {
        title = "Configuración"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func setupSwitches() {
        locationSwitch.addTarget(self, action: #selector(locationSwitchChanged(_:)), for: .valueChanged)
        recordingSwitch.addTarget(self, action: #selector(recordingSwitchChanged(_:)), for: .valueChanged)
        
        locationSwitch.onTintColor = .systemTeal
        recordingSwitch.onTintColor = .systemTeal
    }
    
    private func setupDropdown() {
        dropdownButton.addTarget(self, action: #selector(toggleDropdown), for: .touchUpInside)
        
        audioOptionButton.addTarget(self, action: #selector(audioOptionTapped), for: .touchUpInside)
        photoOptionButton.addTarget(self, action: #selector(photoOptionTapped), for: .touchUpInside)
        
        dropdownPanel.isHidden = true
        dropdownPanel.alpha = 0
        
        if let heightConstraint = dropdownContainer.constraints.first(where: { $0.firstAttribute == .height }) {
            dropdownContainerHeightConstraint = heightConstraint
        }
        loadSelectedType()
    }
    
    // MARK: - Dropdown Actions
    @objc private func toggleDropdown() {
        isDropdownOpen.toggle()
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            if self.isDropdownOpen {
                self.dropdownPanel.isHidden = false
                self.dropdownPanel.alpha = 1
                self.dropdownChevron.transform = CGAffineTransform(rotationAngle: .pi)
                self.dropdownContainerHeightConstraint?.constant = 184 // 80 + 8 + 96
            } else {
                self.dropdownPanel.alpha = 0
                self.dropdownChevron.transform = .identity
                self.dropdownContainerHeightConstraint?.constant = 80
            }
            self.view.layoutIfNeeded()
        } completion: { _ in
            if !self.isDropdownOpen {
                self.dropdownPanel.isHidden = true
            }
        }
    }
    
    @objc private func audioOptionTapped() {
        selectOption(type: "audio", displayText: "🎤 Audio")
    }
    
    @objc private func photoOptionTapped() {
        selectOption(type: "photo", displayText: "📸 Foto")
    }
    
    private func selectOption(type: String, displayText: String) {
        dropdownButton.setTitle(displayText, for: .normal)

        defaults.set(type, forKey: selectedTypeKey)
        defaults.set(displayText, forKey: "\(selectedTypeKey)_display")
        defaults.synchronize()

        toggleDropdown()
    
        showSuccessMessage("Tipo seleccionado: \(displayText)")
    }
    
    private func loadSelectedType() {
        if let savedDisplay = defaults.string(forKey: "\(selectedTypeKey)_display") {
            dropdownButton.setTitle(savedDisplay, for: .normal)
        }
    }
    
    private func setupScreenCaptureMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCaptureDidChange),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
    }
    
    private func loadSavedSettings() {
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
        if sender.isOn {
            enableScreenRecordingProtection()
        } else {
            disableScreenRecordingProtection()
        }
        saveSettings()
    }
    
    // MARK: - Location Methods
    private func enableLocation() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            
        case .denied, .restricted:
            showLocationPermissionAlert()
            locationSwitch.setOn(false, animated: true)
            
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            print("✅ Ubicación activada para NovaMovil")
            NotificationCenter.default.post(name: .locationSettingChanged, object: true)
            showSuccessMessage("Ubicación activada para tu seguridad")
            
        @unknown default:
            break
        }
    }
    
    private func disableLocation() {
        locationManager.stopUpdatingLocation()
        print("⛔️ Ubicación desactivada en NovaMovil")
        NotificationCenter.default.post(name: .locationSettingChanged, object: false)
        showWarningMessage("Ubicación desactivada - Funciones de seguridad limitadas")
    }
    
    private func updateLocationStatus() {
        let status = locationManager.authorizationStatus

        if status == .denied || status == .restricted {
            locationSwitch.isOn = false
            saveSettings()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            if locationSwitch.isOn {
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "⚠️ Permiso de Ubicación Requerido",
            message: "NovaMovil necesita acceso a tu ubicación para funciones de seguridad como alertas de emergencia y rastreo. Ve a Configuración para habilitarlo.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Ir a Configuración", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { _ in
            self.locationSwitch.isOn = false
            self.saveSettings()
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Screen Recording Protection Methods
    private func enableScreenRecordingProtection() {
        isMonitoringScreen = true
        checkCurrentScreenRecordingStatus()
        print("🔒 Protección contra grabación activada")
        NotificationCenter.default.post(name: .recordingSettingChanged, object: true)
        showSuccessMessage("Protección de privacidad activada")
    }
    
    private func disableScreenRecordingProtection() {
        isMonitoringScreen = false
        print("🔓 Protección contra grabación desactivada")
        NotificationCenter.default.post(name: .recordingSettingChanged, object: false)
        showWarningMessage("Protección de privacidad desactivada")
    }
    
    @objc private func screenCaptureDidChange() {
        updateScreenRecordingStatus()
    }
    
    private func updateScreenRecordingStatus() {
        let isCaptured = UIScreen.main.isCaptured
        
        if recordingSwitch.isOn && isCaptured {
            showScreenRecordingDetectedAlert()
        }
    }
    
    private func checkCurrentScreenRecordingStatus() {
        if UIScreen.main.isCaptured {
            showScreenRecordingDetectedAlert()
        }
    }
    
    private func showScreenRecordingDetectedAlert() {
        let alert = UIAlertController(
            title: "🔴 Grabación de Pantalla Detectada",
            message: "Se ha detectado que estás grabando o compartiendo tu pantalla. Por tu seguridad, algunas funciones de NovaMovil pueden estar limitadas.\n\nDetén la grabación para usar todas las funciones.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Ir a Centro de Control", style: .default) { _ in
            self.showHowToStopRecordingInstructions()
        })
        
        alert.addAction(UIAlertAction(title: "Entendido", style: .default))
        present(alert, animated: true)
    }
    
    private func showHowToStopRecordingInstructions() {
        let alert = UIAlertController(
            title: "Cómo detener la grabación",
            message: """
            Para detener la grabación de pantalla:
            
            1. Desliza hacia abajo desde la esquina superior derecha (o hacia arriba en modelos antiguos)
            2. Busca el ícono de grabación (círculo rojo)
            3. Toca el ícono para detener la grabación
            
            También puedes tocar la barra roja en la parte superior de la pantalla.
            """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Entendido", style: .default))
        
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    private func showSuccessMessage(_ message: String) {
        let alert = UIAlertController(title: "✅ Éxito", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
    
    private func showWarningMessage(_ message: String) {
        let alert = UIAlertController(title: "⚠️ Advertencia", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            alert.dismiss(animated: true)
        }
    }
    
    // MARK: - Public Methods
    static func isLocationEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "locationEnabled")
    }
    
    static func isRecordingProtectionEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "recordingEnabled")
    }
    
    static func isScreenBeingCaptured() -> Bool {
        return UIScreen.main.isCaptured
    }
    
    static func getSelectedType() -> String? {
        return UserDefaults.standard.string(forKey: "selectedType")
    }
    
    // MARK: - Deinitializer
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func profileTapped(_ sender: Any) {
        performSegue(withIdentifier: "editProfileSegue", sender: usuario)
    }
}

// MARK: - CLLocationManagerDelegate
extension ConfiguracionViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateLocationStatus()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print("📍 Ubicación actualizada: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Error de ubicación: \(error.localizedDescription)")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let locationSettingChanged = Notification.Name("locationSettingChanged")
    static let recordingSettingChanged = Notification.Name("recordingSettingChanged")
}
