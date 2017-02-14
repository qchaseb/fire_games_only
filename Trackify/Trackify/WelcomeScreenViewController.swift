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
        self.navigationController?.navigationBar.isHidden = true
        self.passwordTextField.text = ""
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.unregisterFromKeyboardNotifications()
    }
    
    // MARK: - Variables
    
    fileprivate var activeField: UITextField?
    fileprivate var user :User? {
        didSet {
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                self.performSegue(withIdentifier: Storyboard.SignInSegue , sender: self)
            }
        }
    }
    
    // MARK: - UI Elements
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var mainScrollView: UIScrollView!
    
    // a subview that will be added to our current view with a
    // spinner, indicating we are attempting to retrieve data from AWS
    fileprivate var spinner = UIActivityIndicatorView()
    
    // MARK: - Other Functions
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        startSpinner(&spinner)
        if (emailTextField.text == "" || !isValidEmail(testStr: emailTextField.text!)) {
            displayAlert("Invalid Email Address", message: "Please enter a valid email address.")
            spinner.stopAnimating()
        } else if (passwordTextField.text == "") {
            displayAlert("Missing Password", message: "Please enter a valid password.")
            spinner.stopAnimating()
        } else {
            // query AWS DB for login credentials
//            startSpinner(&spinner)
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
                self.spinner.stopAnimating()
            }
            sema.signal()
            return nil
        })
        sema.wait()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.spinner.stopAnimating()
        if segue.identifier == Storyboard.SignInSegue {
            if let destinationVC = segue.destination as? FlightsTableViewController {
                destinationVC.user = user
            }
        }
    }
}
