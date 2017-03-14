//
//  StatusViewController.swift
//  Trackify
//
//  Created by Scott Buttinger on 3/13/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit
import SwiftSpinner

class StatusViewController: UIViewController, UIWebViewDelegate {
    
    
    @IBOutlet weak var statusWebView: UIWebView!
    var flight: Flight?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationBar()
        statusWebView.delegate = self

        let URLstr = "https://flightaware.com/live/flight/" + getAirlineUrlParam((flight?.airline!)!) + (flight?.flightNumber!)!
        
        // load web site into web view
        let statusURL = URL(string: URLstr)
        let statusURLRequest:URLRequest = URLRequest(url: statusURL!)
        statusWebView.loadRequest(statusURLRequest)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SwiftSpinner.show("Loading Flight Status")
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        SwiftSpinner.hide()
    }
    
    // Set up the UI for the navigation bar
    fileprivate func setUpNavigationBar() {
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        // set time and battery logos to be white
        UIApplication.shared.statusBarStyle = .lightContent
        
        // set up title image
        let logo = #imageLiteral(resourceName: "trackify_white_title")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x:0, y:0, width:50, height:50)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView
    }

    // returns the Airline url param to get the flight status of a flight from flightstats.com
    // returns "" if an airline that the app doesn't support is passed in
    fileprivate func getAirlineUrlParam(_ airline:String) -> String {
        switch airline {
        case "Southwest": return "SWA"
        case "Delta": return "DAL"
        case "United": return "UAL"
        case "American": return "AAL"
        case "Virgin America": return "VRD"
        case "Air Canada": return "ACA"
        case "Alaska": return "ASA"
        case "Spirit": return "NKS"
        case "Frontier": return "FFT"
        case "JetBlue": return "JBU"
        case "Allegiant": return "AAY"
        case "Sun Country": return "SCX"
        case "Hawaiian": return "HAL"
        default: return ""
        }
    }

}
