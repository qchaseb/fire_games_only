//
//  User.swift
//  Trackify
//
//  Created by Scott Buttinger on 2/2/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import Foundation
import AWSDynamoDB

class User : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    var email_id:String?
    var first_name:String?
    var last_name:String?
    var password:String?
    
    class func dynamoDBTableName() -> String {
        return "TrackifyDevDB"
    }
    
    class func hashKeyAttribute() -> String {
        return "email_id"
    }
}
