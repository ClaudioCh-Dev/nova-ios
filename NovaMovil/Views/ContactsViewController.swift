import UIKit
import Contacts

class ContactsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var contactosTable: UITableView!
    
    var contactos: [CNContact] = []
    var usuarioSesion: UserDetail?
    
    // Closure para devolver el contacto seleccionado al Home
    var contactoSeleccionado: ((CNContact) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configuración básica de la tabla
        contactosTable.dataSource = self
        contactosTable.delegate = self
        
        // Estilo de la tabla
        contactosTable.rowHeight = 80 // Altura para que se vea bien el avatar
        contactosTable.separatorStyle = .none // Quitamos líneas feas, usamos diseño limpio
        
        // Pediremos permisos cuando la vista ya esté en pantalla
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Pedir permisos y cargar cuando la vista está en la jerarquía
        requestContactsAccess()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Usamos el identificador que puse en el XML
        let cell = tableView.dequeueReusableCell(withIdentifier: "celdaContacto", for: indexPath)
        let contacto = contactos[indexPath.row]
        
        // --- CONEXIÓN CON EL DISEÑO XML USANDO TAGS ---
        // Tag 100: Label de Iniciales (Dentro del círculo)
        // Tag 101: Label del Nombre
        // Tag 102: Label del Teléfono
        
        // 1. Configurar Iniciales y Avatar
        if let initialsLabel = cell.viewWithTag(100) as? UILabel {
            let letters = (contacto.givenName.prefix(1) + contacto.familyName.prefix(1)).uppercased()
            initialsLabel.text = letters.isEmpty ? "?" : letters
            
            // Hacemos el círculo perfecto por código
            if let avatarContainer = initialsLabel.superview {
                avatarContainer.layer.cornerRadius = avatarContainer.frame.height / 2
                avatarContainer.clipsToBounds = true
            }
        }
        
        // 2. Configurar Nombre
        if let nameLabel = cell.viewWithTag(101) as? UILabel {
            nameLabel.text = "\(contacto.givenName) \(contacto.familyName)"
        }
        
        // 3. Configurar Teléfono
        if let phoneLabel = cell.viewWithTag(102) as? UILabel {
            if let numero = contacto.phoneNumbers.first?.value.stringValue {
                phoneLabel.text = numero
            } else {
                phoneLabel.text = "Sin número disponible"
            }
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate (La Funcionalidad de Agregar)
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Efecto visual de selección
        tableView.deselectRow(at: indexPath, animated: true)
        
        let contacto = contactos[indexPath.row]
        
        // Mostrar alerta de confirmación profesional
        let alerta = UIAlertController(
            title: "Agregar Contacto",
            message: "¿Deseas agregar a \(contacto.givenName) a tu red de seguridad?",
            preferredStyle: .actionSheet
        )
        
        let accionAgregar = UIAlertAction(title: "Sí, agregar", style: .default) { _ in
            // 1. Ejecutamos el closure para avisar a HomeViewController
            self.contactoSeleccionado?(contacto)
            
            // 2. Cerramos la pantalla
            self.dismiss(animated: true)
        }
        
        let accionCancelar = UIAlertAction(title: "Cancelar", style: .cancel)
        
        // Color verde para la acción positiva (Estilo Nova)
        accionAgregar.setValue(UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1), forKey: "titleTextColor")
        
        alerta.addAction(accionAgregar)
        alerta.addAction(accionCancelar)
        
        present(alerta, animated: true)
    }
    
    // MARK: - Acceso a Contactos (Tu lógica original optimizada)
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
                } else {
                    DispatchQueue.main.async {
                        self.mostrarAlertaPermisos()
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.mostrarAlertaPermisos()
            }
        @unknown default:
            break
        }
    }
    
    private func fetchContacts(store: CNContactStore) {
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey
        ] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        DispatchQueue.global(qos: .userInitiated).async {
            var fetchedContacts: [CNContact] = []
            try? store.enumerateContacts(with: request) { contact, _ in
                // Filtro opcional: Solo mostrar contactos con número de teléfono
                if !contact.phoneNumbers.isEmpty {
                    fetchedContacts.append(contact)
                }
            }
            
            DispatchQueue.main.async {
                self.contactos = fetchedContacts
                self.contactosTable.reloadData()
            }
        }
    }
    
    private func mostrarAlertaPermisos() {
        let alert = UIAlertController(
            title: "Permiso de Contactos",
            message: "Necesitamos acceso a tus contactos para añadirlos a tu red de seguridad. Puedes permitirlo en Ajustes.",
            preferredStyle: .alert
        )

        let abrirAjustes = UIAlertAction(title: "Abrir Ajustes", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        let cancelar = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)

        alert.addAction(abrirAjustes)
        alert.addAction(cancelar)

        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
}
