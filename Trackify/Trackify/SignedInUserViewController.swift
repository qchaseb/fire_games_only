//
//  SignedInUserViewController.swift
//  Trackify
//
//  Created by Chase Brandon on 2/3/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit

class SignedInUserViewController: UIViewController {

    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    // a subview that will be added to our current view with a
    // spinner, indicating we are attempting to retrieve data from AWS
    var spinner = UIActivityIndicatorView()
    
    
    @IBAction func logOutTapped(_ sender: Any) {
        self.navigationController!.popViewController(animated: true)
    }
    
    var user : User?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        firstNameLabel.text = user?.first_name
        lastNameLabel.text = user?.last_name
        emailLabel.text = user?.email_id
        
        startSpinner(&spinner)
        
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
