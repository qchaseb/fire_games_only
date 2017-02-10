//
//  FlightsTableViewController.swift
//  Trackify
//
//  Created by Scott Buttinger on 2/6/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit
import AWSDynamoDB

class FlightsTableViewController: UITableViewController {
    
    // MARK: - Variables
    
    var user: User?
    fileprivate var spinner = UIActivityIndicatorView()
    
    var flights: [Flight]? {
        didSet {
            flights?.sort(by: { $0.date! < $1.date! })
            self.tableView.reloadData()
            self.refreshController?.endRefreshing()
        }
    }
    
    fileprivate var refreshController: UIRefreshControl?
    
    fileprivate var df = DateFormatter()
    fileprivate var helpers = Helpers()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshController = UIRefreshControl()
        self.refreshController?.addTarget(self, action: #selector(self.handleRefresh), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshController!)
        self.refreshController?.beginRefreshing()
        
//        flights = []
        
//        setUpTestFlights()
        
        // query for flights for the logged in user
        flights = loadFlights(email: (user?.email_id)!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if flights?.count == 0 {
            displayAlert("No Upcoming Flights", message: "Forward your flight confirmation emails to flights@trackify.biz or manually enter a flight by touching the button above!")
        }
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
        
        // set up settings button
        let settingsButton = UIBarButtonItem()
        settingsButton.image = #imageLiteral(resourceName: "menu_icon")
        settingsButton.tintColor = UIColor.white
        settingsButton.customView?.contentMode = .scaleAspectFit
        settingsButton.target = self
        settingsButton.action = #selector(self.settingsButtonTapped)
        self.navigationItem.leftBarButtonItem = settingsButton
        
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
    
//    fileprivate func setUpTestFlights() {
//        
//        var testFlight = Flight()
//        testFlight.airline = "Southwest"
//        var dateString = "02-10-2017 10:00"
//        df.dateFormat = "MM-dd-yyyy HH:mm"
//        testFlight.date = df.date(from: dateString)
//        testFlight.departureAirport = "LGA"
//        testFlight.destinationAirport = "SFO"
//        testFlight.flightNumber = 3878
//        flights!.append(testFlight)
//        
//        testFlight = Flight()
//        testFlight.airline = "American"
//        dateString = "02-22-2017 16:15"
//        testFlight.date = df.date(from: dateString)
//        testFlight.departureAirport = "SFO"
//        testFlight.destinationAirport = "JFK"
//        testFlight.flightNumber = 265
//        flights!.append(testFlight)
//        
//        testFlight = Flight()
//        testFlight.airline = "Air Canada"
//        dateString = "03-5-2017 07:45"
//        testFlight.date = df.date(from: dateString)
//        testFlight.departureAirport = "YYZ"
//        testFlight.destinationAirport = "FLL"
//        testFlight.flightNumber = 842
//        flights!.append(testFlight)
//        
//        testFlight = Flight()
//        testFlight.airline = "Delta"
//        dateString = "03-12-2017 21:20"
//        testFlight.date = df.date(from: dateString)
//        testFlight.departureAirport = "MIA"
//        testFlight.destinationAirport = "IAD"
//        testFlight.flightNumber = 5436
//        flights!.append(testFlight)
//        
//        testFlight = Flight()
//        testFlight.airline = "United"
//        dateString = "04-18-2017 6:30"
//        testFlight.date = df.date(from: dateString)
//        testFlight.departureAirport = "JFK"
//        testFlight.destinationAirport = "LAS"
//        testFlight.flightNumber = 1920
//        flights!.append(testFlight)
//        
//        testFlight = Flight()
//        testFlight.airline = "Virgin America"
//        dateString = "06-13-2017 10:10"
//        testFlight.date = df.date(from: dateString)
//        testFlight.departureAirport = "ORD"
//        testFlight.destinationAirport = "SJC"
//        testFlight.flightNumber = 445
//        flights!.append(testFlight)
//        
//        testFlight = Flight()
//        testFlight.airline = "Sun Country"
//        dateString = "07-30-2017 6:50"
//        testFlight.date = df.date(from: dateString)
//        testFlight.departureAirport = "OAK"
//        testFlight.destinationAirport = "LAX"
//        testFlight.flightNumber = 672
//        flights!.append(testFlight)
//        
//        testFlight = Flight()
//        testFlight.airline = "Frontier"
//        dateString = "11-01-2017 14:00"
//        testFlight.date = df.date(from: dateString)
//        testFlight.departureAirport = "DFW"
//        testFlight.destinationAirport = "SEA"
//        testFlight.flightNumber = 188
//        flights!.append(testFlight)
//        
//        testFlight = Flight()
//        testFlight.airline = "Hawaiian"
//        dateString = "12-26-2017 7:20"
//        testFlight.date = df.date(from: dateString)
//        testFlight.departureAirport = "SFO"
//        testFlight.destinationAirport = "HNL"
//        testFlight.flightNumber = 160
//        flights!.append(testFlight)
//    }

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
            flightCell.flight = flights![indexPath.row]
            cell = flightCell
        }
        return cell!
    }
    
    func handleRefresh() {
        // Reload data and update flights variable
        flights = loadFlights(email: (user?.email_id)!)
        self.refreshController?.endRefreshing()
    }
    
    func manualEntryButtonTapped() {
        self.performSegue(withIdentifier: Storyboard.ManualEntrySegue , sender: self)
    }
    
    func settingsButtonTapped() {
        // eventually add popover, but for now just sign out
        self.navigationController!.popToRootViewController(animated: true)
    }
    
    // gets all the flights assosiated with a given user and returns them in an array of flight objects
    // returns flights in order of date. 
    fileprivate func loadFlights(email:String) -> [Flight] {
        var resultFlights = [Flight]()
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
        updateMapperConfig.saveBehavior = .updateSkipNullAttributes
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "email = :id"
        scanExpression.expressionAttributeValues = [":id": email]
        let sema = DispatchSemaphore(value: 0)
        dynamoDBObjectMapper.scan(Flight.self, expression: scanExpression)
            .continueOnSuccessWith(block: {(task:AWSTask!) -> AnyObject! in
                if let error = task.error as? NSError {
                    if (error.domain == NSURLErrorDomain) {
                        DispatchQueue.main.async {
                            self.displayAlert("No Network Connection", message: "Couldn't load flights. Please try again.")
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
        return resultFlights
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboard.ManualEntrySegue {
            if let destinationVC = segue.destination as? ManualEntryViewController {
                destinationVC.parentVC = self
            }
        }

    }

}
