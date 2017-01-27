//
//  WelcomeScreenViewController.swift
//  Trackify
//
//  Created by Scott Buttinger on 1/25/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit

class WelcomeScreenViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAway()
        emailTextField.delegate = self
        passwordTextField.delegate = self

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.registerForKeyboardNotifications()
        self.mainScrollView.isScrollEnabled = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.unregisterFromKeyboardNotifications()
    }
    
    // MARK: - Variables
    
    var activeField: UITextField?
    
    // MARK: - UI Elements
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!

    @IBOutlet weak var mainScrollView: UIScrollView!
    
    // MARK: - Other Functions
    
    func registerForKeyboardNotifications(){
        // Add notifications for keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func unregisterFromKeyboardNotifications(){
        // Remove notifications for keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // called anytime the keyboard appears on screen
    func keyboardWasShown(notification: NSNotification){
        keyboardWasShownHelper(notification: notification, scrollView: mainScrollView, activeField: activeField)
    }
    
    // called when the keyboard is about to be removed from the screen
    func keyboardWillBeHidden(notification: NSNotification){
        keyboardWillBeHiddenHelper(notification: notification, scrollView: mainScrollView, activeField: activeField)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField){
        activeField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        activeField = nil
    }
    
     // this function moves the cursor to the next text field upon hitting
     // return in the current text field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.restorationIdentifier == "emailTextField" {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
