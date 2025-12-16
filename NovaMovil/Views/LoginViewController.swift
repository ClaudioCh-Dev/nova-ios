
import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var CorreoView: UITextField!
    
    @IBOutlet weak var ContraView: UITextField!
    
    @IBOutlet weak var Ingresar: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func IngresarAction(_ sender: Any) {
        guard let email = CorreoView.text, !email.isEmpty else {
                    presentarAlerta(mensaje: "Introduzca su email")
                    return
                }
                
                guard let password = ContraView.text, !password.isEmpty else {
                    presentarAlerta(mensaje: "Introduzca su contraseña")
                    return
                }
                
                let datosLogin = LoginRequest(email: email, password: password)
             
                AuthService.shared.login(req: datosLogin) { [weak self] result in
                    switch result {
                    case .success(let loginResp):
                        
                        // Guardamos token básico
                        UserDefaults.standard.set(loginResp.token, forKey: "userToken")
                        
                        // Guardamos el id
                        UserDefaults.standard.set(loginResp.userId, forKey: "userId")
                        
                        self?.obtenerDatosDeUsuario(id: loginResp.userId, token: loginResp.token)
                        
                    case .failure:
                        DispatchQueue.main.async {
                            self?.presentarAlerta(mensaje: "Credenciales incorrectas")
                        }
                    }
                }
            }
            
            private func obtenerDatosDeUsuario(id: Int, token: String) {
                UserService.shared.obtenerUsuario(id: id, token: token) { [weak self] result in
                    DispatchQueue.main.async {
                        self?.Ingresar.isEnabled = true
                        
                        switch result {
                        case .success(let usuarioDetalle):
                            if usuarioDetalle.status == "ACTIVE" {
                                self?.performSegue(withIdentifier: "loginSegue", sender: usuarioDetalle)
                            } else {
                                self?.presentarAlerta(mensaje: "Usuario inactivo")
                            }
                            
                        case .failure(let error):
                            self?.presentarAlerta(mensaje: "Login correcto, pero error al obtener perfil: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            // MARK: - Navigation
            override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if segue.identifier == "loginSegue" {
                    if let destino = segue.destination as? HomeViewController,
                       let usuario = sender as? UserDetail {
                        destino.usuarioSesion = usuario
                        print("usuario: \(usuario)")
                    }
                }
            }
            
            private func presentarAlerta(mensaje: String) {
                let alerta = UIAlertController(title: "Atención", message: mensaje, preferredStyle: .alert)
                alerta.addAction(UIAlertAction(title: "Aceptar", style: .default))
                self.present(alerta, animated: true)
            }
        }

