/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The custom MKAnnotation object representing the Golden Gate Bridge.
*/

import UIKit
import MapKit

class PostAnnotation: NSObject, MKAnnotation, Comparable {
    
    // This property must be key-value observable, which the `@objc dynamic` attributes provide.
    @objc dynamic var coordinate: CLLocationCoordinate2D
    
    // Title is required if you set the annotation view's `canShowCallout` property to `true`
    var title: String?
    var post: Post!
    
    init(withPost post: Post) {
        self.post = post
        self.title = post.title
        self.coordinate = CLLocationCoordinate2D(latitude: post.latitude!, longitude: post.longitude!)
        super.init()
    }
    
    init(justWithCoordinate coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
    
    static func < (lhs: PostAnnotation, rhs: PostAnnotation) -> Bool {
        let firstLocation = CLLocation(latitude: lhs.coordinate.latitude, longitude: lhs.coordinate.longitude)
        let secondLocation = CLLocation(latitude: rhs.coordinate.latitude, longitude: rhs.coordinate.longitude)
        let origin = CLLocation(latitude: 0, longitude: 0)
        return firstLocation.distance(from: origin) < secondLocation.distance(from: origin)
    }
}
