//
//  ProfileEditViewController.swift
//  NovaMovil
//
//  Created by DAMII on 20/12/25.
//

import UIKit

private let reuseIdentifier = "Cell"

class ProfileEditViewController: UIViewController {

    var usuario: UserDetail?
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
    }
    
}
