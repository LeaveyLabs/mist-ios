//
//  ExploreViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit
import SwiftMessages

//todos / problems:
//TODO: cluster annotation bounce on deselect even its deselect is animated: false?
//TODO: add a jab to the user when clicking on current location. it seems like "title" no longer works
//TODO: setting the clusters to hotspots after zooming in closer enough isnt working quite right
//TODO: automatically reduce the pitch to flatten the map while zooming out
//TODO: (probably not possible) only render cluster views when you get close enough
    //IDEA: instead of trying to change the title of the cluster view at a certain width, you could just...
    //when someone clicks on a cluster view, you zoom in on it, and if that zoom is close enough, then send them to the feed page

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var userTrackingButton: UIButton!
    @IBOutlet weak var mapDimensionButton: UIButton!
    
    private var isThreeDimensional:Bool = true {
        didSet {
            if isThreeDimensional {
                mapDimensionButton.setTitle("2D", for: .normal)
            } else {
                mapDimensionButton.setTitle("3D", for: .normal)
            }
        }
    }
    
    // Create a location manager to trigger user tracking
    private let locationManager = CLLocationManager()
    
    var cameraIsFlying: Bool = false
    var modifyingMap: Bool = false
    var latitudeOffset: Double!
    
    //remove one of these three
    var prevZoomFactor: Int = 4
    var prevZoomWidth: Double!
    //when the pitch increases, zoomWidth's value increases
    var prevZoom: Double!
    //when pitch increases, zoom goes UP then down
    //when pitch decreases, zoom goes DOWN then up
    
    var displayedAnnotations = [PostAnnotation]() {
        willSet {
            mapView.removeAnnotations(displayedAnnotations)
        }
        didSet {
            mapView.addAnnotations(displayedAnnotations)
        }
    }
    
    var cameraAnimationDuration: Double {
        //add up to 0.3 seconds to rotate the heading of the camera
        return Double(prevZoomFactor+2)/10 + ((180-fabs(180.0 - mapView.camera.heading)) / 180 * 0.3)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize variables
        prevZoomWidth = mapView.visibleMapRect.size.width
        prevZoom = mapView.camera.centerCoordinateDistance
        
        displayedAnnotations = []
        setupMapButtons()
        setupMapView()
        setupLocationManager()

        applyGradientUnderneathNavbar()
    }
    
    // MARK: - Setup
    
    func setupMapView() {
        // GENERAL SETTINGS
        mapView.cameraZoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 310) // Note: this creates an effect where, when the camera is pretty zoomed in, if you try to increase the pitch past a certian point, it automatically zooms in more. Not totally sure why. This is slightly undesirable but not that deep
        //310 is range from which you view a post, that way you cant zoom in more afterwards
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.delegate = self
        mapView.tintColor = .systemBlue //sets user puck color
        mapView.showsTraffic = false
        
        // POINTS OF INTEREST
        //including categories is more ideal, bc there are some markers like "shared bikes" which wont be excluded no matter what
        let includeCategories:[MKPointOfInterestCategory] = [.cafe, .airport, .amusementPark, .aquarium, .bakery, .beach, .brewery, .campground, .foodMarket, .fitnessCenter, .hotel, .hospital, .library, .marina, .movieTheater, .museum, .nationalPark, .nightlife, .park, .pharmacy, .postOffice, .restaurant, .school, .stadium, .store, .theater, .university, .zoo, .winery]
        mapView.pointOfInterestFilter = .some(MKPointOfInterestFilter(including: includeCategories))
        
        // CAMERA
        cameraIsFlying = true
        registerMapAnnotationViews()
        centerMapOnUSC()
        mapView.camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate,
                                     fromDistance: 4000,
                                     pitch: 20,
                                     heading: mapView.camera.heading)
        cameraIsFlying = false
    }
    
    // NOTE: If you want to change the clustering identifier based on location, you should probably delink the annotationview and reuse identifier like below (watch the wwdc video again) so you can change the constructor of AnnotationViews/ClusterANnotationViews to include map height
    func registerMapAnnotationViews() {
        mapView.register(PostAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    }
    
    private func setupMapButtons() {
        // For more customizaiton later on: https://stackoverflow.com/questions/27029854/custom-button-to-track-mkusertrackingmode
        userTrackingButton.layer.cornerRadius = 10
        userTrackingButton.layer.cornerCurve = .continuous
        applyShadowOnView(userTrackingButton)
        
        mapDimensionButton.isHighlighted = true
        mapDimensionButton.layer.cornerRadius = 10
        mapDimensionButton.layer.cornerCurve = .continuous
        applyShadowOnView(mapDimensionButton)
    }
    
    func handleUserLocationPermissionRequest() {
        if locationManager.authorizationStatus == .denied ||
            locationManager.authorizationStatus == .notDetermined { //this check should also exist here for when the function is called after registering/logging in
            
            CustomSwiftMessages.showPermissionRequest(permissionType: .userLocation, onApprove: { [weak self] in //TODO: should this not be weak?
                if self?.locationManager.authorizationStatus == .notDetermined {
                    self?.locationManager.requestWhenInUseAuthorization()
                } else {
                    CustomSwiftMessages.showSettingsAlertController(title: "Turn on location services for \"Mist\" in Settings.", message: "", on: self!)
                }
            })
        }
    }
    
    private func setupLocationManager(){
        locationManager.delegate = self
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
        if locationManager.authorizationStatus == .denied ||
            locationManager.authorizationStatus == .notDetermined {
            handleUserLocationPermissionRequest()
        } else {
            slowFlyTo(lat: mapView.userLocation.coordinate.latitude,
                      long: mapView.userLocation.coordinate.longitude,
                      incrementalZoom: false,
                      withDuration: cameraAnimationDuration, completion: {_ in })
        }
    }
    
    @IBAction func mapDimensionButtonDidPressed(_ sender: UIButton) {
        toggleMapDimension()
    }
    
}

