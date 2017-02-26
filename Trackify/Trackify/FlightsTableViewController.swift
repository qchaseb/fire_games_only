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

class FlightsTableViewController: UITableViewController, SlideMenuDelegate {
    
    // MARK: - Variables
    var user: User?
    fileprivate var initialFlights = true
    
    var flights: [Flight]? {
        didSet {
            flights?.sort(by: { $0.getDate()! < $1.getDate()! })
            flights = flights?.filter({ $0.getDate()! > Date()})
            if (!initialFlights) {
                for flight in flights! {
                    addFlightToCoreData(flight: flight)
                }
            }
            self.tableView.reloadData()
            self.refreshController?.endRefreshing()
        }
    }
    
    var menuVC: MenuViewController?
    var optionsVC: FlightOptionsViewController?
    let BOUNDS_OFFSET: CGFloat = 64
    
    let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.regular)
    var blurEffectView: UIVisualEffectView?
    
    // get managed object context from delegate
    var managedObjectContext: NSManagedObjectContext? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    
    fileprivate var refreshController: UIRefreshControl?
    fileprivate var df = DateFormatter()
    fileprivate var helpers = Helpers()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialFlights = false
        self.refreshController = UIRefreshControl()
        self.refreshController?.addTarget(self, action: #selector(self.handleRefresh), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshController!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpNavigationBar()
        
        // query for flights for the logged in user
        loadFlights(email: (user?.email_id)!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if flights?.count == 0 {
            displayAlert("No Upcoming Flights", message: "Forward your flight confirmation emails to flights@trackify.biz or manually enter a flight by touching the button above!")
        }
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        self.navigationController?.isNavigationBarHidden = true
    }
    
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
        
        // set up menu button
        let menuButton = UIBarButtonItem()
        menuButton.image = #imageLiteral(resourceName: "menu_icon")
        menuButton.tintColor = UIColor.white
        menuButton.customView?.contentMode = .scaleAspectFit
        menuButton.target = self
        menuButton.action = #selector(self.menuButtonTapped(_:))
        self.navigationItem.leftBarButtonItem = menuButton
        
        // set up manual entry button
        let addButton = UIBarButtonItem()
        addButton.image = #imageLiteral(resourceName: "plus_icon")
        addButton.tintColor = UIColor.white
        addButton.customView?.contentMode = .scaleAspectFit
        addButton.target = self
        addButton.action = #selector(self.manualEntryButtonTapped)
        self.navigationItem.rightBarButtonItem = addButton
        
        // set time and battery logos to be white
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarStyle = .default
        self.navigationController?.isNavigationBarHidden = true
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flights!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        if let flightCell = tableView.dequeueReusableCell(withIdentifier: Storyboard.FlightCell, for: indexPath) as? FlightTableViewCell {
            flightCell.flight = flights?[indexPath.row]
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
                let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
                let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
                updateMapperConfig.saveBehavior = .updateSkipNullAttributes
                let sema = DispatchSemaphore(value: 0)
                var errorOccurred = false
                dynamoDBObjectMapper.remove(flightCell.flight!).continueWith(block: {(task:AWSTask!) -> AnyObject! in
                    if let error = task.error as? NSError {
                        errorOccurred = true
                        print("Remove failed. Error: \(error)")
                        if (error.domain == NSURLErrorDomain) {
                            DispatchQueue.main.async {
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
                    removeFlightFromCoreData(datetime: (flightCell.flight?.datetime!)!)
                    handleRefresh()
                }
            }
            
        }
    }
    
    fileprivate func removeFlightFromCoreData(datetime: String) {
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
    }
    
    // move the settings menu if the user scrolls while it is open
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if menuVC != nil {
            menuVC!.view.frame = CGRect(x: self.view.bounds.minX, y: self.view.bounds.minY+BOUNDS_OFFSET, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let flight = flights?[indexPath.row]
        addBlurView()
        tableView.isScrollEnabled = false
        optionsVC = self.storyboard!.instantiateViewController(withIdentifier: "FlightOptionsViewController") as? FlightOptionsViewController
        optionsVC?.delegate = self
        self.view.addSubview((optionsVC?.view)!)
        self.addChildViewController(optionsVC!)
        optionsVC?.view.layoutIfNeeded()
        
        optionsVC?.view.frame=CGRect(x: UIScreen.main.bounds.size.width, y: self.view.bounds.minY+BOUNDS_OFFSET, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.optionsVC?.view.frame=CGRect(x: 0, y: self.view.bounds.minY+self.BOUNDS_OFFSET, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        }, completion:nil)

        
    }
    
    func handleRefresh() {
        // Reload data and update flights variable
        loadFlights(email: (user?.email_id)!)
        self.refreshController?.endRefreshing()
    }
    
    func manualEntryButtonTapped() {
        self.performSegue(withIdentifier: Storyboard.ManualEntrySegue , sender: self)
    }
    
    // gets all the flights assosiated with a given user and returns them in an array of flight objects
    // returns flights in order of date. 
    fileprivate func loadFlights(email:String) {

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
                        DispatchQueue.main.async {
                            self.displayAlert("Poor Network Connection", message: "Couldn't load flights. Please try again.")
                        }
                    }
                } else if let dbResults = task.result {
                    for flight in dbResults.items as! [Flight] {
                        resultFlights.append(flight)
                    }
                }
                sema.signal()
                return nil
            })

        sema.wait()
        if (!errorOccurred) {
            self.flights = resultFlights
        } else {
            DispatchQueue.main.async {
                self.refreshController?.endRefreshing()
            }
        }
    }
    
    // MARK: - Slider Menu Delegate Functions
    // Adapted from: https://github.com/ashishkakkad8/AKSwiftSlideMenu
    
    func slideMenuItemSelected(_ option: String) {
        switch(option){
        case "Account":
            print("Account Button Tapped")
            
            // self.openViewControllerBasedOnIdentifier("Account")
            
            break
        case "Sign Out":
            print("Log Out Tapped")
            removeUserFromCoreData()
            self.navigationController!.popToRootViewController(animated: true)
            
            break
        default:
            print("default")
        }
    }
    
    func addFlightToCoreData(flight: Flight) {
        managedObjectContext?.perform {
            SavedFlight.addFlight(flight.email!, airline: flight.airline!, flightNumber: flight.flightNumber!, departureAirport: flight.departureAirport!, destinationAirport: flight.destinationAirport!, confirmation: flight.confirmation!, datetime: flight.datetime!, inManagedObjectContext: self.managedObjectContext!)
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
    func removeUserFromCoreData() {
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
    
    func openViewControllerBasedOnIdentifier(_ strIdentifier:String) {
        let destViewController : UIViewController = self.storyboard!.instantiateViewController(withIdentifier: strIdentifier)
        
        let topViewController : UIViewController = self.navigationController!.topViewController!
        
        if (topViewController.restorationIdentifier! == destViewController.restorationIdentifier!){
            print("Same VC")
        } else {
            self.navigationController!.pushViewController(destViewController, animated: true)
        }
    }
    
    // open or close slider menu with animation
    func menuButtonTapped(_ sender : UIButton) {
        if menuVC != nil {
            // hide menu if it is already being displayed
            self.slideMenuItemSelected("")
            
            let settingsMenuView : UIView = view.subviews.last!
            
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                var frameMenu : CGRect = settingsMenuView.frame
                frameMenu.origin.x = -1 * UIScreen.main.bounds.size.width
                settingsMenuView.frame = frameMenu
                settingsMenuView.layoutIfNeeded()
                settingsMenuView.backgroundColor = UIColor.clear
            }, completion: { (finished) -> Void in
                settingsMenuView.removeFromSuperview()
            })
            menuVC = nil
            blurEffectView?.removeFromSuperview()
            blurEffectView = nil
            tableView.isScrollEnabled = true
        } else {
            addBlurView()
            tableView.isScrollEnabled = false
            menuVC = self.storyboard!.instantiateViewController(withIdentifier: "MenuViewController") as? MenuViewController
            menuVC?.menuButton = sender
            menuVC?.delegate = self
            self.view.addSubview((menuVC?.view)!)
            self.addChildViewController(menuVC!)
            menuVC?.view.layoutIfNeeded()
            
            menuVC?.view.frame=CGRect(x: 0 - UIScreen.main.bounds.size.width, y: self.view.bounds.minY+BOUNDS_OFFSET, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
            
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.menuVC?.view.frame=CGRect(x: 0, y: self.view.bounds.minY+self.BOUNDS_OFFSET, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
            }, completion:nil)
        }
    }
    
    fileprivate func addBlurView() {
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView?.frame = view.bounds
        blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView!)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboard.ManualEntrySegue {
            if let destinationVC = segue.destination as? ManualEntryViewController {
                destinationVC.userEmail = user?.email_id
            }
        }
    }

}
