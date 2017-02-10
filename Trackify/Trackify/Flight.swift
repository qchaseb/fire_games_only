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
    var flightNumber: String?
    var departureAirport: String?
    var destinationAirport: String?
    var confirmation: String?
    var email: String?
    var datetime: String? {
        didSet {
            df.dateFormat = "MM-dd-yyyy HH:mm"
            self.date = df.date(from: datetime!)
            df.dateFormat = "h:mm a"
            self.timeString = df.string(from: self.date!)
            df.dateFormat = "MMMM d, yyyy"
            self.dateString = df.string(from: self.date!)
        }
    }
        
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
