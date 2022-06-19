
/*
From apple

Abstract:
A utility file to provide icons for point-of-interest categories.
*/

import Foundation
import MapKit

extension MKPointOfInterestCategory {
    
    static let travelPointsOfInterest: [MKPointOfInterestCategory] = [.bakery, .brewery, .cafe, .restaurant, .winery, .hotel]
    static let defaultSymbolUIImage = UIImage(systemName: "mappin.and.ellipse")!
    
    var symbolUIImage: UIImage {
        switch self {
        case .airport:
            return UIImage(systemName: "airplane")!
        case .atm, .bank:
            return UIImage(systemName: "banknote")!
        case .brewery, .winery, .restaurant:
            return UIImage(systemName: "fork.knife")!
        case .nightlife:
            return UIImage(systemName: "moon")!
        case .foodMarket, .store:
            return UIImage(systemName: "cart")!
        case .bakery, .cafe:
            return UIImage(systemName: "cup.and.saucer")!
        case .campground, .hotel:
            return UIImage(systemName: "bed.double")!
        case .pharmacy:
            return UIImage(systemName: "pills")!
        case .carRental, .gasStation:
            return UIImage(systemName: "car")!
        case .evCharger:
            return UIImage(systemName: "bolt.car")!
        case .laundry, .store:
            return UIImage(systemName: "tshirt")!
        case .university, .school:
            return UIImage(systemName: "graduationcap")!
        case .library:
            return UIImage(systemName: "book")!
        case .parking:
            return UIImage(systemName: "p.circle")!
        case .theater:
            return UIImage(systemName: "theatermasks")!
        case .marina:
            return UIImage(systemName: "ferry")!
        case .museum:
            return UIImage(systemName: "building.columns")!
        case .nationalPark, .park:
            return UIImage(systemName: "leaf")!
        case .postOffice:
            return UIImage(systemName: "envelope")!
        case .publicTransport:
            return UIImage(systemName: "bus")!
        default:
            return UIImage(systemName: "mappin.and.ellipse")!
        }
    }
}
