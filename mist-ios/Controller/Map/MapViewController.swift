//
//  ExploreViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit

//problems:
//TODO: cluster annotation bounce on deselect even its deselect is animated: false?
//TODO: add a jab to the user when clicking on current location. it seems like "title" no longer works
//TODO: setting the clusters to hotspots after zooming in closer enough isnt working quite right

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var userTrackingButton: UIButton!
    
    // Create a location manager to trigger user tracking
    private let locationManager = CLLocationManager()
    
    var mapModal: MapModalViewController?
    var postIsBeingRendered: Bool = false
    var modifyingMap: Bool = false
    var latitudeOffset: Double!
    
    //remove one of these three
    var prevZoomFactor: Int = 4
    var prevZoomWidth: Double!
    var prevZoom: Double!
    
    var displayedAnnotations = [PostAnnotation]() {
        willSet {
            mapView.addAnnotations(displayedAnnotations)
        }
        didSet {
            mapView.addAnnotations(displayedAnnotations)
        }
    }
    
    
    var cameraAnimationDuration: Double {
        return Double(prevZoomFactor+2)/10 + ((180-fabs(180.0 - mapView.camera.heading)) / 180 * 0.3) //add up to 0.3 seconds to rotate the heading of the camera
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.restoreHairline()
        displayedAnnotations = []
        setupMapButtons()
        setupMapView()
        setupLocationManager()
        applyGradientUnderneathNavbar()
    }
    
    // MARK: - Setup
    
    func setupMapView() {
        mapView.delegate = self
        mapView.tintColor = .systemBlue //sets user puck color
        centerMapOnUSC()
        registerMapAnnotationViews()
        
        // Set iniital camera pitch (aka camera angle)
        mapView.camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: 4000, pitch: 20, heading: mapView.camera.heading)
        prevZoomWidth = mapView.visibleMapRect.size.width
        prevZoom = mapView.camera.centerCoordinateDistance
        
        //including categories is more ideal, bc there are some markers like "shared bikes" which wont be excluded no matter what
        let includeCategories:[MKPointOfInterestCategory] = [.cafe, .airport, .amusementPark, .aquarium, .bakery, .beach, .brewery, .campground, .foodMarket, .fitnessCenter, .hotel, .hospital, .library, .marina, .movieTheater, .museum, .nationalPark, .nightlife, .park, .pharmacy, .postOffice, .restaurant, .school, .stadium, .store, .theater, .university, .zoo, .winery]
        mapView.pointOfInterestFilter = .some(MKPointOfInterestFilter(including: includeCategories))
    }
    
    // NOTE: If you want to change the clustering identifier based on location, you should probably delink the annotationview and reuse identifier like below (watch the wwdc video again) so you can change the constructor of AnnotationViews/ClusterANnotationViews to include map height
    func registerMapAnnotationViews() {
        mapView.register(PostMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    }
    
    private func setupMapButtons() {
        // For more customizaiton later on: https://stackoverflow.com/questions/27029854/custom-button-to-track-mkusertrackingmode
        userTrackingButton.layer.cornerRadius = 10
        userTrackingButton.layer.cornerCurve = .continuous
        applyShadowOnView(userTrackingButton)
    }
    
    private func setupLocationManager(){
        mapView.showsUserLocation = true
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func applyGradientUnderneathNavbar() {
        // Folllow this code next time: https://stackoverflow.com/questions/34269399/how-to-control-shadow-spread-and-blur
        
//        let gradient: CAGradientLayer = CAGradientLayer()
//        gradient.colors = [UIColor.gray.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.white.cgColor]
//        gradient.locations = [0.0 , 1.0, 2.0, 3.0]
//        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
//        gradient.endPoint = CGPoint(x: 0.0, y: 3.0)
//        gradient.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: mapView.frame.size.height / 3)
//        gradient.opacity = 0.3
////        mapView.layer.insertSublayer(gradient, at: 1)
//
//        var gradientView = UIView(frame: CGRect(x: 0, y: 0, width: mapView.frame.size.width, height: mapView.frame.size.height / 3))
//        let gradientLayer:CAGradientLayer = CAGradientLayer()
//        gradientLayer.frame.size = gradientView.frame.size
//        gradientLayer.colors = [UIColor.black.cgColor,UIColor.white.cgColor]
//        gradientLayer.opacity = 0.2
//        gradientView.layer.addSublayer(gradientLayer)
//        mapView.addSubview(gradientView)

    }

    
    //MARK: - User Interaction
    
    @IBAction func userTrackingButtonDidPressed(_ sender: UIButton) {
        slowFlyTo(lat: mapView.userLocation.coordinate.latitude, long: mapView.userLocation.coordinate.longitude, incrementalZoom: false, completion: {_ in })
    }
    
}

//https://developer.apple.com/documentation/mapkit/mkmapviewdelegate
extension MapViewController: MKMapViewDelegate {
    
    //updates after each view change is completed
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if (postIsBeingRendered) {
            postIsBeingRendered = false //so that when the user starts dragging again, the post will disappear
        }
    }

    //updates continuously throughout user drag
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        
        // Limit max zoom https://stackoverflow.com/questions/1636868/is-there-way-to-limit-mkmapview-maximum-zoom-level
        if (mapView.camera.centerCoordinateDistance < 400 && !modifyingMap) {
            modifyingMap = true
            mapView.camera.centerCoordinateDistance = 400
            modifyingMap = false
        }
        
        // Limit minimum pitch. Doing this because of weird behavior with clicking on posts from a pitch less than 50
        if (mapView.camera.pitch > 50 && !modifyingMap) {
            modifyingMap = true
            mapView.camera.pitch = 50
            modifyingMap = false
        }
        
        // Deselect selected annotation.
        if !postIsBeingRendered {
            if (mapView.selectedAnnotations.count > 0) {
                mapView.deselectAnnotation(mapView.selectedAnnotations[0], animated: true)
            }
        }
        
        
        let zoomWidth = mapView.visibleMapRect.size.width
        let zoomFactor = Int(log2(zoomWidth)) - 9
        let zoom = mapView.camera.centerCoordinateDistance
        
        prevZoomFactor = zoomFactor
        prevZoomWidth = zoomWidth
        prevZoom = zoom
        
        
        //RIP This is still not working 100%... oh well i'll fix it later
        // Toggle cluster hotspot, 1 of 2
        // Updates all clusters already rendered
        for annotation in mapView.annotations {
            if let clusterAnnotation = annotation as? MKClusterAnnotation {
                clusterAnnotation.updateIsHotspot(cameraDistance: mapView.camera.centerCoordinateDistance)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Toggle cluster hotspot, 2 of 2
        // Updates new clusters created if user zooms in even more after already rendered clusters are udpated
        // This can't go into MKClusterAnnotation because it depends on the camera distance
        if let clusterAnnotation = annotation as? MKClusterAnnotation {
            clusterAnnotation.updateIsHotspot(cameraDistance: mapView.camera.centerCoordinateDistance)
        }
        return nil
    }
}

extension MapViewController: CLLocationManagerDelegate {
 
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let locationAuthorized = status == .authorizedWhenInUse
        userTrackingButton.isHidden = !locationAuthorized
    }
}
    
