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
    fileprivate var df = DateFormatter()
    fileprivate var timeString: String?
    fileprivate var dateString: String?
    fileprivate var date: Date?
    
    var airline: String? {
        didSet {
            switch (airline!) {
            case "Southwest Airlines": airline = "Southwest"
            case "Delta Air Lines": airline = "Delta"
            case "United Airlines": airline = "United"
            case "American Airlines": airline = "American"
            case "Alaska Airlines": airline = "Alaska"
            case "Spirit Airlines": airline = "Spirit"
            case "Frontier Airlines": airline = "Frontier"
            case "JetBlue Airways": airline = "JetBlue"
            case "Allegiant Travel Company": airline = "Allegiant"
            case "Sun Country Airlines": airline = "Sun Country"
            case "Hawaiian Airlines": airline = "Hawaiian"
            default: break
            }
        }
    }
    var flightNumber: String?
    var departureAirport: String?
    var destinationAirport: String?
    var confirmation: String?
    var email: String?
    var datetime: String? {
        didSet {
            df.dateFormat = "YYYY-MM-dd HH:mm:ss"
            self.date = df.date(from: datetime!)
            df.dateFormat = "h:mm a"
            self.timeString = df.string(from: self.date!)
            df.dateFormat = "MMMM d, yyyy"
            self.dateString = df.string(from: self.date!)
        }
    }
    var identifiers: Set<String>?
    var sharedWith: Set<String>?

    class func dynamoDBTableName() -> String {
        return "TrackifyFlightsTable"
    }
    
    class func hashKeyAttribute() -> String {
        return "email"
    }
    
    class func rangeKeyAttribute() -> String {
        return "datetime"
    }
    
    func getTimeString() -> String? {
        return self.timeString
    }
    
    func getDateString() -> String? {
        return self.dateString
    }
    
    func getDate() -> Date? {
        return self.date
    }

}
