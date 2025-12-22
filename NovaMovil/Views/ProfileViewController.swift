import UIKit

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet weak var NombresView: UITextField!
    
    @IBOutlet weak var EmailVie: UITextField!
    
    @IBOutlet weak var BtnCerrar: UIButton!

    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    var usuario: UserDetail?
    private var token: String?
    private var userId: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        if let usuario = usuario {
             NombresView.text = usuario.fullName
             EmailVie.text = usuario.email
         }
        nameTextField.isEnabled = false
        emailTextField.isEnabled = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        // Tap para cambiar imagen de perfil
        let tap = UITapGestureRecognizer(target: self, action: #selector(changeProfileImage))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tap)

        // Cargar imagen guardada localmente si existe
        if let saved = loadProfileImage() {
            profileImageView.image = saved
        }
        cargarUsuario()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
    }
    
    /*@IBAction func cerrarSesion(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        dismiss(animated: true)
    }*/
    
    
    @IBAction func closeSessionButtonTapped(_ sender: Any) {
        let alerta = UIAlertController(title: "Cerrar sesión", message: "¿Desea salir de su cuenta?", preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alerta.addAction(UIAlertAction(title: "Salir", style: .destructive, handler: { _ in
            // Limpiar datos de usuario
            UserDefaults.standard.removeObject(forKey: "userToken")
            UserDefaults.standard.removeObject(forKey: "userId")
            
            // Instanciar HomeViewController y ponerlo como root
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let homeVC = storyboard.instantiateViewController(withIdentifier: "login") as? LoginViewController else { return }
            let nav = UINavigationController(rootViewController: homeVC)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let sceneDelegate = windowScene.delegate as? SceneDelegate {
                sceneDelegate.window?.rootViewController = nav
                sceneDelegate.window?.makeKeyAndVisible()
            }
        }))
        present(alerta, animated: true)
    }
}

private extension ProfileViewController {
    @objc func changeProfileImage() {
        // Solo galería
        presentPicker(source: .photoLibrary)
    }

    func presentPicker(source: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = true
        // iPad: configurar popover si es fototeca
        if let pop = picker.popoverPresentationController {
            pop.sourceView = profileImageView
            pop.sourceRect = profileImageView.bounds
        }
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        if let img = image {
            profileImageView.image = img
            _ = saveProfileImage(img)
        }
        dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    func saveProfileImage(_ image: UIImage) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return false }
        let url = getDocumentsDirectory().appendingPathComponent("profile.jpg")
        do {
            try data.write(to: url, options: .atomic)
            UserDefaults.standard.set("profile.jpg", forKey: "profileImageFilename")
            return true
        } catch {
            return false
        }
    }

    func loadProfileImage() -> UIImage? {
        let filename = UserDefaults.standard.string(forKey: "profileImageFilename") ?? "profile.jpg"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }

    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    func cargarUsuario() {
        token = UserDefaults.standard.string(forKey: "userToken")
        userId = UserDefaults.standard.integer(forKey: "userId")
        guard let tk = token, userId != 0 else { return }

        UserService.shared.obtenerUsuario(id: userId, token: tk) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let detalle):
                    self?.usuario = detalle
                    self?.nameTextField.text = detalle.fullName
                    self?.emailTextField.text = detalle.email
                    if self?.profileImageView.image == nil {
                        // Si no hay imagen guardada ni remota, usar un placeholder
                        self?.profileImageView.image = UIImage(systemName: "person.circle.fill")
                    }
                case .failure:
                    break
                }
            }
        }
    }
}
