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
import SwiftSpinner

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - View Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAway()
        self.setTextFieldDelegates()
        self.addSwipeGestureRecognizer()
        
        if editableUser != nil {
            setUpNavigationBar()
            self.backButton.isHidden = true
            self.emailTextField.text = editableUser?.email_id
            self.firstNameTextField.text = editableUser?.first_name
            self.lastNameTextField.text = editableUser?.last_name
            self.titleLabel.text = "Update Account"
            self.emailTextField.isUserInteractionEnabled = false
            self.signUpButton.setTitle("Save", for: .normal)
        }
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SwiftSpinner.hide()
    }
    
    // MARK: - Variables
    
    var delegate: UpdateUserDelegate?
    
    fileprivate var activeField: UITextField?
    
    fileprivate var newUser: User? {
        didSet {
            DispatchQueue.main.async {
                self.addUserToCoreData()
                if self.editableUser == nil {
                    self.performSegue(withIdentifier: Storyboard.NewUserSignInSegue , sender: self)
                } else {
                    self.delegate?.updateUser(newUser: self.newUser!)
                    self.navigationController!.popViewController(animated: true)
                }
                
            }
        }
    }
    
    // get managed object context from delegate
    var managedObjectContext: NSManagedObjectContext? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    
    var editableUser: User?
    
    var removeUserFromCoreData: () -> Void = {_ in }
    
    // MARK: - UI Elements
    
    @IBOutlet weak var firstNameTextField: UITextField!
    
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var confirmTextField: UITextField!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var logoImageView: UIImageView!
    
    // MARK: - Other Functions
    
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
        } else if (editableUser == nil && userWithEmailExists(emailTextField.text!)) {
            displayAlert("Invalid Email Address", message: "User with email address already exists.")
        } else if (passwordTextField.text == "") {
            displayAlert("Missing Password", message: "Please enter a valid password.")
        } else if (confirmTextField.text == "") {
            displayAlert("Missing Password Confirmation", message: "Please confirm your password.")
        } else if (passwordTextField.text! != confirmTextField.text!) {
            displayAlert("Password Mismatch", message: "Please confirm your password.")
            confirmTextField.text = ""
        } else if editableUser != nil {
            // updating user
            SwiftSpinner.show("Updating Account")
            removeUserFromCoreData()
            addUserToDB()
            
        } else {
            // adding new user
            // push data to AWS and sign in
            SwiftSpinner.show("Creating Account")
            addUserToDB();
        }
    }
    
    fileprivate func addUserToDB() {
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
                if (error.domain == NSURLErrorDomain) {
                    DispatchQueue.main.async {
                        SwiftSpinner.hide()
                        self.displayAlert("Poor Network Connection", message: "Please try again.")
                    }
                }
            } else {
                // success!
                self.newUser = user
            }
            return nil
        })
    }
    
    fileprivate func userWithEmailExists(_ email:String) -> Bool {
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
    
    // this function clears out any currently signed in user info and adds the new users
    // so that if they leave the app and reopen it, they remain signed in
    fileprivate func addUserToCoreData() {
        managedObjectContext?.perform {
            SavedUser.addSignedInUser((self.newUser?.email_id)!, firstName: (self.newUser?.first_name)!, lastName: (self.newUser?.last_name)!, password: (self.newUser?.password)!, inManagedObjectContext: self.managedObjectContext!)
            do {
                try self.managedObjectContext?.save()
            } catch let error {
                print("error saving signed in user: \(error)")
            }
        }
    }
    
    // allow user to swipe back to welcome screen
    fileprivate func addSwipeGestureRecognizer() {
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeSegueToWelcomeScreen))
        swipe.direction = UISwipeGestureRecognizerDirection.right
        view.addGestureRecognizer(swipe)
    }
    
    func swipeSegueToWelcomeScreen() {
        self.navigationController!.popViewController(animated: true)
    }
    
    // set this class as the delegate for all user input text fields
    fileprivate func setTextFieldDelegates() {
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmTextField.delegate = self
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
        switch (textField) {
        case firstNameTextField: lastNameTextField.becomeFirstResponder()
        case lastNameTextField: if editableUser == nil { emailTextField.becomeFirstResponder() }
        else { passwordTextField.becomeFirstResponder() }
        case emailTextField: passwordTextField.becomeFirstResponder()
        case passwordTextField: confirmTextField.becomeFirstResponder()
        default: textField.resignFirstResponder()
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboard.NewUserSignInSegue {
            if let destinationVC = segue.destination as? FlightsTableViewController {
                destinationVC.user = newUser
            }
        }
    }
}

protocol UpdateUserDelegate {
    func updateUser(newUser: User)
}
