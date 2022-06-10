
/*
From apple

Abstract:
A utility file to provide icons for point-of-interest categories.
*/

import Foundation
import MapKit

extension MKPointOfInterestCategory {
    
    static let travelPointsOfInterest: [MKPointOfInterestCategory] = [.bakery, .brewery, .cafe, .restaurant, .winery, .hotel]
    static let defaultSymbolName = "mappin.and.ellipse"
    
    var symbolName: String {
        switch self {
        case .airport:
            return "airplane"
        case .atm, .bank:
            return "banknote"
        case .brewery, .winery, .restaurant:
            return "fork.knife"
        case .nightlife:
            return "moon"
        case .foodMarket, .store:
            return "cart"
        case .bakery, .cafe:
            return "cup.and.saucer"
        case .campground, .hotel:
            return "bed.double"
        case .pharmacy:
            return "pills"
        case .carRental, .gasStation:
            return "car"
        case .evCharger:
            return "bolt.car"
        case .laundry, .store:
            return "tshirt"
        case .university, .school:
            return "graduationcap"
        case .library:
            return "book"
        case .parking:
            return "p.circle"
        case .theater:
            return "theatermasks"
        case .marina:
            return "ferry"
        case .museum:
            return "building.columns"
        case .nationalPark, .park:
            return "leaf"
        case .postOffice:
            return "envelope"
        case .publicTransport:
            return "bus"
        default:
            return MKPointOfInterestCategory.defaultSymbolName
        }
    }
}
