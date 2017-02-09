//
//  FlightTableViewCell.swift
//  Trackify
//
//  Created by Scott Buttinger on 2/6/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit

class FlightTableViewCell: UITableViewCell {
    
    var isExpanded: Bool?
    var isVisible: Bool?
    
    fileprivate var df = DateFormatter()
    

    // populates the table cell with flight information. Assumes that no fields in the flight
    // flight object are null
    var flight: Flight? {
        didSet {
            switch((flight?.airline)!) {
                case "Southwest": flightLogoImageView.image = #imageLiteral(resourceName: "southwest_logo")
                case "Delta": flightLogoImageView.image = #imageLiteral(resourceName: "delta_logo")
                case "United": flightLogoImageView.image = #imageLiteral(resourceName: "united_logo")
                case "American": flightLogoImageView.image = #imageLiteral(resourceName: "american_logo")
                default:flightLogoImageView.image = #imageLiteral(resourceName: "southwest_logo")
            }
            df.dateFormat = "MM-dd-yyyy HH:mm"
            flight?.date = df.date(from: (flight?.datetime)!)
            df.dateFormat = "h:mm a"
            timeLabel.text = df.string(from: (flight?.date)!)
            df.dateFormat = "MMMM dd, yyyy"
            dateLabel.text = df.string(from: (flight?.date)!)
            flightNumberLabel.text = "#" + (flight?.flightNumber!)!
            departureAirportLabel.text = flight?.departureAirport
            destinationAirportLabel.text = flight?.destinationAirport
        }
    }
    
    @IBOutlet weak var flightLogoImageView: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var flightNumberLabel: UILabel!
    @IBOutlet weak var departureAirportLabel: UILabel!
    @IBOutlet weak var destinationAirportLabel: UILabel!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
