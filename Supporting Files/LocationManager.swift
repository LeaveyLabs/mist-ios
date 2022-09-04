//
//  LocationManager.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/2/22.
//

import Foundation
import MapKit

/// Notification on update of location. UserInfo contains CLLocation for key "location"
let kLocationDidChangeNotification = "LocationDidChangeNotification"

class LocationManager: NSObject, CLLocationManagerDelegate {

    static let Shared = LocationManager()

    private let geocoder = CLGeocoder()
    private var locationManager = CLLocationManager()

    var currentLocation : CLLocation?
    
    var authorizationStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    var currentLocationTitle: String?
    
    private override init () {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLLocationAccuracyHundredMeters
        
        //TODO: i might actually not wanna do the below
        self.locationManager.startUpdatingLocation()
    }
    
    //MARK: - Public Interface
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
    }
    

    // MARK: - CLLocationManagerDelegate
    
    //called upon creation of LocationManager and upon permission changes (either from within app or in settings)
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
        
        //TODO: post a custom notificaiton
    }
    
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        currentLocation = newLocation
//        let userInfo : NSDictionary = ["location" : currentLocation!]

        DispatchQueue.main.async {
//            NotificationCenter.default.post(name: kLocationDidChangeNotification, object: self, userInfo: userInfo as [NSObject : AnyObject])
        }
                
        geocoder.reverseGeocodeLocation(newLocation, preferredLocale: Locale(identifier: "en_US")) { (placemarks, error) in
            guard error == nil else { return }
//            self.currentLocationTitle = placemarks?.first?.name
        }
    }
    
    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LOCATION MANAGER DID FAIL W ERROR", error)
    }

}
