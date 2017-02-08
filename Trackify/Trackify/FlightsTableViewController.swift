//
//  FlightsTableViewController.swift
//  Trackify
//
//  Created by Scott Buttinger on 2/6/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit

class FlightsTableViewController: UITableViewController {
    
    // MARK: - Variables
    
    var user: User?
    
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
        
        setUpTestFlights()
        // query for flights
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
    
    fileprivate func setUpTestFlights() {
        flights = []
        
        var testFlight = Flight()
        testFlight.airline = "Southwest"
        var dateString = "02-10-2017 10:00"
        df.dateFormat = "MM-dd-yyyy HH:mm"
        testFlight.date = df.date(from: dateString)
        testFlight.departureAirport = "LGA"
        testFlight.destinationAirport = "SFO"
        testFlight.flightNumber = 3878
        flights!.append(testFlight)
        
        testFlight = Flight()
        testFlight.airline = "American"
        dateString = "02-22-2017 16:15"
        testFlight.date = df.date(from: dateString)
        testFlight.departureAirport = "SFO"
        testFlight.destinationAirport = "JFK"
        testFlight.flightNumber = 265
        flights!.append(testFlight)
        
        testFlight = Flight()
        testFlight.airline = "Air Canada"
        dateString = "03-5-2017 07:45"
        testFlight.date = df.date(from: dateString)
        testFlight.departureAirport = "YYZ"
        testFlight.destinationAirport = "FLL"
        testFlight.flightNumber = 842
        flights!.append(testFlight)
        
        testFlight = Flight()
        testFlight.airline = "Delta"
        dateString = "03-12-2017 21:20"
        testFlight.date = df.date(from: dateString)
        testFlight.departureAirport = "MIA"
        testFlight.destinationAirport = "IAD"
        testFlight.flightNumber = 5436
        flights!.append(testFlight)
        
        testFlight = Flight()
        testFlight.airline = "United"
        dateString = "04-18-2017 6:30"
        testFlight.date = df.date(from: dateString)
        testFlight.departureAirport = "JFK"
        testFlight.destinationAirport = "LAS"
        testFlight.flightNumber = 1920
        flights!.append(testFlight)
        
        testFlight = Flight()
        testFlight.airline = "Virgin America"
        dateString = "06-13-2017 10:10"
        testFlight.date = df.date(from: dateString)
        testFlight.departureAirport = "ORD"
        testFlight.destinationAirport = "SJC"
        testFlight.flightNumber = 445
        flights!.append(testFlight)
        
        testFlight = Flight()
        testFlight.airline = "Sun Country"
        dateString = "07-30-2017 6:50"
        testFlight.date = df.date(from: dateString)
        testFlight.departureAirport = "OAK"
        testFlight.destinationAirport = "LAX"
        testFlight.flightNumber = 672
        flights!.append(testFlight)
        
        testFlight = Flight()
        testFlight.airline = "Frontier"
        dateString = "11-01-2017 14:00"
        testFlight.date = df.date(from: dateString)
        testFlight.departureAirport = "DFW"
        testFlight.destinationAirport = "SEA"
        testFlight.flightNumber = 188
        flights!.append(testFlight)
        
        testFlight = Flight()
        testFlight.airline = "Hawaiian"
        dateString = "12-26-2017 7:20"
        testFlight.date = df.date(from: dateString)
        testFlight.departureAirport = "SFO"
        testFlight.destinationAirport = "HNL"
        testFlight.flightNumber = 160
        flights!.append(testFlight)
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
        
        print("REFRESH")
        self.refreshController?.endRefreshing()
    }
    
    func manualEntryButtonTapped() {
        self.performSegue(withIdentifier: Storyboard.ManualEntrySegue , sender: self)
    }
    
    func settingsButtonTapped() {
        // eventually add popover, but for now just sign out
        self.navigationController!.popToRootViewController(animated: true)
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
