//
//  ProfileViewController.swift
//  NovaMovil
//
//  Created by user288878 on 12/15/25.
//

import UIKit

class ProfileViewController: UIViewController {

    
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var fullnameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var editProfileButton: UIButton!
    
    @IBOutlet weak var closeSessionButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            print("Usuario ya logueado con token: \(token)")
        
            
            
            
        }
        
    }
    

    @IBAction func EditProfileButtonTapped(_ sender: Any) {
        
        
        
        
    }
    
    @IBAction func CloseSessionButtonTapped(_ sender: Any) {
        
        UserDefaults.standard.removePersistentDomain(
            forName: Bundle.main.bundleIdentifier!
        )
        
    }
    
   /* private func obtenerDatosDeUsuario(id: Int, token: String) {
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
    }*/
    
}
