//
//  WelcomeScreenViewController.swift
//  Trackify
//
//  Created by Scott Buttinger on 1/25/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit
import AWSCore
import AWSDynamoDB
import AWSCognito
import CoreData
import SwiftSpinner

class WelcomeScreenViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - View Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAway()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        self.addSwipeGestureRecognizer()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.registerForKeyboardNotifications()
        self.mainScrollView.isScrollEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.passwordTextField.text = ""
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.unregisterFromKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SwiftSpinner.hide()
    }
    
    // MARK: - Variables
    
    fileprivate var activeField: UITextField?
    fileprivate var user: User? {
        didSet {
            DispatchQueue.main.async {
//                self.addUserToCoreData()
                self.performSegue(withIdentifier: Storyboard.SignInSegue , sender: self)
            }
        }
    }
    
    fileprivate var helpers = Helpers()
    
    // get managed object context from delegate
    var managedObjectContext: NSManagedObjectContext? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    
    // MARK: - UI Elements
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var mainScrollView: UIScrollView!
    
    // MARK: - Other Functions
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        if (emailTextField.text == "" || !isValidEmail(testStr: emailTextField.text!)) {
            displayAlert("Invalid Email Address", message: "Please enter a valid email address.")
        } else if (passwordTextField.text == "") {
            displayAlert("Missing Password", message: "Please enter a valid password.")
        } else {
            // query AWS DB for login credentials
            SwiftSpinner.show("Signing In")
            attemptLogin(email: emailTextField.text!, password: passwordTextField.text!)
        }
    }
    
    // allow user to swipe to sign up screen
    fileprivate func addSwipeGestureRecognizer() {
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeSegueToSignUp))
        swipe.direction = UISwipeGestureRecognizerDirection.left
        view.addGestureRecognizer(swipe)
    }
    
    func swipeSegueToSignUp() {
        performSegue(withIdentifier: Storyboard.WelcomeSwipeSegueIdentifier, sender: self)
    }
    
    fileprivate func registerForKeyboardNotifications() {
        // Add notifications for keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    fileprivate func unregisterFromKeyboardNotifications() {
        // Remove notifications for keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // called anytime the keyboard appears on screen
    func keyboardWasShown(notification: NSNotification) {
        keyboardWasShownHelper(notification: notification, scrollView: mainScrollView, activeField: activeField)
    }
    
    // called when the keyboard is about to be removed from the screen
    func keyboardWillBeHidden(notification: NSNotification) {
        keyboardWillBeHiddenHelper(notification: notification, scrollView: mainScrollView, activeField: activeField)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
    }
    
    // this function moves the cursor to the next text field upon hitting
    // return in the current text field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.restorationIdentifier == Storyboard.WelcomeEmailTextFieldIdentifier {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    // function to check if user exist with email password combination exist
    fileprivate func attemptLogin(email:String, password:String) {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
        updateMapperConfig.saveBehavior = .updateSkipNullAttributes
        
        let sema = DispatchSemaphore(value: 0)
        dynamoDBObjectMapper.load(User.self, hashKey: email, rangeKey: nil).continueWith(block: { (task:AWSTask!) -> AnyObject! in
            if let error = task.error as? NSError {
                if (error.domain == NSURLErrorDomain) {
                    DispatchQueue.main.async {
                        self.displayAlert("Poor Network Connection", message: "Please try again.")
                    }
                }
            } else if let res = task.result as? User {
                if (res.email_id == email && res.password == password){
                    self.user = res
                } else {
                    DispatchQueue.main.async {
                        self.displayAlert("Invalid Password", message: "Please try again.")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.displayAlert("Invalid Email", message: "No account associated with email address.")
                }
            }
            DispatchQueue.main.async {
                SwiftSpinner.hide()
            }
            sema.signal()
            return nil
        })
        sema.wait()
    }
    
    // this function clears out any currently signed in user info and adds the new users
    // so that if they leave the app and reopen it, they remain signed in
    fileprivate func addUserToCoreData() {
        managedObjectContext?.perform {
            SavedUser.addSignedInUser((self.user?.email_id)!, firstName: (self.user?.first_name)!, lastName: (self.user?.last_name)!, password: (self.user?.password)!, inManagedObjectContext: self.managedObjectContext!)
            do {
                try self.managedObjectContext?.save()
            } catch let error {
                print("error saving signed in user: \(error)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboard.SignInSegue {
            if let destinationVC = segue.destination as? FlightTabBarController {
                for vc in (destinationVC.viewControllers)! {
                    if let flightTVC = vc as? FlightsTableViewController {
                        flightTVC.user = user
                    }
                }
            }
        }
    }
}
