//
//  Helpers.swift
//  Trackify
//
//  Created by Scott Buttinger on 1/25/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

// A file that is created to hold miscellaneous helper variables, extensions, or protocols

import Foundation
import UIKit

class Helpers {
    // helper variables here
    let themeColor = UIColor(red: 0/255, green: 80/255, blue:255/255, alpha: 1)
}

extension UIViewController {
    
    // This will hide the keyboard whenever the user taps outside of a text field
    func hideKeyboardWhenTappedAway() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    // this function will manually dismiss the keyboard when called
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func keyboardWasShownHelper(notification: NSNotification, scrollView: UIScrollView?, activeField: UITextField?){
        // Need to calculate keyboard exact size due to Apple suggestions
        scrollView?.isScrollEnabled = true
        var info = notification.userInfo!
        // add 10 for slight buffer between text field and keyboard
        var keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        keyboardSize?.height += CGFloat(10)
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height, 0.0)
        
        scrollView?.contentInset = contentInsets
        scrollView?.scrollIndicatorInsets = contentInsets
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        if activeField != nil {
            if (!aRect.contains(activeField!.frame.origin)){
                scrollView?.scrollRectToVisible(activeField!.frame, animated: true)
            }
        }
    }
    
    func keyboardWillBeHiddenHelper(notification: NSNotification, scrollView: UIScrollView?, activeField: UITextField?){
        // Once keyboard disappears, restore original positions
        var info = notification.userInfo!
        var keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        // add 10 for slight buffer between text field and keyboard
        keyboardSize?.height += CGFloat(10)
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, -keyboardSize!.height, 0.0)
        scrollView?.contentInset = contentInsets
        scrollView?.scrollIndicatorInsets = contentInsets
        self.view.endEditing(true)
        scrollView?.isScrollEnabled = false
    }
    
    // call this function when the user tries to submit a form without providing all required info
    func displayAlert(_ title: String, message: String){
        let alertVC = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: "OK",
            style:.default,
            handler: nil)
        alertVC.addAction(okAction)
        present(alertVC,
                animated: true,
                completion: nil)
    }
    
    // this function checks a string to see if it conforms to email address formatting
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    // this function sets up the attributes for the spinner and
    // adds it to the display
    func startSpinner(_ spinner: inout UIActivityIndicatorView) {
        spinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        spinner.center = self.view.center
        spinner.hidesWhenStopped = true
        spinner.backgroundColor = UIColor(red: 0/255, green: 0/255, blue:0/255, alpha: 0.75)
        spinner.layer.cornerRadius = 10
        self.view.addSubview(spinner)
        spinner.bringSubview(toFront: self.view)
        spinner.startAnimating()
    }
    
}

// String constants that are used in the storyboard
struct Storyboard {
    static let WelcomeEmailTextFieldIdentifier = "emailTextField"
    static let WelcomeSwipeSegueIdentifier = "swipeToSignUp"
    static let SignInSegue = "signInSegue"
    static let NewUserSignInSegue = "newUserSignInSegue"
    static let FlightCell = "flightCell"
    static let ManualEntrySegue = "manualEntrySegue"
}

