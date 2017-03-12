//
//  ManualEntryViewController.swift
//  Trackify
//
//  Created by Scott Buttinger on 2/7/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit
import AWSDynamoDB
import UserNotifications
import SwiftSpinner

class ManualEntryViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    fileprivate var helpers = Helpers()
    fileprivate let airlines = ["Air Canada", "Alaska", "Allegiant", "American", "Delta", "Frontier", "Hawaiian", "JetBlue", "Southwest", "Spirit", "Sun Country", "United", "Virgin America"]
    fileprivate var activeField: UITextField?
    fileprivate let df = DateFormatter()
    
    fileprivate var success: Bool = false {
        didSet {
            if (editFlight != nil) {
                removeFlightFromCoreData((editFlight?.datetime)!)
            }
            DispatchQueue.main.async {
                self.navigationController!.popViewController(animated: true)
            }
        }
    }
    
    fileprivate var deleteSuccess: Bool = false {
        didSet {
            addFlightToDB()
        }
    }
    
    var editFlight: Flight?
    
    var userEmail: String?
    
    var removeFlightFromCoreData: (_ dateTime: String) -> Void = {_ in }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAway()
        self.scrollView.isScrollEnabled = false
        self.airlinePicker.dataSource = self
        self.airlinePicker.delegate = self
        self.flightNumberTextField.delegate = self
        self.departureTextField.delegate = self
        self.arrivalTextField.delegate = self
        self.confirmationTextField.delegate = self
        
        if (editFlight != nil) {
            let row = airlines.index(of: (editFlight?.airline)!)
            airlinePicker.selectRow(row!, inComponent: 0, animated: true)
            flightNumberTextField.text = editFlight?.flightNumber
            departureTextField.text = editFlight?.departureAirport
            arrivalTextField.text = editFlight?.destinationAirport
            confirmationTextField.text = editFlight?.confirmation
            datePicker.date = (editFlight?.getDate())!
            timePicker.date = (editFlight?.getDate())!
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpNavigationBar()
        if (editFlight != nil) {
            titleLabel.text = "Update Flight"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.registerForKeyboardNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.unregisterFromKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SwiftSpinner.hide()
    }
    
    @IBOutlet weak var departureTextField: UITextField!
    @IBOutlet weak var arrivalTextField: UITextField!
    @IBOutlet weak var confirmationTextField: UITextField!
    @IBOutlet weak var airlinePicker: UIPickerView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var flightNumberTextField: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    
    // Set up the UI for the navigation bar
    fileprivate func setUpNavigationBar() {
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.barTintColor = helpers.themeColor
        
        // set up title image
        let logo = #imageLiteral(resourceName: "trackify_white_title")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x:0, y:0, width:50, height:50)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView
        
        // set up settings button
        let cancelButton = UIBarButtonItem()
        cancelButton.image = #imageLiteral(resourceName: "delete_white_icon")
        cancelButton.tintColor = UIColor.white
        cancelButton.customView?.contentMode = .scaleAspectFit
        cancelButton.target = self
        cancelButton.action = #selector(self.cancelButtonTapped)
        self.navigationItem.leftBarButtonItem = cancelButton
        
        // set up manual entry button
        let doneButton = UIBarButtonItem()
        doneButton.image = #imageLiteral(resourceName: "check_white_icon")
        doneButton.tintColor = UIColor.white
        doneButton.customView?.contentMode = .scaleAspectFit
        doneButton.target = self
        doneButton.action = #selector(self.doneButtonTapped)
        self.navigationItem.rightBarButtonItem = doneButton
        
        // set time and battery logos to be white
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    func cancelButtonTapped() {
        self.navigationController!.popViewController(animated: true)
    }
    
    fileprivate func dateIsBeforeToday(date: Date) -> Bool {
        let today = Date()
        
        df.dateFormat = "yyyy-MM-dd"
        let dateString = df.string(from: date)
        let todayString = df.string(from: today)
        return dateString < todayString
    }
    
    func doneButtonTapped() {
        if flightNumberTextField.text == "" {
            displayAlert("Invalid Flight Number", message: "Please enter a valid flight number.")
        } else if dateIsBeforeToday(date: datePicker.date) {
            displayAlert("Past Date Entered", message: "Please enter a future date.")
        } else if departureTextField.text == "" {
            displayAlert("Invalid Departure Airport Code", message: "Please enter a valid departure airport code.")
        } else if arrivalTextField.text == "" {
            displayAlert("Invalid Arrival Airport Code", message: "Please enter a valid arrival airport code.")
        } else if confirmationTextField.text == "" {
            displayAlert("Invalid Confirmation Code", message: "Please enter a valid confirmation code.")
        } else if editFlight != nil {
            removeNotificationsFromNotificationCenter(flight: editFlight!)
            SwiftSpinner.show("Updating Flight")
            if self.getDateTimeString() != editFlight?.datetime {
                removeFlightFromDB()
            } else {
                addFlightToDB()
            }
        } else if flightExists() {
            displayAlert("Duplicate Flight", message: "This flight has already been added to the database.")
        } else {
            // Push flight to DynamoDB
            SwiftSpinner.show("Adding New Flight")
            addFlightToDB()
        }
    }
    
    func removeNotificationsFromNotificationCenter(flight: Flight) {
        if(flight.identifiers == nil){
            return
        } else {
            for id in flight.identifiers! {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            }
        }
    }

    fileprivate func getDateTimeString() -> String? {
        df.dateFormat = "HH:mm"
        let timeString = df.string(from: timePicker.date)
        df.dateFormat = "MM-dd-yyyy"
        let dateString = df.string(from: datePicker.date)
        return dateString + " " + timeString
    }
    
    fileprivate func removeFlightFromDB() {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
        updateMapperConfig.saveBehavior = .updateSkipNullAttributes
        let sema = DispatchSemaphore(value: 0)
        dynamoDBObjectMapper.remove(editFlight!).continueWith(block: {(task:AWSTask!) -> AnyObject! in
            if let error = task.error as? NSError {
                print("Remove failed. Error: \(error)")
                if (error.domain == NSURLErrorDomain) {
                    DispatchQueue.main.async {
                        SwiftSpinner.hide()
                        self.displayAlert("Poor Network Connection", message: "Couldn't update flight. Please try again.")
                    }
                }
            } else {
                // success!
                self.deleteSuccess = true
            }
            sema.signal()
            return nil
        })
        sema.wait()
    }
    
    fileprivate func addFlightToDB() {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let flight = Flight()
        flight?.airline = airlines[airlinePicker.selectedRow(inComponent: 0)]
        flight?.flightNumber = flightNumberTextField.text
        flight?.datetime = self.getDateTimeString()
        flight?.email = userEmail
        flight?.departureAirport = departureTextField.text
        flight?.destinationAirport = arrivalTextField.text
        flight?.confirmation = confirmationTextField.text
        
        // Handles 
        if editFlight != nil {
            flight?.identifiers = editFlight?.identifiers
            flight?.sharedWith = editFlight?.sharedWith
        }
        
        let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
        updateMapperConfig.saveBehavior = .updateSkipNullAttributes
        
        dynamoDBObjectMapper.save(flight!).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as? NSError {
                if (error.domain == NSURLErrorDomain) {
                    DispatchQueue.main.async {
                        SwiftSpinner.hide()
                        self.displayAlert("Poor Network Connection", message: "Please try again.")
                    }
                }
            } else {
                // success!
                self.success = true
            }
            return nil
        })
    }
    
    // gets all the flights assosiated with a given user and returns them in an array of flight objects
    // returns flights in order of date.
    fileprivate func flightExists() -> Bool {
        let dateTime = getDateTimeString()
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
        updateMapperConfig.saveBehavior = .updateSkipNullAttributes
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "email = :id"
        scanExpression.expressionAttributeValues = [":id": userEmail ?? ""]
        
        var flightExists = false
        
        let sema = DispatchSemaphore(value: 0)
        dynamoDBObjectMapper.scan(Flight.self, expression: scanExpression)
            .continueWith(block: {(task:AWSTask!) -> AnyObject! in
                if let error = task.error as? NSError {
                    if (error.domain == NSURLErrorDomain) {
                        print("The request failed. Error: \(error)")
                    }
                } else if let dbResults = task.result {
                    for flight in dbResults.items as! [Flight] {
                        if flight.datetime == dateTime {
                            flightExists = true
                            break
                        }
                    }
                }
                sema.signal()
                return nil
            })
        
        sema.wait()
        return flightExists
    }
    
    // MARK: - Text Field movement functions
    
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
        if textField == departureTextField {
            arrivalTextField.becomeFirstResponder()
        } else if textField == arrivalTextField {
            confirmationTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // This function limits the number of characters allowed in certain text fields
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var validTextField = false
        var maxChars = 0
        
        if textField == departureTextField || textField == arrivalTextField {
            validTextField = true
            maxChars = 3
        } else if textField == flightNumberTextField {
            validTextField = true
            maxChars = 5
        }
        
        if validTextField {
            let currentString: NSString = textField.text! as NSString
            let newString: NSString =
                currentString.replacingCharacters(in: range, with: string) as NSString
            return newString.length <= maxChars
        }
        return true
    }
    
    // MARK: - Picker View delegates and data source functions
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return airlines.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return airlines[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        let titleData = airlines[row]
        let myTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:UIFont.preferredFont(forTextStyle: UIFontTextStyle.title2),NSForegroundColorAttributeName:UIColor.black])
        pickerLabel.attributedText = myTitle
        pickerLabel.textAlignment = .center
        return pickerLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 36.0
    }
}
