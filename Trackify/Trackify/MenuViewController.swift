//
//  MenuViewController.swift
//  Trackify
//
//  Created by Scott Buttinger on 2/12/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit

protocol SlideMenuDelegate {
    func slideMenuItemSelected(_ option: String)
}

class MenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    /**
    *  Array to display menu options
    */
    @IBOutlet var menuTable : UITableView!
    
    /**
    *  Transparent button to hide menu
    */
    @IBOutlet var transparentSideButton : UIButton!
    
    /**
    *  Arrays containing menu options and images
    */
    var menuOptions = ["Account", "Sign Out", "Cancel"]
    
    var menuImages = [#imageLiteral(resourceName: "user_icon_blue"), #imageLiteral(resourceName: "exit_icon_blue"), #imageLiteral(resourceName: "delete_blue_icon")]
    
    /**
    *  Menu button which was tapped to display the menu
    */
    var menuButton : UIButton!
    
    /**
    *  Delegate of the MenuVC
    */
    var delegate : SlideMenuDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuTable.tableFooterView = UIView()
        
        self.menuTable.backgroundColor = UIColor.clear
    }
    
    @IBAction func onCloseMenuClick(_ button:UIButton!) {
        menuButton.tag = 0
        
        if (self.delegate != nil) {
            var option = menuOptions[Int(button.tag)]
            if(button == self.transparentSideButton){
                option = ""
            }
            delegate?.slideMenuItemSelected(option)
        }
        
        let delegateVC = delegate as? FlightsTableViewController
        delegateVC?.menuVC = nil
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            
            if (delegateVC?.view.bounds.minY)! > 0 {
                self.view.frame=CGRect(x: -UIScreen.main.bounds.size.width, y: (delegateVC?.navigationController?.navigationBar.bounds.height)!, width: UIScreen.main.bounds.size.width, height: (delegateVC?.view.bounds.maxY)!)
            } else if self.view.bounds.minY > -(delegateVC?.BOUNDS_OFFSET)! {
                self.view.frame=CGRect(x: -UIScreen.main.bounds.size.width, y: (delegateVC?.view.bounds.minY)! + (delegateVC?.BOUNDS_OFFSET)!, width: UIScreen.main.bounds.size.width, height: (delegateVC?.view.bounds.maxY)!)
            } else {
                self.view.frame=CGRect(x: -UIScreen.main.bounds.size.width, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
            }
            self.view.layoutIfNeeded()
            self.view.backgroundColor = UIColor.clear
            }, completion: { (finished) -> Void in
                self.view.removeFromSuperview()
                self.removeFromParentViewController()
        })
        
        delegateVC?.menuBlurEffectView?.removeFromSuperview()
        delegateVC?.menuBlurEffectView = nil
        if delegateVC?.optionsVC == nil {
           delegateVC?.tableView.isScrollEnabled = true
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cellMenu")!
        
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.backgroundColor = UIColor.clear
        
        let optionLabel : UILabel = cell.contentView.viewWithTag(101) as! UILabel
        let iconImageView : UIImageView = cell.contentView.viewWithTag(100) as! UIImageView
        
        iconImageView.image = menuImages[indexPath.row]
        optionLabel.text = menuOptions[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let button = UIButton(type: UIButtonType.custom)
        button.tag = indexPath.row
        self.onCloseMenuClick(button)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuOptions.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIScreen.main.bounds.size.height/6
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}
