//
//  SavedUser+CoreDataClass.swift
//  Trackify
//
//  Created by Scott Buttinger on 2/19/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import Foundation
import CoreData


public class SavedUser: NSManagedObject {
    class func addSignedInUser(_ emailAddress: String, firstName: String, lastName: String, password:String, inManagedObjectContext context: NSManagedObjectContext) {
        // set the new signed in user
        if let user = NSEntityDescription.insertNewObject(forEntityName: "SavedUser", into: context) as? SavedUser {
            user.emailAddress = emailAddress
            user.firstName = firstName
            user.lastName = lastName
            user.password = password
        }
    }
}
