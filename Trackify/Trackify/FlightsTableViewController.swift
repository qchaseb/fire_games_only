//
//  FlightsTableViewController.swift
//  Trackify
//
//  Created by Scott Buttinger on 2/6/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit
import AWSDynamoDB
import CoreData
import EventKit
import SwiftSpinner
import UserNotifications

class FlightsTableViewController: UITableViewController, SlideMenuDelegate, UpdateUserDelegate {
    
    // MARK: - Variables
    var user: User?
    fileprivate var initialFlights = true
    fileprivate let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
    
    var flights: [Flight]? {
        didSet {
            flights?.sort(by: { $0.getDate()! < $1.getDate()! })
            flights = flights?.filter({ $0.getDate()! > yesterday!})
            if (!initialFlights) {
                for flight in flights! {
                    addUpcomingFlightToCoreData(flight: flight)
                }
            }
            self.tableView.reloadData()
            self.refreshController?.endRefreshing()
        }
    }
    
    var pastFlights: [Flight]? {
        didSet {
            pastFlights?.sort(by: { $0.getDate()! < $1.getDate()! })
            pastFlights = pastFlights?.filter({ $0.getDate()! <= yesterday!})
            // Need to deal with core data
            if (!initialFlights) {
                for flight in pastFlights! {
                    addPastFlightToCoreData(flight: flight)
                }
            }
            self.tableView.reloadData()
            self.refreshController?.endRefreshing()
        }
    }
    
    var sharedFlights: [Flight]? {
        didSet {
            sharedFlights?.sort(by: { $0.getDate()! < $1.getDate()! })
            sharedFlights = sharedFlights?.filter({ $0.getDate()! > yesterday!})
            if (!initialFlights) {
                for flight in sharedFlights! {
                    addSharedFlightToCoreData(flight: flight)
                }
            }
            self.tableView.reloadData()
            self.refreshController?.endRefreshing()
        }
    }
    
    var menuVC: MenuViewController?
    var optionsVC: FlightOptionsViewController?
    let BOUNDS_OFFSET: CGFloat = 64
    
    //for sharing flights
    fileprivate var enterEmail: UIAlertController?
    fileprivate var selectedFlight:Flight?
    
