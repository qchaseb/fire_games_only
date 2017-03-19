//
//  FlightPDFViewController.swift
//  Trackify
//
//  Created by Ted Ganting Lim on 3/18/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import AWSS3
import Foundation
import UIKit
import SwiftSpinner
import WebKit

class FlightPDFViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var pdfView: UIWebView!
    var flight: Flight?
    let transferManager = AWSS3TransferManager.default()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationBar()
        pdfView.delegate = self
        self.automaticallyAdjustsScrollViewInsets = false

        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SwiftSpinner.show("Loading Ticket")
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        SwiftSpinner.hide()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        SwiftSpinner.hide()
        self.displayAlert("Poor Network Connection", message: "Couldn't load ticket. Please try again.")
    }
    
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

    override func viewDidAppear(_ animated: Bool) {
        
        let downloadingFileURL2 = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Cracking the Coding Interview, 4 Edition - 150 Programming Interview Questions and Solutions.pdf")
        
        let downloadRequest2 = AWSS3TransferManagerDownloadRequest()
        downloadRequest2?.bucket = "trackifypdfs"
        downloadRequest2?.key = "Cracking the Coding Interview, 4 Edition - 150 Programming Interview Questions and Solutions.pdf"
        downloadRequest2?.downloadingFileURL = downloadingFileURL2
        transferManager.download(downloadRequest2!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
            
            if let error = task.error as? NSError {
                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                    switch code {
                    case .cancelled, .paused:
                        break
                    default:
                        print("Error downloading: \(downloadRequest2?.key) Error: \(error)")
                    }
                } else {
                    print("Error downloading: \(downloadRequest2?.key) Error: \(error)")
                }
                return nil
            } else {
                self.pdfView.loadRequest(URLRequest(url: downloadingFileURL2))
            }
            return nil
        })
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
