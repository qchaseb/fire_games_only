//
//  PastFlight+CoreDataProperties.swift
//  Trackify
//
//  Created by Scott Buttinger on 3/14/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import Foundation
import CoreData


extension PastFlight {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PastFlight> {
        return NSFetchRequest<PastFlight>(entityName: "PastFlight");
    }

    @NSManaged public var airline: String?
    @NSManaged public var confirmation: String?
    @NSManaged public var datetime: String?
    @NSManaged public var departureAirport: String?
    @NSManaged public var destinationAirport: String?
    @NSManaged public var flightNumber: String?
    @NSManaged public var user: SavedUser?

}
