/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Custom pin annotation for display found places.
*/

import MapKit

class PlaceAnnotation: NSObject, MKAnnotation {
    
    /*
    This property is declared with `@objc dynamic` to meet the API requirement that the coordinate property on all MKAnnotations
    must be KVO compliant.
     */
    @objc dynamic var coordinate: CLLocationCoordinate2D
    
    var title: String?
    var category: MKPointOfInterestCategory?
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
    
    init(withPlace place: MKMapItem) {
        self.coordinate = place.placemark.coordinate
        self.title = place.placemark.name
        self.category = place.pointOfInterestCategory
        super.init()
    }
    
}
