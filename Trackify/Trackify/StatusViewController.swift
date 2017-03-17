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
        self.automaticallyAdjustsScrollViewInsets = false

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
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        SwiftSpinner.hide()
        self.displayAlert("Poor Network Connection", message: "Couldn't load flight status. Please try again.")
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
        case "Southwest Airlines": return "SWA"
        case "Delta": return "DAL"
        case "Delta Airlines": return "DAL"
        case "United": return "UAL"
        case "United Airlines": return "UAL"
        case "American": return "AAL"
        case "American Airlines": return "AAL"
        case "Virgin America": return "VRD"
        case "Air Canada": return "ACA"
        case "Alaska": return "ASA"
        case "Alaska Airlines": return "ASA"
        case "Spirit": return "NKS"
        case "Spirit Airlines": return "NKS"
        case "Frontier": return "FFT"
        case "Frontier Airlines": return "FFT"
        case "JetBlue": return "JBU"
        case "JetBlue Airways": return "JBU"
        case "Allegiant": return "AAY"
        case "Allegiant Travel Company": return "AAY"
        case "Sun Country": return "SCX"
        case "Sun Country Airlines": return "SCX"
        case "Hawaiian": return "HAL"
        case "Hawaiian Airlines": return "HAL"
        default: return ""
        }
    }

}
