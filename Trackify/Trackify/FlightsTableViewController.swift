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
    
    fileprivate var flights: [Flight]? {
        didSet {
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
        // query for flights for the logged in user
        flights = loadFlights(email: (user?.email_id)!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpNavigationBar()
    }
    
    // Set up the UI for the navigation bar
    fileprivate func setUpNavigationBar() {
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.barTintColor = helpers.themeColor
        
        // set up title image
        let logo = #imageLiteral(resourceName: "trackify_white_title")
        let imageView = UIImageView(image: logo)
        imageView.frame = CGRect(x:0, y:0, width:40, height:40)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView
        
        // set up settings button
        let settingsButton = UIBarButtonItem()
        settingsButton.image = #imageLiteral(resourceName: "menu_icon")
        settingsButton.tintColor = UIColor.white
        settingsButton.customView?.contentMode = .scaleAspectFit
        self.navigationItem.leftBarButtonItem = settingsButton
        
        // set up manual entry button
        let addButton = UIBarButtonItem()
        addButton.image = #imageLiteral(resourceName: "plus_icon")
        addButton.tintColor = UIColor.white
        addButton.customView?.contentMode = .scaleAspectFit
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