//https://developer.apple.com/documentation/mapkit/mkmapviewdelegate
extension MapViewController: MKMapViewDelegate {
    
    //updates after each view change is completed
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if (cameraIsFlying) {
            cameraIsFlying = false //so that when the user starts dragging again, the post will disappear
        }
    }
    
    //OOOOH This could be useful, i'm not using this function at all up until now
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
    }

    //updates continuously throughout user drag
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let zoomWidth = mapView.visibleMapRect.size.width
        let zoomFactor = Int(log2(zoomWidth)) - 9
        let zoom = mapView.camera.centerCoordinateDistance //centerCoordinateDistance takes pitch into account
        
//        print("zoom: " + String(zoom))
//        print("zoomWidth: " + String(zoomWidth))
        
        // Limit minimum pitch. Doing this because of weird behavior with clicking on posts from a pitch less than 50
        if mapView.camera.pitch > 50 && !modifyingMap {
            modifyingMap = true
            mapView.camera.pitch = 50
            modifyingMap = false
        }
        
        // Automatically reduce the pitch while zooming out
        //once i click on post, or when i click 2d/3d button, this just stops working
        //this is also called incorrectly when youre roughly 1000 distance away and you manually adjust the pitch (since adjusting pitch also adjusts zoom)
//        if zoom > 1000 && prevZoom < 1000 && !modifyingMap && !cameraIsFlying {
//            print("REDUCE PITCH")
//            modifyingMap = true
////            mapView.camera.pitch = 0
//            mapView.camera = MKMapCamera(lookingAtCenter: mapView.camera.centerCoordinate,
//                                         fromDistance: mapView.camera.centerCoordinateDistance,
//                                         pitch: 0,
//                                         heading: mapView.camera.heading)
//            //try setting the whole camera to something new?
//            modifyingMap = false
//        }
        
        // Deselect selected annotation upon moving
        if !cameraIsFlying {
            deselectOneAnnotationIfItExists()
        }
        
        // Toggle text of 3d button
        isThreeDimensional = mapView.camera.pitch != 0
        
        //RIP This is still not working 100%... oh well i'll fix it later
        // Toggle cluster hotspot, 1 of 2
        // Updates all clusters already rendered
        for annotation in mapView.annotations {
            if let clusterAnnotation = annotation as? MKClusterAnnotation {
                clusterAnnotation.updateIsHotspot(cameraDistance: mapView.camera.centerCoordinateDistance)
            }
        }
        
        prevZoomFactor = zoomFactor
        prevZoomWidth = zoomWidth
        prevZoom = zoom
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
 
    //called upon creationg of LocationManager and upon permission changes (either from within app or in settings)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
}
    
