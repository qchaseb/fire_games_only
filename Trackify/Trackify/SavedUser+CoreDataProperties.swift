//
//  SavedUser+CoreDataProperties.swift
//  Trackify
//
//  Created by Scott Buttinger on 3/14/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import Foundation
import CoreData


extension SavedUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedUser> {
        return NSFetchRequest<SavedUser>(entityName: "SavedUser");
    }

    @NSManaged public var emailAddress: String?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var password: String?
    @NSManaged public var flights: NSSet?
    @NSManaged public var pastFlights: NSSet?
    @NSManaged public var sharedFlights: NSSet?

}

// MARK: Generated accessors for flights
extension SavedUser {

    @objc(addFlightsObject:)
    @NSManaged public func addToFlights(_ value: SavedFlight)

    @objc(removeFlightsObject:)
    @NSManaged public func removeFromFlights(_ value: SavedFlight)

    @objc(addFlights:)
    @NSManaged public func addToFlights(_ values: NSSet)

    @objc(removeFlights:)
    @NSManaged public func removeFromFlights(_ values: NSSet)

}

// MARK: Generated accessors for pastFlights
extension SavedUser {

    @objc(addPastFlightsObject:)
    @NSManaged public func addToPastFlights(_ value: PastFlight)

    @objc(removePastFlightsObject:)
    @NSManaged public func removeFromPastFlights(_ value: PastFlight)

    @objc(addPastFlights:)
    @NSManaged public func addToPastFlights(_ values: NSSet)

    @objc(removePastFlights:)
    @NSManaged public func removeFromPastFlights(_ values: NSSet)

}

// MARK: Generated accessors for sharedFlights
extension SavedUser {

    @objc(addSharedFlightsObject:)
    @NSManaged public func addToSharedFlights(_ value: SharedFlight)

    @objc(removeSharedFlightsObject:)
    @NSManaged public func removeFromSharedFlights(_ value: SharedFlight)

    @objc(addSharedFlights:)
    @NSManaged public func addToSharedFlights(_ values: NSSet)

    @objc(removeSharedFlights:)
    @NSManaged public func removeFromSharedFlights(_ values: NSSet)

}
