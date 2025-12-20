import UIKit

class ProfileViewController: UIViewController {
    
    
    @IBOutlet weak var NombresView: UITextField!
    
    @IBOutlet weak var EmailVie: UITextField!
    
    @IBOutlet weak var BtnCerrar: UIButton!
    
    var usuario: UserDetail?

    override func viewDidLoad() {
        super.viewDidLoad()
        

        if let usuario = usuario {
             NombresView.text = usuario.fullName
             EmailVie.text = usuario.email
         }
    }
    
    @IBAction func cerrarSesion(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        dismiss(animated: true)
    }

}
