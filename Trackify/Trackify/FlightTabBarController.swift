//
//  ViewController.swift
//  Trackify
//
//  Created by Chase Brandon on 3/8/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit

class FlightTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
        (self.viewControllers![0] as! FlightsTableViewController).title="Upcoming"
        (self.viewControllers![0] as! FlightsTableViewController).tabBarItem.image=#imageLiteral(resourceName: "user_icon_blue")
        (self.viewControllers![1] as! FlightsTableViewController).title="Past"
        (self.viewControllers![1] as! FlightsTableViewController).tabBarItem.image=#imageLiteral(resourceName: "password_icon_blue")
        (self.viewControllers![2] as! FlightsTableViewController).title="Shared"
        (self.viewControllers![2] as! FlightsTableViewController).tabBarItem.image=#imageLiteral(resourceName: "share_icon_blue")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
