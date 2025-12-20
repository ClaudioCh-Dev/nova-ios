//
//  ProfileViewController.swift
//  NovaMovil
//
//  Created by user288878 on 12/15/25.
//

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    private var usuario: UserDetail?
    private var token: String?
    private var userId: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.isEnabled = false
        emailTextField.isEnabled = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = profileImageView.bounds.width/2
        profileImageView.clipsToBounds = true
        cargarUsuario()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func editButtonTapped(_ sender: Any) {
        let nuevo = !nameTextField.isEnabled
        nameTextField.isEnabled = nuevo
        emailTextField.isEnabled = nuevo
        if nuevo {
            nameTextField.becomeFirstResponder()
        } else {
            view.endEditing(true)
        }
    }
    
    @IBAction func closeSessionButtonTapped(_ sender: Any) {
        let alerta = UIAlertController(title: "Cerrar sesión", message: "¿Desea salir de su cuenta?", preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alerta.addAction(UIAlertAction(title: "Salir", style: .destructive, handler: { [weak self] _ in
            UserDefaults.standard.removeObject(forKey: "userToken")
            UserDefaults.standard.removeObject(forKey: "userId")
            if let nav = self?.navigationController {
                nav.popToRootViewController(animated: true)
            } else {
                self?.dismiss(animated: true)
            }
        }))
        present(alerta, animated: true)
    }
}

private extension ProfileViewController {
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
                        self?.profileImageView.image = UIImage(systemName: "person.circle.fill")
                    }
                case .failure:
                    break
                }
            }
        }
    }
}