    let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.regular)
    var optionsBlurEffectView: UIVisualEffectView?
    var menuBlurEffectView: UIVisualEffectView?
    
    var editingFlight: Bool = false
    
    // get managed object context from delegate
    var managedObjectContext: NSManagedObjectContext? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    
    fileprivate var refreshController: UIRefreshControl?
    fileprivate var helpers = Helpers()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialFlights = false
        self.refreshController = UIRefreshControl()
        self.refreshController?.addTarget(self, action: #selector(self.handleRefresh), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshController!)
        let tabBarHeight = self.tabBarController?.tabBar.bounds.height
        self.edgesForExtendedLayout = UIRectEdge.all
        self.tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: tabBarHeight!, right: 0.0)
        UNUserNotificationCenter.current().delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // query for flights for the logged in user
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        loadFlights(email: (user?.email_id)!, fromRefreshHandler: false)
        loadSharedFlights(email: (user?.email_id)!, fromRefreshHandler: false
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if currentFlightsArray()?.count == 0 {
            switch (self.tabBarItem.title!) {
            case "Upcoming" :
                displayAlert("No Upcoming Flights", message: "Forward your flight confirmation emails to flights@trackify.biz or manually enter a flight by touching the button above!")
            default :
                return
            }
        }
    }
    
    fileprivate func currentFlightsArray() ->[Flight]? {
        // for core data
        if self.tabBarItem.title == nil {
            return flights
        }
        switch (self.tabBarItem.title!) {
        case "Upcoming" :
            return flights
        case "Shared":
            print("returned shared flights")
            return sharedFlights
        default :
            return pastFlights
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentFlightsArray()?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        if let flightCell = tableView.dequeueReusableCell(withIdentifier: Storyboard.FlightCell, for: indexPath) as? FlightTableViewCell {
            flightCell.flight = currentFlightsArray()?[indexPath.row]
            cell = flightCell
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            if let flightCell = tableView.cellForRow(at: indexPath) as? FlightTableViewCell {
                var errorOccurred = false
                if (self.tabBarItem.title! == "Shared") {
                    if flightCell.flight!.sharedWith != nil  && (flightCell.flight!.sharedWith?.contains((user?.email_id)!))!{
                        flightCell.flight!.sharedWith!.remove((user?.email_id)!)
                        // can't have empty sets in dynamoDB
                        if flightCell.flight!.sharedWith!.count == 0 {
                            flightCell.flight!.sharedWith = nil
                        }
                        removeNotificationsFromNotificationCenter(flight: flightCell.flight!)
                        SwiftSpinner.show("Deleting Shared Flight")
                        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
                        let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
                        updateMapperConfig.saveBehavior = .updateSkipNullAttributes
                        let sema = DispatchSemaphore(value: 0)
                        
                        dynamoDBObjectMapper.save(flightCell.flight!).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
                            if let error = task.error as? NSError {
                                errorOccurred = true
                                if (error.domain == NSURLErrorDomain) {
                                    DispatchQueue.main.async {
                                        SwiftSpinner.hide()
                                        self.displayAlert("Poor Network Connection", message: "Please try again.")
                                    }
                                }
                            }
                            sema.signal()
                            return nil
                        })
                        sema.wait()
                        if (!errorOccurred) {
                            removeSharedFlightFromCoreData(datetime: (flightCell.flight?.datetime!)!)
                        }
                        SwiftSpinner.hide()
                        handleRefresh()
                    }
                    return
                }
                SwiftSpinner.show("Deleting Flight")
                let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
                let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
                updateMapperConfig.saveBehavior = .updateSkipNullAttributes
                let sema = DispatchSemaphore(value: 0)
                dynamoDBObjectMapper.remove(flightCell.flight!).continueWith(block: {(task:AWSTask!) -> AnyObject! in
                    if let error = task.error as? NSError {
                        errorOccurred = true
                        print("Remove failed. Error: \(error)")
                        if (error.domain == NSURLErrorDomain) {
                            DispatchQueue.main.async {
                                SwiftSpinner.hide()
                                self.displayAlert("Poor Network Connection", message: "Couldn't delete flight. Please try again.")
                            }
                        }
                    } else {
                        print("Item removed")
                    }
                    sema.signal()
                    return nil
                })
                sema.wait()
                if (!errorOccurred) {
                    if (self.tabBarItem.title! == "Upcoming") {
                        removeUpcomingFlightFromCoreData(datetime: (flightCell.flight?.datetime!)!)
                    } else {
                        removePastFlightFromCoreData(datetime: (flightCell.flight?.datetime!)!)
                    }
                    handleRefresh()
                }
                removeNotificationsFromNotificationCenter(flight: flightCell.flight!)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let flight = currentFlightsArray()?[indexPath.row]//flights?[indexPath.row]
        selectedFlight = flight
        addBlurView(forMenu: false)
        tableView.isScrollEnabled = false
        optionsVC = self.storyboard!.instantiateViewController(withIdentifier: "FlightOptionsViewController") as? FlightOptionsViewController
        optionsVC?.delegate = self
        optionsVC?.flight = flight
        self.view.addSubview((optionsVC?.view)!)
        self.addChildViewController(optionsVC!)
        optionsVC?.view.layoutIfNeeded()
        
        optionsVC?.view.frame=CGRect(x: 0, y: UIScreen.main.bounds.size.height, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            if self.view.bounds.minY > 0 {
                self.optionsVC?.view.frame=CGRect(x: 0, y: (self.navigationController?.navigationBar.bounds.height)!, width: UIScreen.main.bounds.size.width, height: self.view.bounds.maxY)
            } else if self.view.bounds.minY > -self.BOUNDS_OFFSET {
                self.optionsVC?.view.frame=CGRect(x: 0, y: self.view.bounds.minY + self.BOUNDS_OFFSET, width: UIScreen.main.bounds.size.width, height: self.view.bounds.maxY)
            } else {
                self.optionsVC?.view.frame=CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
            }
            
        }, completion:nil)
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
    
    fileprivate func removeUpcomingFlightFromCoreData(datetime: String) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedFlight")
        let context = self.managedObjectContext!
        request.predicate = NSPredicate(format: "TRUEPREDICATE")
        var fetchedObjects: [NSManagedObject]?
        context.perform {
            fetchedObjects = (try? context.fetch(request)) as? [NSManagedObject]
            if fetchedObjects != nil {
                for object in fetchedObjects! {
                    let savedFlight = object as! SavedFlight
                    if savedFlight.datetime == datetime {
                        // we found the flight, delete it
                        context.delete(object)
                        do {
                            try context.save()
                        } catch let error {
                            print("Couldn't save Core Data after deletion: \(error)")
                        }
                    }
                }
            }
        }
        DispatchQueue.main.async {
            SwiftSpinner.hide()
        }
    }
    
    fileprivate func removePastFlightFromCoreData(datetime: String) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PastFlight")
        let context = self.managedObjectContext!
        request.predicate = NSPredicate(format: "TRUEPREDICATE")
        var fetchedObjects: [NSManagedObject]?
        context.perform {
            fetchedObjects = (try? context.fetch(request)) as? [NSManagedObject]
            if fetchedObjects != nil {
                for object in fetchedObjects! {
                    let pastFlight = object as! PastFlight
                    if pastFlight.datetime == datetime {
                        // we found the flight, delete it
                        context.delete(object)
                        do {
                            try context.save()
                        } catch let error {
                            print("Couldn't save Core Data after deletion: \(error)")
                        }
                    }
                }
            }
        }
        DispatchQueue.main.async {
            SwiftSpinner.hide()
        }
    }
    
    fileprivate func removeSharedFlightFromCoreData(datetime: String) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SharedFlight")
        let context = self.managedObjectContext!
        request.predicate = NSPredicate(format: "TRUEPREDICATE")
        var fetchedObjects: [NSManagedObject]?
        context.perform {
            fetchedObjects = (try? context.fetch(request)) as? [NSManagedObject]
            if fetchedObjects != nil {
                for object in fetchedObjects! {
                    let sharedFlight = object as! SharedFlight
                    if sharedFlight.datetime == datetime {
                        // we found the flight, delete it
                        context.delete(object)
                        do {
                            try context.save()
                        } catch let error {
                            print("Couldn't save Core Data after deletion: \(error)")
                        }
                    }
                }
            }
        }
        DispatchQueue.main.async {
            SwiftSpinner.hide()
        }
    }
    
    func handleRefresh() {
        // Reload data and update flights variable
        loadFlights(email: (user?.email_id)!, fromRefreshHandler: true)
        loadSharedFlights(email: (user?.email_id)!, fromRefreshHandler: true)
        self.refreshController?.endRefreshing()
    }
    
    func manualEntryButtonTapped() {
        editingFlight = false
        self.performSegue(withIdentifier: Storyboard.ManualEntrySegue , sender: self)
    }
    
    // gets all the flights assosiated with a given user and returns them in an array of flight objects
    // returns flights in order of date.
    fileprivate func loadFlights(email:String, fromRefreshHandler: Bool) {
        
        var resultFlights = [Flight]()
        var errorOccurred = false
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
        updateMapperConfig.saveBehavior = .updateSkipNullAttributes
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "email = :id"
        scanExpression.expressionAttributeValues = [":id": email]
        let sema = DispatchSemaphore(value: 0)
        dynamoDBObjectMapper.scan(Flight.self, expression: scanExpression)
            .continueWith(block: {(task:AWSTask!) -> AnyObject! in
                if let error = task.error as? NSError {
                    errorOccurred = true
                    if (error.domain == NSURLErrorDomain) {
                        if fromRefreshHandler {
                            DispatchQueue.main.async {
                                self.displayAlert("Poor Network Connection", message: "Couldn't load flights. Please try again.")
                            }
                        }
                    }
                } else if let dbResults = task.result {
                    for flight in dbResults.items as! [Flight] {
                        resultFlights.append(flight)
                        if (flight.getDate()! > Date()){
                            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                                if settings.authorizationStatus == .authorized {
                                    self.scheduleLocalNotifications(flight: flight)
                                }
                            }
                        }
                    }
                }
                sema.signal()
                return nil
            })
        
        sema.wait()
        if (!errorOccurred) {
            self.flights = resultFlights
            self.pastFlights = resultFlights
        } else {
            DispatchQueue.main.async {
                self.refreshController?.endRefreshing()
            }
        }
    }
    
    // gets all the flights shared with a given user and returns them in an array of flight objects
    // returns flights in order of date.
    fileprivate func loadSharedFlights(email:String, fromRefreshHandler: Bool) {
        var resultFlights = [Flight]()
        var errorOccurred = false
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
        updateMapperConfig.saveBehavior = .updateSkipNullAttributes
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "contains (sharedWith, :id)"
        scanExpression.expressionAttributeValues = [":id": email]
        let sema = DispatchSemaphore(value: 0)
        dynamoDBObjectMapper.scan(Flight.self, expression: scanExpression)
            .continueWith(block: {(task:AWSTask!) -> AnyObject! in
                if let error = task.error as? NSError {
                    errorOccurred = true
                    if (error.domain == NSURLErrorDomain) {
                        if fromRefreshHandler {
                            DispatchQueue.main.async {
                                self.displayAlert("Poor Network Connection", message: "Couldn't load flights. Please try again.")
                            }
                        }
                    }
                } else if let dbResults = task.result {
                    for flight in dbResults.items as! [Flight] {
                        if (flight.getDate()! > Date()){
                            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                                if settings.authorizationStatus == .authorized {
                                    self.scheduleLocalNotifications(flight: flight)
                                }
                            }
                        }
                        resultFlights.append(flight)
                    }
                }
                sema.signal()
                return nil
            })
        
        sema.wait()
        if (!errorOccurred) {
            self.sharedFlights = resultFlights
        } else {
            DispatchQueue.main.async {
                self.refreshController?.endRefreshing()
            }
        }
    }
    
    fileprivate func scheduleLocalNotifications(flight: Flight) {
        //create notification dates
        let date = flight.getDate()
        let calendar = Calendar(identifier: .gregorian)
        let flight_components = calendar.dateComponents(in: .current, from: date!)
        let new_date24 = flight_components.calendar?.date(byAdding: .day, value: -1, to: date!)
        let new_date12 = flight_components.calendar?.date(byAdding: .hour, value: -12, to: date!)
        let new_date6 = flight_components.calendar?.date(byAdding: .hour, value: -6, to: date!)
        let new_date1 = flight_components.calendar?.date(byAdding: .hour, value: -1, to: date!)
        let arr_Dates = [new_date24, new_date12, new_date6, new_date1]
        
        //notification content
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = flight.flightNumber!
        notificationContent.subtitle = flight.airline!
        notificationContent.body = String(format: "Your flight from %@ to %@ leaves soon.",
                                          flight.departureAirport!, flight.destinationAirport!)
        notificationContent.sound = UNNotificationSound.default()
        
        //dateformatter
        let df = DateFormatter()
        df.dateFormat = ("MM-dd-yyyy HH:mm")
        
        //make notification for each date and store in UNUserNotificationCenter
        for time in arr_Dates {
            let date_string = df.string(from: time!)
            let components = calendar.dateComponents(in: .current, from: time!)
            let newComponents = DateComponents(calendar: calendar, timeZone: .current,
                                               month: components.month, day: components.day, hour: components.hour, minute: components.minute)
            let calendarTrigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: false)
            let identifier = (user?.email_id)! + date_string
            let notificationRequest = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: calendarTrigger)
            UNUserNotificationCenter.current().add(notificationRequest) { (error) in
                if let error = error {
                    print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
                }
            }
            
            //save identifier in flight object
            if(flight.identifiers == nil){
                flight.identifiers = Set<String>()
            }
            (flight.identifiers)!.insert(identifier)
        }
    }
    
    // MARK: - Slider Menu Delegate Functions
    // Adapted from: https://github.com/ashishkakkad8/AKSwiftSlideMenu
    
    func slideMenuItemSelected(_ option: String) {
        switch(option){
        case "Account":
            print("Account Button Tapped")
            self.performSegue(withIdentifier: Storyboard.AccountSettingsSegue , sender: self)
            
            break
        case "Sign Out":
            print("Sign Out Tapped")
            removeUserFromCoreData()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            self.navigationController!.popToRootViewController(animated: true)
            break
        case "Edit":
            print("Edit Button Tapped")
            editingFlight = true
            self.performSegue(withIdentifier: Storyboard.ManualEntrySegue , sender: self)
            break
        case "Status":
            print("Status Button Tapped")
            self.performSegue(withIdentifier: Storyboard.StatusSegue , sender: self)
            break
        case "Add to Calendar":
            print("Add to Calendar Tapped")
            addFlightToCalendar(flight: (optionsVC?.flight!)!)
            break
        case "Share":
            print("Share Button Tapped")
            handleShare()
            break
        case "Export":
            print("Export Button Tapped")
            displayShareSheet(flight: (optionsVC?.flight!)!)
            break
        default:
            print("Cancel tapped")
        }
    }
    
    // displays a modal share sheet view with links to various other apps
    fileprivate func displayShareSheet(flight: Flight) {
        var shareContent = "Here are the details for my upcoming flight:\n\n"
        shareContent += ("Flight:\t" + flight.airline! + " #" + flight.flightNumber! + "\n")
        shareContent += ("Time:\t" + flight.getTimeString()! + "\n")
        shareContent += ("Date:\t" + flight.getDateString()! + "\n")
        shareContent += ("From:\t" + flight.departureAirport! + "\n")
        shareContent += ("To:\t\t" + flight.destinationAirport! + "\n\n")
        shareContent += "Shared from Trackify."
        let activityViewController = UIActivityViewController(activityItems: [shareContent as NSString], applicationActivities: nil)
        present(activityViewController, animated: true, completion: {})
    }
    
    // adds a calendar event to the user's calendar if possible
    // detects and prevents the addition of duplicate events
    fileprivate func addFlightToCalendar(flight: Flight) {
        let eventStore : EKEventStore = EKEventStore()
        eventStore.requestAccess(to: .event) { (granted, error) in
            
            if (granted) && (error == nil) {
                print("granted \(granted)")
                print("error \(error)")
                
                let calendar = Calendar(identifier: .gregorian)
                let startDate = flight.getDate()!
                let endDate = calendar.date(byAdding: Calendar.Component.hour, value: 1, to: startDate)!
                
                // check to see if this event has already been added to the user's calendar
                let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
                let existingEvents = eventStore.events(matching: predicate)
                for event in existingEvents {
                    if event.title == (flight.airline! + " #" + flight.flightNumber!) && event.startDate == startDate {
                        DispatchQueue.main.async {
                            self.displayAlert("Duplicate Calendar Event", message: "This flight has already been added to your calendar!")
                        }
                        return
                    }
                }
                
                // event does not yet exist in the calendar
                
                let event:EKEvent = EKEvent(eventStore: eventStore)
                event.title = flight.airline! + " #" + flight.flightNumber!
                event.startDate = flight.getDate()!
                event.endDate = endDate
                var notesStr = ""
                notesStr += ("Flight:\t" + flight.airline! + " #" + flight.flightNumber! + "\n")
                notesStr += ("Time:\t" + flight.getTimeString()! + "\n")
                notesStr += ("Date:\t" + flight.getDateString()! + "\n")
                notesStr += ("From:\t" + flight.departureAirport! + "\n")
                notesStr += ("To:\t\t" + flight.destinationAirport! + "\n")
                notesStr += ("Confirmation:\t" + flight.confirmation! + "\n\n")
                event.notes = notesStr
                event.calendar = eventStore.defaultCalendarForNewEvents
                do {
                    try eventStore.save(event, span: .thisEvent)
                } catch let error as NSError {
                    print("failed to save event with error : \(error)")
                }
                print("Saved Event")
                DispatchQueue.main.async {
                    self.displayAlert("Calendar Event Created", message: "Successfully added the selected flight's details to your calendar.")
                }
            } else {
                print("failed to save event with error : \(error) or access not granted")
                DispatchQueue.main.async {
                    self.displayAlert("Calendar Error", message: "Could not add the selected flight to your calendar. Please verify that Trackify has permission to access your calendar and try again. ")
                }
            }
        }
    }
    
    fileprivate func addUpcomingFlightToCoreData(flight: Flight) {
        managedObjectContext?.perform {
            SavedFlight.addFlight(flight.email!, airline: flight.airline!, flightNumber: flight.flightNumber!, departureAirport: flight.departureAirport!, destinationAirport: flight.destinationAirport!, confirmation: flight.confirmation!, datetime: flight.datetime!, inManagedObjectContext: self.managedObjectContext!)
            do {
                try self.managedObjectContext?.save()
            } catch let error {
                print("error saving signed in user: \(error)")
            }
        }
    }
    
    fileprivate func addPastFlightToCoreData(flight: Flight) {
        managedObjectContext?.perform {
            PastFlight.addFlight(flight.email!, airline: flight.airline!, flightNumber: flight.flightNumber!, departureAirport: flight.departureAirport!, destinationAirport: flight.destinationAirport!, confirmation: flight.confirmation!, datetime: flight.datetime!, inManagedObjectContext: self.managedObjectContext!)
            do {
                try self.managedObjectContext?.save()
            } catch let error {
                print("error saving signed in user: \(error)")
            }
        }
    }
    
    fileprivate func addSharedFlightToCoreData(flight: Flight) {
        managedObjectContext?.perform {
            SharedFlight.addFlight(flight.email!, airline: flight.airline!, flightNumber: flight.flightNumber!, departureAirport: flight.departureAirport!, destinationAirport: flight.destinationAirport!, confirmation: flight.confirmation!, datetime: flight.datetime!, inManagedObjectContext: self.managedObjectContext!)
            do {
                try self.managedObjectContext?.save()
            } catch let error {
                print("error saving signed in user: \(error)")
            }
        }
    }
    
    // this function is called when a user signs out
    // it removes them from core data so that upon re-opening the app,
    // a new user must sign in or create an account
    fileprivate func removeUserFromCoreData() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedUser")
        let context = self.managedObjectContext!
        request.predicate = NSPredicate(format: "TRUEPREDICATE")
        var fetchedObjects: [NSManagedObject]?
        context.perform {
            fetchedObjects = (try? context.fetch(request)) as? [NSManagedObject]
            if fetchedObjects != nil {
                // we found the signed in user, delete it
                for object in fetchedObjects! {
                    context.delete(object)
                    do {
                        try context.save()
                    } catch let error {
                        print("Couldn't save Core Data after deletion: \(error)")
                    }
                }
            }
        }
    }
    
    // For the text field config handler
    fileprivate func shareFlight(textField: UITextField!) {
        print(textField.text!)
    }
    
    // Updates the database and actually
    fileprivate func shareFlight(_ flight: Flight?, withEmail email: String) {
        if !isValidEmail(testStr: email) {
            self.displayAlert("Invalid Email", message: "Please enter a valid email address.")
            print("invalid email")
        } else if flight != nil{
            print(flight ?? "no flight")
            if (flight?.sharedWith) == nil {
                flight?.sharedWith = Set<String>()
            }
            flight?.sharedWith?.insert(email)
            //updates flight in the database
            let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
            let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
            updateMapperConfig.saveBehavior = .updateSkipNullAttributes
            
            dynamoDBObjectMapper.save(flight!).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
                if let error = task.error as? NSError {
                    if (error.domain == NSURLErrorDomain) {
                        DispatchQueue.main.async {
                            self.displayAlert("Poor Network Connection", message: "Please try again.")
                        }
                    }
                } else {
                    // success!
                    self.displayAlert("Share Success!", message: "Your flight was successfully shared with \(email)")
                }
                return nil
            })
        }
    }
    
    fileprivate func handleCancel(alertView: UIAlertAction!) {
        print("User clicked cancelled sharing")
    }
    
    // Adds an alert to share flight
    fileprivate func handleShare(){
        enterEmail = UIAlertController(title: "Share Flight", message: "Please enter the email for the user that you want to share your flight with", preferredStyle: UIAlertControllerStyle.alert)
        enterEmail!.addTextField(configurationHandler: shareFlight)
        enterEmail?.textFields?[0].keyboardType = .emailAddress
        enterEmail!.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: handleCancel))
        enterEmail!.addAction(UIAlertAction(title: "Share", style: UIAlertActionStyle.default, handler: { (UIAlertAction)in
            print("User clicked the share button")
            print(self.enterEmail!.textFields![0].text!)
            if self.enterEmail!.textFields![0].text! == self.selectedFlight?.email! {
                print("same emails not sharing")
                self.displayAlert("Sharing Not Allowed", message: "Please enter an email that is different from your own")
                return
            }
            self.shareFlight(self.selectedFlight,withEmail: self.enterEmail!.textFields![0].text!)
            
        }))
        self.present(enterEmail!, animated: true, completion: {
            print("Sharing email alert!")
        })
    }

    
    // for UpdateAccountDelegate
    func updateUser(newUser: User) {
        self.user = newUser
    }
    
    func addBlurView(forMenu: Bool) {
        if forMenu {
            menuBlurEffectView = UIVisualEffectView(effect: blurEffect)
            menuBlurEffectView?.frame = view.bounds
            menuBlurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(menuBlurEffectView!)
        } else {
            optionsBlurEffectView = UIVisualEffectView(effect: blurEffect)
            optionsBlurEffectView?.frame = view.bounds
            optionsBlurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(optionsBlurEffectView!)
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboard.ManualEntrySegue {
            if let destinationVC = segue.destination as? ManualEntryViewController {
                destinationVC.userEmail = user?.email_id
                if (editingFlight) {
                    destinationVC.editFlight = optionsVC?.flight
                }
                if (self.tabBarItem.title! == "Upcoming") {
                    destinationVC.removeFlightFromCoreData = self.removeUpcomingFlightFromCoreData
                } else if (self.tabBarItem.title! == "Past") {
                    destinationVC.removeFlightFromCoreData = self.removePastFlightFromCoreData
                } else {
                    destinationVC.removeFlightFromCoreData = self.removeSharedFlightFromCoreData
                }
                
            }
        } else if segue.identifier == Storyboard.AccountSettingsSegue {
            if let destinationVC = segue.destination as? SignUpViewController {
                destinationVC.editableUser = self.user
                destinationVC.delegate = self
                destinationVC.removeUserFromCoreData = self.removeUserFromCoreData
            }
        } else if segue.identifier == Storyboard.StatusSegue {
            if let destinationVC = segue.destination as? StatusViewController {
                destinationVC.flight = optionsVC?.flight
            }
        }
    }
    
}

extension FlightsTableViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}
