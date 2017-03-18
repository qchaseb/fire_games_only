//
//  SharedFlight+CoreDataClass.swift
//  Trackify
//
//  Created by Scott Buttinger on 3/14/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import Foundation
import CoreData


public class SharedFlight: NSManagedObject {
    class func addFlight(_ emailAddress: String, airline: String, flightNumber: String, departureAirport: String, destinationAirport:String, confirmation:String, datetime:String, inManagedObjectContext context: NSManagedObjectContext) {
        
        if let users = try? context.fetch(NSFetchRequest(entityName: "SavedUser")) {
            if !users.isEmpty {
                let signedInUser = users[0] as! SavedUser
                
                // check if this flight already exists
                for userFlight in signedInUser.sharedFlights! {
                    let sharedFlight = userFlight as! SharedFlight
                    if sharedFlight.datetime == datetime {
                        // don't store this flight again
                        return
                    }
                }
                
                // this is a new flight! store it in core data
                if let flight = NSEntityDescription.insertNewObject(forEntityName: "SharedFlight", into: context) as? SharedFlight {
                    flight.airline = airline
                    flight.flightNumber = flightNumber
                    flight.departureAirport = departureAirport
                    flight.destinationAirport = destinationAirport
                    flight.confirmation = confirmation
                    flight.datetime = datetime
                    flight.user = signedInUser
                }
            }
        }
    }

}
