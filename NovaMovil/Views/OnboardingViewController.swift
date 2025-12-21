import UIKit

class OnboardingViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.bounces = false
        scrollView.alwaysBounceVertical = false
        

        scrollView.contentSize = CGSize(width: view.frame.width * 3, height: view.frame.height)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 3. Ocultar la barra de navegación SOLO en esta pantalla
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}
