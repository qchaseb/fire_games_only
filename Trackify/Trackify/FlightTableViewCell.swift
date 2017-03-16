//
//  FlightTableViewCell.swift
//  Trackify
//
//  Created by Scott Buttinger on 2/6/17.
//  Copyright © 2017 Fire Apps Only. All rights reserved.
//

import UIKit

class FlightTableViewCell: UITableViewCell {
    
    // populates the table cell with flight information. Assumes that no fields in the flight
    // flight object are null
    var flight: Flight? {
        didSet {
            switch((flight?.airline)!) {
            case "Southwest": flightLogoImageView.image = #imageLiteral(resourceName: "southwest_logo")
            case "Southwest Airlines": flightLogoImageView.image = #imageLiteral(resourceName: "southwest_logo")
            case "Delta": flightLogoImageView.image = #imageLiteral(resourceName: "delta_logo")
            case "Delta Airlines": flightLogoImageView.image = #imageLiteral(resourceName: "delta_logo")
            case "United": flightLogoImageView.image = #imageLiteral(resourceName: "united_logo")
            case "United Airlines": flightLogoImageView.image = #imageLiteral(resourceName: "united_logo")
            case "American": flightLogoImageView.image = #imageLiteral(resourceName: "american_logo")
            case "American Airlines": flightLogoImageView.image = #imageLiteral(resourceName: "american_logo")
            case "Virgin America": flightLogoImageView.image = #imageLiteral(resourceName: "virgin_logo")
            case "Air Canada": flightLogoImageView.image = #imageLiteral(resourceName: "air_canada_logo")
            case "Alaska": flightLogoImageView.image = #imageLiteral(resourceName: "alaska_logo")
            case "Alaska Airlines": flightLogoImageView.image = #imageLiteral(resourceName: "alaska_logo")
            case "Spirit": flightLogoImageView.image = #imageLiteral(resourceName: "spirit_logo")
            case "Spirit Airlines": flightLogoImageView.image = #imageLiteral(resourceName: "spirit_logo")
            case "Frontier": flightLogoImageView.image = #imageLiteral(resourceName: "frontier_logo")
            case "Frontier Airlines": flightLogoImageView.image = #imageLiteral(resourceName: "frontier_logo")
            case "JetBlue": flightLogoImageView.image = #imageLiteral(resourceName: "jetblue_logo")
            case "JetBlue Airways": flightLogoImageView.image = #imageLiteral(resourceName: "jetblue_logo")
            case "Allegiant": flightLogoImageView.image = #imageLiteral(resourceName: "allegiant_logo")
            case "Allegiant Air": flightLogoImageView.image = #imageLiteral(resourceName: "allegiant_logo")
            case "Sun Country": flightLogoImageView.image = #imageLiteral(resourceName: "sun_country_logo")
            case "Sun Country Airlines": flightLogoImageView.image = #imageLiteral(resourceName: "sun_country_logo")
            case "Hawaiian": flightLogoImageView.image = #imageLiteral(resourceName: "hawaiian_logo")
            case "Hawaiian Airlines": flightLogoImageView.image = #imageLiteral(resourceName: "hawaiian_logo")
            default:flightLogoImageView.image = #imageLiteral(resourceName: "southwest_logo")
            }
            
            timeLabel.text = flight?.getTimeString()
            dateLabel.text = flight?.getDateString()
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
}
