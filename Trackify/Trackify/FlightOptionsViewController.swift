//
//  FlightOptionsViewController.swift
//  Trackify
//
//  Created by Scott Buttinger on 2/25/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit

class FlightOptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
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
    var menuOptions = ["Flight", "Edit", "Status", "Add to Calendar", "Share", "Export", "Cancel"]
    
    var menuImages = [nil, #imageLiteral(resourceName: "edit_icon_blue"), #imageLiteral(resourceName: "status_blue_icon"),#imageLiteral(resourceName: "calendar_blue"), #imageLiteral(resourceName: "share_icon_blue"), #imageLiteral(resourceName: "export_icon_blue"), #imageLiteral(resourceName: "delete_blue_icon")]
    
    var flight: Flight?
    
    /**
     *  Delegate of the MenuVC
     */
    var delegate : SlideMenuDelegate?
    
    fileprivate var flightCellHeight: CGFloat?
    fileprivate var menuCellHeight: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuTable.tableFooterView = UIView()
        
        self.menuTable.backgroundColor = UIColor.clear
    }
    
    @IBAction func onCloseMenuClick(_ button:UIButton!) {
        if (self.delegate != nil) {
            var option = menuOptions[Int(button.tag)]
            if(button == self.transparentSideButton){
                option = ""
            }
            delegate?.slideMenuItemSelected(option)
        }
        
        let delegateVC = delegate as? FlightsTableViewController
        delegateVC?.optionsVC = nil
        delegateVC?.tableView.isScrollEnabled = true
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.view.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height, width: UIScreen.main.bounds.size.width,height: UIScreen.main.bounds.size.height)
            self.view.layoutIfNeeded()
            self.view.backgroundColor = UIColor.clear
        }, completion: { (finished) -> Void in
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        })
        
        delegateVC?.optionsBlurEffectView?.removeFromSuperview()
        delegateVC?.optionsBlurEffectView = nil
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        if indexPath.row == 0 {
            if let flightCell = tableView.dequeueReusableCell(withIdentifier: Storyboard.FlightCell, for: indexPath) as? FlightTableViewCell {
                flightCell.flight = flight!
                cell = flightCell
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "cellMenu")!
            let optionLabel : UILabel = cell!.contentView.viewWithTag(101) as! UILabel
            let iconImageView : UIImageView = cell!.contentView.viewWithTag(100) as! UIImageView
            
            iconImageView.image = menuImages[indexPath.row]
            optionLabel.text = menuOptions[indexPath.row]
        }
        
        
        
        cell!.selectionStyle = UITableViewCellSelectionStyle.none
        cell!.layoutMargins = UIEdgeInsets.zero
        cell!.preservesSuperviewLayoutMargins = false
        cell!.backgroundColor = UIColor.clear
        
        return cell!
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
        if indexPath.row == 0 {
            return UIScreen.main.bounds.size.height/4.35
        }
        return UIScreen.main.bounds.size.height/10
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
}
