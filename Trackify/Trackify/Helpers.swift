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

}

