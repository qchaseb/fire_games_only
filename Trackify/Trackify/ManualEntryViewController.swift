//
//  ManualEntryViewController.swift
//  Trackify
//
//  Created by Scott Buttinger on 2/7/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit

class ManualEntryViewController: UIViewController, UIPickerViewDelegate {
    
    fileprivate var helpers = Helpers()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAway()
        self.scrollView.isScrollEnabled = false

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpNavigationBar()
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    // Set up the UI for the navigation bar
    fileprivate func setUpNavigationBar() {
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.barTintColor = helpers.themeColor
        
        // set up title image
        let logo = #imageLiteral(resourceName: "trackify_white_title")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x:0, y:0, width:50, height:50)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView
        
        // set up settings button
        let cancelButton = UIBarButtonItem()
        cancelButton.image = #imageLiteral(resourceName: "delete_white_icon")
        cancelButton.tintColor = UIColor.white
        cancelButton.customView?.contentMode = .scaleAspectFit
        cancelButton.target = self
        cancelButton.action = #selector(self.cancelButtonTapped)
        self.navigationItem.leftBarButtonItem = cancelButton
        
        // set up manual entry button
        let doneButton = UIBarButtonItem()
        doneButton.image = #imageLiteral(resourceName: "check_white_icon")
        doneButton.tintColor = UIColor.white
        doneButton.customView?.contentMode = .scaleAspectFit
        self.navigationItem.rightBarButtonItem = doneButton
        
        // set time and battery logos to be white
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    func cancelButtonTapped() {
        self.navigationController!.popViewController(animated: true)
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
