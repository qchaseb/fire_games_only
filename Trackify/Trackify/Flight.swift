//
//  Flight.swift
//  Trackify
//
//  Created by Scott Buttinger on 2/6/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import Foundation
import AWSDynamoDB

class Flight : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    var airline: String?
    var flightNumber: String?
    var date: Date?
    var departureAirport: String?
    var destinationAirport: String?
    var confirmation: String?
    var email:String?
    var datetime:String?
        
    class func dynamoDBTableName() -> String {
        return "TrackifyFlightsTable"
    }
    
    class func hashKeyAttribute() -> String {
        return "email"
    }
    
    class func rangeKeyAttribute() -> String {
        return "datetime"
    }

}
