//
//  LoadAppViewController.swift
//  Trackify
//
//  Created by Scott Buttinger on 2/19/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit
import CoreData
import SwiftSpinner

class LoadAppViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        SwiftSpinner.show("Loading Trackify")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchForSignedInUser()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SwiftSpinner.hide()
    }
    
    fileprivate var user: User?
    fileprivate var flights = [Flight]()
    
    // get managed object context from delegate
    var managedObjectContext: NSManagedObjectContext? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext

    // look in our core data database to see if there is already a user signed in
    // if so, load their flights
    fileprivate func searchForSignedInUser() {
        managedObjectContext?.performAndWait {
            if let users = try? self.managedObjectContext?.fetch(NSFetchRequest(entityName: "SavedUser")) {
                if !users!.isEmpty {
                    let signedInUser = users![0] as! SavedUser
                    self.user = User()
                    self.user?.email_id = signedInUser.emailAddress
                    self.user?.first_name = signedInUser.firstName
                    self.user?.last_name = signedInUser.lastName
                    self.user?.password = signedInUser.password
                    for userFlight in signedInUser.flights! {
                        let savedFlight = userFlight as! SavedFlight
                        let flight = Flight()
                        flight?.airline = savedFlight.airline
                        flight?.flightNumber = savedFlight.flightNumber
                        flight?.confirmation = savedFlight.confirmation
                        flight?.datetime = savedFlight.datetime
                        flight?.departureAirport = savedFlight.departureAirport
                        flight?.destinationAirport = savedFlight.destinationAirport
                        self.flights.append(flight!)
                    }
                    self.goToFlightsScreen()
                } else {
                    self.goToWelcomeScreen()
                }
            }
        }
    }
    
    fileprivate func goToWelcomeScreen() {
        // segue to main menu
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: Storyboard.WelcomeScreenSegue, sender: self.self)
        }
    }
    
    fileprivate func goToFlightsScreen() {
        // segue to main menu
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: Storyboard.PreviouslySignedInSegue, sender: self.self)
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboard.PreviouslySignedInSegue {
            if let destinationVC = segue.destination as? FlightTabBarController {
                for vc in (destinationVC.viewControllers)! {
                    if let flightTVC = vc as? FlightsTableViewController {
                        flightTVC.user = user
                        flightTVC.flights = flights
                    }
                }
            }
        }
    }

}
