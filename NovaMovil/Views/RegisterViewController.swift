import UIKit




class RegisterViewController: UIViewController {

    
    @IBOutlet weak var nombreView: UITextField!
    
    @IBOutlet weak var correoView: UITextField!
    
    @IBOutlet weak var telefonoView: UITextField!
    
    @IBOutlet weak var contraView: UITextField!
    
    @IBOutlet weak var contraConfir: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contraView.isSecureTextEntry = true
        contraConfir.isSecureTextEntry = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ocultarTeclado))
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    @objc func ocultarTeclado() {
        view.endEditing(true)
    }
    
 

    @IBAction func crearConfir(_ sender: Any) {
    
    guard let nombre = nombreView.text, !nombre.isEmpty,
          let email = correoView.text, !email.isEmpty,
          let telefono = telefonoView.text, !telefono.isEmpty,
          let password = contraView.text, !password.isEmpty,
          let confirm = contraConfir.text, !confirm.isEmpty else {
        mostrarAlerta(mensaje: "Complete todos los campos")
        return
    }
    
    guard password == confirm else {
        mostrarAlerta(mensaje: "Las contraseñas no coinciden")
        return
    }
    
    let nuevoUsuario = RegisterRequest(
        fullName: nombre,
        email: email,
        phone: telefono,
        password: password
    )
    
    
    UserService.shared.registrarUsuario(datos: nuevoUsuario) { [weak self] result in
        DispatchQueue.main.async {
            
            switch result {
            case .success(_):
                self?.mostrarAlerta(mensaje: "Cuenta creada correctamente") {
                    self?.navigationController?.popViewController(animated: true)
                }
                
            case .failure(let error):
                self?.mostrarAlerta(mensaje: "Error al registrar: \(error.localizedDescription)")
            }
        }
    }
}

private func mostrarAlerta(mensaje: String, completion: (() -> Void)? = nil) {
    let alerta = UIAlertController(title: "Atención", message: mensaje, preferredStyle: .alert)
    let accion = UIAlertAction(title: "Aceptar", style: .default) { _ in
        completion?()
    }
    alerta.addAction(accion)
    present(alerta, animated: true)
}
}
