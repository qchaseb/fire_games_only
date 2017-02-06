//
//  SignUpViewController.swift
//  Trackify
//
//  Created by Scott Buttinger on 1/26/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit
import AWSCore
import AWSDynamoDB
import AWSCognito

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - View Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAway()
        self.setTextFieldDelegates()
        self.addSwipeGestureRecognizer()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.registerForKeyboardNotifications()
        self.scrollView.isScrollEnabled = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.unregisterFromKeyboardNotifications()
    }
    
    // MARK: - Variables
    
    var activeField: UITextField?
    
    // MARK: - UI Elements
    
    @IBOutlet weak var firstNameTextField: UITextField!
    
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var confirmTextField: UITextField!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    // MARK: - Other Functions
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func signUpButtonTapped(_ sender: Any) {
        if (firstNameTextField.text == "") {
            displayAlert("Missing First Name", message: "Please enter your first name.")
        } else if (lastNameTextField.text == "") {
            displayAlert("Missing Last Name", message: "Please enter your last name.")
        } else if (emailTextField.text == "" || !isValidEmail(testStr: emailTextField.text!)) {
            displayAlert("Invalid Email Address", message: "Please enter a valid email address.")
        } else if (userWithEmailExists(emailTextField.text!)) {
            displayAlert("Invalid Email Address", message: "User with email address already exists.")
        } else if (passwordTextField.text == "") {
            displayAlert("Missing Password", message: "Please enter a valid password.")
        } else if (confirmTextField.text == "") {
            displayAlert("Missing Password Confirmation", message: "Please confirm your password.")
        } else if (passwordTextField.text! != confirmTextField.text!) {
            displayAlert("Password Mismatch", message: "Please confirm your password.")
            confirmTextField.text = ""
        } else {
            addUserToDB();
        }
        
        // push data to AWS and sign in
    }
    
    func addUserToDB() {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let user = User()
        user?.email_id = emailTextField.text
        user?.password = passwordTextField.text
        user?.first_name = firstNameTextField.text
        user?.last_name = lastNameTextField.text
        let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
        updateMapperConfig.saveBehavior = .updateSkipNullAttributes
        
        dynamoDBObjectMapper.save(user!).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as? NSError {
                print("The request failed. Error: \(error)")
            } else {
                print("this is result: \(task.result)")
                // Do something with task.result or perform other operations.
            }
            return nil
        })
    }
    
    func userWithEmailExists(_ email:String) -> Bool {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
        updateMapperConfig.saveBehavior = .updateSkipNullAttributes
        
        var userExists = false;
        // semaphore to waits until load call completes
        let sema = DispatchSemaphore(value: 0)
        dynamoDBObjectMapper.load(User.self, hashKey: email, rangeKey: nil).continueWith(block: { (task:AWSTask!) -> AnyObject! in
            if let error = task.error as? NSError {
                print("The request failed. Error: \(error)")
            } else if (task.result as? User) != nil {
                userExists = true
            }
            sema.signal()
            return nil
        })
        sema.wait()
        return userExists
    }
    
    // allow user to swipe back to welcome screen
    func addSwipeGestureRecognizer() {
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeSegueToWelcomeScreen))
        swipe.direction = UISwipeGestureRecognizerDirection.right
        view.addGestureRecognizer(swipe)
    }
    
    func swipeSegueToWelcomeScreen() {
        self.navigationController!.popViewController(animated: true)
    }
    
    // set this class as the delegate for all user input text fields
    func setTextFieldDelegates() {
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmTextField.delegate = self
    }
    
    func registerForKeyboardNotifications() {
        // Add notifications for keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func unregisterFromKeyboardNotifications() {
        // Remove notifications for keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // called anytime the keyboard appears on screen
    func keyboardWasShown(notification: NSNotification) {
        keyboardWasShownHelper(notification: notification, scrollView: scrollView, activeField: activeField)
    }
    
    // called when the keyboard is about to be removed from the screen
    func keyboardWillBeHidden(notification: NSNotification) {
        keyboardWillBeHiddenHelper(notification: notification, scrollView: scrollView, activeField: activeField)
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
        switch (textField){
        case firstNameTextField: lastNameTextField.becomeFirstResponder()
        case lastNameTextField: emailTextField.becomeFirstResponder()
        case emailTextField: passwordTextField.becomeFirstResponder()
        case passwordTextField: confirmTextField.becomeFirstResponder()
        default: textField.resignFirstResponder()
        }
        return true
    }
}
