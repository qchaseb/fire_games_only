//
//  SavedUser+CoreDataProperties.swift
//  Trackify
//
//  Created by Scott Buttinger on 2/19/17.
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
