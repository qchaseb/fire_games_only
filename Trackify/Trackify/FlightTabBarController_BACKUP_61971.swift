//
//  ViewController.swift
//  Trackify
//
//  Created by Chase Brandon on 3/8/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit

class FlightTabBarController: UITabBarController {
<<<<<<< HEAD
    
    fileprivate let helpers = Helpers()
=======
>>>>>>> ee4f028bf38cfb34a3d319ec9d338f155ebf99f7

    override func viewDidLoad() {
        super.viewDidLoad()
        
<<<<<<< HEAD
        // set up tab bar icons and titles
        (self.viewControllers![0] as! FlightsTableViewController).title="Upcoming"
        (self.viewControllers![0] as! FlightsTableViewController).tabBarItem.image=#imageLiteral(resourceName: "small_user_icon_white")
        (self.viewControllers![1] as! FlightsTableViewController).title="Past"
        (self.viewControllers![1] as! FlightsTableViewController).tabBarItem.image=#imageLiteral(resourceName: "hourglass_icon_white")
        (self.viewControllers![2] as! FlightsTableViewController).title="Shared"
        (self.viewControllers![2] as! FlightsTableViewController).tabBarItem.image=#imageLiteral(resourceName: "users_white_icon")
=======
        
        // Do any additional setup after loading the view.
        (self.viewControllers![0] as! FlightsTableViewController).title="Upcoming"
        (self.viewControllers![0] as! FlightsTableViewController).tabBarItem.image=#imageLiteral(resourceName: "user_icon_blue")
        (self.viewControllers![1] as! FlightsTableViewController).title="Past"
        (self.viewControllers![1] as! FlightsTableViewController).tabBarItem.image=#imageLiteral(resourceName: "password_icon_blue")
        (self.viewControllers![2] as! FlightsTableViewController).title="Shared"
        (self.viewControllers![2] as! FlightsTableViewController).tabBarItem.image=#imageLiteral(resourceName: "share_icon_blue")
>>>>>>> ee4f028bf38cfb34a3d319ec9d338f155ebf99f7
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
<<<<<<< HEAD
        setUpTabBar()
        setUpNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
                UIApplication.shared.statusBarStyle = .default
                self.navigationController?.isNavigationBarHidden = true
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    fileprivate func setUpTabBar() {
        self.tabBar.barTintColor = UIColor.white
        self.tabBar.tintColor = helpers.themeColor
    }
    
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
        
        // set up menu button
        let menuButton = UIBarButtonItem()
        menuButton.image = #imageLiteral(resourceName: "menu_icon")
        menuButton.tintColor = UIColor.white
        menuButton.customView?.contentMode = .scaleAspectFit
        menuButton.target = self
        menuButton.action = #selector(self.menuButtonTapped(_:))
        self.navigationItem.leftBarButtonItem = menuButton
        
        // set up manual entry button
        let addButton = UIBarButtonItem()
        addButton.image = #imageLiteral(resourceName: "plus_icon")
        addButton.tintColor = UIColor.white
        addButton.customView?.contentMode = .scaleAspectFit
        addButton.target = self
        addButton.action = #selector(self.manualEntryButtonTapped)
        self.navigationItem.rightBarButtonItem = addButton
        
        // set time and battery logos to be white
        UIApplication.shared.statusBarStyle = .lightContent
    }
    func manualEntryButtonTapped() {
        if let flightsVC = self.selectedViewController as? FlightsTableViewController {
            flightsVC.editingFlight = false
            flightsVC.performSegue(withIdentifier: Storyboard.ManualEntrySegue , sender: flightsVC)
        }
    }
    
    // open or close slider menu with animation
    func menuButtonTapped(_ sender : UIButton) {
        if let flightsVC = self.selectedViewController as? FlightsTableViewController {
            if flightsVC.menuVC != nil {
                // hide menu if it is already being displayed
                
                flightsVC.slideMenuItemSelected("")
                
                let settingsMenuView : UIView = flightsVC.view.subviews.last!
                
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    var frameMenu : CGRect = settingsMenuView.frame
                    frameMenu.origin.x = -1 * UIScreen.main.bounds.size.width
                    settingsMenuView.frame = frameMenu
                    settingsMenuView.layoutIfNeeded()
                    settingsMenuView.backgroundColor = UIColor.clear
                }, completion: { (finished) -> Void in
                    settingsMenuView.removeFromSuperview()
                })
                flightsVC.menuVC = nil
                flightsVC.menuBlurEffectView?.removeFromSuperview()
                flightsVC.menuBlurEffectView = nil
                if (flightsVC.optionsVC == nil) {
                    flightsVC.tableView.isScrollEnabled = true
                }
            } else {
                flightsVC.addBlurView(forMenu: true)
                flightsVC.tableView.isScrollEnabled = false
                flightsVC.menuVC = flightsVC.storyboard!.instantiateViewController(withIdentifier: "MenuViewController") as? MenuViewController
                flightsVC.menuVC?.menuButton = sender
                flightsVC.menuVC?.delegate = flightsVC
                flightsVC.view.addSubview((flightsVC.menuVC?.view)!)
                flightsVC.addChildViewController(flightsVC.menuVC!)
                flightsVC.menuVC?.view.layoutIfNeeded()
                
                // make sure the menu appears at the correct y value within the table view
                // this value changes depending on how far the user has scrolled
                if flightsVC.view.bounds.minY > 0 {
                    flightsVC.menuVC?.view.frame=CGRect(x: -UIScreen.main.bounds.size.width, y: (flightsVC.navigationController?.navigationBar.bounds.height)!, width: UIScreen.main.bounds.size.width, height: flightsVC.view.bounds.maxY)
                } else if flightsVC.view.bounds.minY > -flightsVC.BOUNDS_OFFSET {
                    flightsVC.menuVC?.view.frame=CGRect(x: -UIScreen.main.bounds.size.width, y: flightsVC.view.bounds.minY + flightsVC.BOUNDS_OFFSET, width: UIScreen.main.bounds.size.width, height: flightsVC.view.bounds.maxY)
                } else {
                    flightsVC.menuVC?.view.frame=CGRect(x: -UIScreen.main.bounds.size.width, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
                }
                
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    if flightsVC.view.bounds.minY > 0 {
                        flightsVC.menuVC?.view.frame=CGRect(x: 0, y: (flightsVC.navigationController?.navigationBar.bounds.height)!, width: UIScreen.main.bounds.size.width, height: flightsVC.view.bounds.maxY)
                    } else if flightsVC.view.bounds.minY > -flightsVC.BOUNDS_OFFSET {
                        flightsVC.menuVC?.view.frame=CGRect(x: 0, y: flightsVC.view.bounds.minY + flightsVC.BOUNDS_OFFSET, width: UIScreen.main.bounds.size.width, height: flightsVC.view.bounds.maxY)
                    } else {
                        flightsVC.menuVC?.view.frame=CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
                    }
                }, completion:nil)
            }
        }
    }
=======
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
>>>>>>> ee4f028bf38cfb34a3d319ec9d338f155ebf99f7

}