extension MapViewController {

    //MARK: - Helpers
    
    func centerMapOnUSC() {
        let region = mapView.regionThatFits(MKCoordinateRegion(center: Constants.Coordinates.USC, latitudinalMeters: 1200, longitudinalMeters: 1200))
        mapView.setRegion(region, animated: true)
    }
    
    func centerMapOn(lat: Double, long: Double) {
        let newCamera = MKMapCamera(lookingAtCenter: CLLocationCoordinate2D.init(latitude: lat, longitude: long), fromDistance: mapView.camera.centerCoordinateDistance, pitch: 50, heading: 0)
        mapView.camera = newCamera
    }
    
    // Custom camera transition https://stackoverflow.com/questions/21125573/mkmapcamera-pitch-altitude-function
    func slowFlyTo(lat: Double,
                   long: Double,
                   incrementalZoom: Bool,
                   withDuration duration: Double,
                   completion: @escaping (Bool) -> Void) {
        let pinLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        var newCLLDistance: Double = 500
        if incrementalZoom {
            // TODO: Handle conditions to zoom in based on how zoomed in the camera already is
            newCLLDistance = mapView.camera.centerCoordinateDistance / 3
        }

        let rotationCamera = MKMapCamera(lookingAtCenter: pinLocation, fromDistance: newCLLDistance, pitch: 50, heading: 0)
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.mapView.camera = rotationCamera
        }, completion: completion)
        cameraIsFlying = true
    }
        
    func toggleMapDimension() {
        isThreeDimensional = !isThreeDimensional
        
        // Prepare the new pitch based on the new value of isThreeDimensional
        var newPitch: Double
        if isThreeDimensional {
            newPitch = 50.0
        } else {
            newPitch = 0.0
        }
        
        //setting to 2d doesnt do animation but just SNAPS sometimes,
        //this only happens when zoomed in too close
        
        //OOOH:: i think the reason why is because the centercoordinatedistance also changes with a new pitch
        //this error only happens when going from 3D to 2D
        //so the CCDDistance is decreasing unintentionally
        
        // Update the camera
        cameraIsFlying = true
        let rotationCamera = MKMapCamera(lookingAtCenter: mapView.camera.centerCoordinate,
                                         fromDistance: mapView.camera.centerCoordinateDistance,
                                         pitch: newPitch,
                                         heading: mapView.camera.heading)
        UIView.animate(withDuration: cameraAnimationDuration,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: {
            self.mapView.camera = rotationCamera
        },
                       completion: nil)
    }
    
    func deselectOneAnnotationIfItExists() {
        if mapView.selectedAnnotations.count > 0 {
            mapView.deselectAnnotation(mapView.selectedAnnotations[0], animated: true)
        }
    }
    
    func deselectAllAnnotations() {
        for annotation in mapView.annotations {
            mapView.deselectAnnotation(annotation, animated: true)
        }
    }
    
    func reselectOneAnnotationIfItExists() {
        if mapView.annotations.count > 1 {
            for annotation in mapView.annotations {
                if annotation .isKind(of: MKUserLocation.self) == false {
                    print("trying to reselect a non user annotation")
                    mapView.selectAnnotation(mapView.annotations[1], animated: true)
                    return
                }
            }
        }
    }
}