extension MapViewController {

    //MARK: - Helpers
    
    func centerMapOnUSC() {
        let region = mapView.regionThatFits(MKCoordinateRegion(center: Constants.USC_LAT_LONG, latitudinalMeters: 1200, longitudinalMeters: 1200))
        mapView.setRegion(region, animated: true)
    }
    
    func centerMapOn(lat: Double, long: Double) {
        let newCamera = MKMapCamera(lookingAtCenter: CLLocationCoordinate2D.init(latitude: lat, longitude: long), fromDistance: mapView.camera.centerCoordinateDistance, pitch: 50, heading: 0)
        mapView.camera = newCamera
    }
    
    // Custom camera transition https://stackoverflow.com/questions/21125573/mkmapcamera-pitch-altitude-function
    func slowFlyTo(lat: Double, long: Double, incrementalZoom: Bool, completion: @escaping (Bool) -> Void) {
        let pinLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        var newCLLDistance: Double = 500
        if incrementalZoom {
            // TODO: Handle conditions to zoom in based on how zoomed in the camera already is
            newCLLDistance = mapView.camera.centerCoordinateDistance / 3
        }

        let rotationCamera = MKMapCamera(lookingAtCenter: pinLocation, fromDistance: newCLLDistance, pitch: 50, heading: 0)
        UIView.animate(withDuration: cameraAnimationDuration, delay: 0, options: .curveEaseInOut, animations: {
            self.mapView.camera = rotationCamera
        }, completion: completion)
        postIsBeingRendered = true
    }
}
