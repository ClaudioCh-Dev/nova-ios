import UIKit
import Contacts
import ContactsUI

class ContactsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var contactosTable: UITableView!
    
    var contactos: [CNContact] = [] // Aquí guardamos los contactos
    var usuarioSesion: UserDetail?   // 👈 AÑADE ESTO

    // Agrega esta propiedad al inicio de la clase
    var contactoSeleccionado: ((CNContact) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        contactosTable.dataSource = self
        contactosTable.delegate = self
        
        // Registrar celda si es que no estás usando prototype cell
        // contactosTable.register(UITableViewCell.self, forCellReuseIdentifier: "celdaContacto")
        
        // Gestos
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 1.0
        contactosTable.addGestureRecognizer(longPress)
        
        requestContactsAccess()
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "celdaContacto", for: indexPath)
        let contacto = contactos[indexPath.row]
        cell.textLabel?.text = "\(contacto.givenName) \(contacto.familyName)"
        return cell
    }
    
    // MARK: - Gestos
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: contactosTable)
        if let indexPath = contactosTable.indexPathForRow(at: point), gesture.state == .began {
            let contact = contactos[indexPath.row]
            
            let alert = UIAlertController(title: contact.givenName, message: "Opciones", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Poner como predeterminado", style: .default) { _ in
                self.agregarPredeterminado(contact)
            })
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
            
            present(alert, animated: true)
        }
    }
    
    // MARK: - Acceso a contactos
    private func requestContactsAccess() {
        let store = CNContactStore()
           let status = CNContactStore.authorizationStatus(for: .contacts)

           switch status {

           case .authorized:
               fetchContacts(store: store)

           case .notDetermined:
               store.requestAccess(for: .contacts) { granted, _ in
                   if granted {
                       self.fetchContacts(store: store)
                   }
               }

           case .denied, .restricted:
               print("Permiso de contactos denegado")

           @unknown default:
               break
           }
    }
    
    private func fetchContacts(store: CNContactStore) {
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey
        ]
        
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        
        DispatchQueue.global(qos: .userInitiated).async { // hilo de fondo
            var fetchedContacts: [CNContact] = []
            
            do {
                try store.enumerateContacts(with: request) { contact, _ in
                    fetchedContacts.append(contact)
                }
                
                // Actualizamos la UI en el main thread
                DispatchQueue.main.async {
                    self.contactos = fetchedContacts
                    self.contactosTable.reloadData()
                }
                
            } catch {
                print("Error al leer contactos:", error)
            }
        }
    }


    // MARK: - Función de ejemplo para predeterminado
    private func agregarPredeterminado(_ contact: CNContact) {
        print("Contacto predeterminado: \(contact.givenName)")
           
           // Avisamos a HomeViewController
           contactoSeleccionado?(contact)
           
           // Cerramos la vista
           dismiss(animated: true)

    }
}
