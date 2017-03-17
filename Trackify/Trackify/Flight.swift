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
    
    var airline: String?
    var flightNumber: String? {
        didSet {
            if flightNumber!.characters.count > 4 {
                let index = flightNumber!.index(flightNumber!.startIndex, offsetBy: 2)
                flightNumber = flightNumber!.substring(from: index)
            }
        }
    }
    var departureAirport: String?
    var destinationAirport: String?
    var confirmation: String?
    var email: String?
    var datetime: String? {
        didSet {
            datetime = datetime!.replacingOccurrences(of: "T", with: " ")
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
