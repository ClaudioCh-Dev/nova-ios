//
//  EmergencyDetailViewController.swift
//  NovaMovil
//
//  Created by user288878 on 12/15/25.
//

import UIKit
import MapKit

class EmergencyDetailViewController: UIViewController {
    
    
    @IBOutlet weak var dayLabel: UILabel!
    
    
    @IBOutlet weak var scheduleLabel: UILabel!
    
    @IBOutlet weak var mapMapView: MKMapView!
    
    
    	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func pdfButtonTapped(_ sender: Any) {
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
