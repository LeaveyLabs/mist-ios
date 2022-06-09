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
    @IBOutlet weak var zoomInButton: UIButton!
    @IBOutlet weak var zoomOutButton: UIButton!

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
    
    var isCameraFlyingOutAndIn: Bool = false
    var isCameraFlying: Bool = false {
        didSet {
            view.isUserInteractionEnabled = !isCameraFlying
        }
    }
    var modifyingMap: Bool = false
    var latitudeOffset: Double!
    
    //remove one of these three
    var prevZoomFactor: Int = 4
    var prevZoomWidth: Double!
    //when the pitch increases, zoomWidth's value increases
    var prevZoom: Double!
    //when pitch increases, zoom goes UP then down
    //when pitch decreases, zoom goes DOWN then up
    
    var postAnnotations = [PostAnnotation]() {
        willSet {
            mapView.removeAnnotations(postAnnotations)
        }
        didSet {
            mapView.addAnnotations(postAnnotations)
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
        
        postAnnotations = []
        setupMapButtons()
        setupMapView()
        setupLocationManager()
        blurStatusBar()

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
        isCameraFlying = true
        registerMapAnnotationViews()
        centerMapOnUSC()
        mapView.camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate,
                                     fromDistance: 4000,
                                     pitch: 20,
                                     heading: mapView.camera.heading)
        isCameraFlying = false
    }
    
    // NOTE: If you want to change the clustering identifier based on location, you should probably delink the annotationview and reuse identifier like below (watch the wwdc video again) so you can change the constructor of AnnotationViews/ClusterANnotationViews to include map height
    func registerMapAnnotationViews() {
        mapView.register(PostAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    }
    
    private func setupMapButtons() {
        userTrackingButton.layer.cornerRadius = 10
        userTrackingButton.layer.cornerCurve = .continuous
        applyShadowOnView(userTrackingButton)
        
        mapDimensionButton.isHighlighted = true
        mapDimensionButton.layer.cornerRadius = 10
        mapDimensionButton.layer.cornerCurve = .continuous
        applyShadowOnView(mapDimensionButton)
        
        zoomInButton.layer.cornerRadius = 10
        zoomInButton.layer.cornerCurve = .continuous
        applyShadowOnView(zoomInButton)
        
        zoomOutButton.layer.cornerRadius = 10
        zoomOutButton.layer.cornerCurve = .continuous
        applyShadowOnView(zoomOutButton)
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
    
    func blurStatusBar() {
        let blurryEffect = UIBlurEffect(style: .regular)
        let blurredStatusBar = UIVisualEffectView(effect: blurryEffect)
        blurredStatusBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurredStatusBar)
        blurredStatusBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        blurredStatusBar.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        blurredStatusBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        blurredStatusBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
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
        // Ideally: stop the camera. Otherwise, the camera might keep moving after moving to userlocation. But not sure how to do that
        
        if locationManager.authorizationStatus == .denied ||
            locationManager.authorizationStatus == .notDetermined {
            handleUserLocationPermissionRequest()
        } else {
            slowFlyTo(lat: mapView.userLocation.coordinate.latitude,
                      long: mapView.userLocation.coordinate.longitude,
                      incrementalZoom: false,
                      withDuration: cameraAnimationDuration,
                      completion: {_ in
                self.view.isUserInteractionEnabled = true //in case the user scrolled map before pressing
            })
        }
    }
    
    @IBAction func mapDimensionButtonDidPressed(_ sender: UIButton) {
        toggleMapDimension() {
            self.view.isUserInteractionEnabled = true //in case the user scrolled map before pressing
        }
    }
    
    @IBAction func zoomInButtonDidPressed(_ sender: UIButton) {
        zoomByAFactorOf(0.33) {
            self.view.isUserInteractionEnabled = true //in case the user scrolled map before pressing
        }
    }
    
    @IBAction func zoomOutButtonDidPressed(_ sender: UIButton) {
        zoomByAFactorOf(3) {
            self.view.isUserInteractionEnabled = true //in case the user scrolled map before pressing
        }
    }
    
}

//https://developer.apple.com/documentation/mapkit/mkmapviewdelegate
extension MapViewController: MKMapViewDelegate {
    
    // Updates after each view change is completed
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // When the camera flies out and in, it pauses between animations and this function is called. we need to wait to have it
        if isCameraFlying && !isCameraFlyingOutAndIn {
            isCameraFlying = false
        }
        if isCameraFlying && isCameraFlyingOutAndIn {
            isCameraFlyingOutAndIn = false //so that on the next call of regionDidChangeAnimated, aka when the camera is done flying back in, isCameraFlying will be set to false
            //note: this doesnt work for more than one chaining... for that. you'll have to set isCameraFlyingOutAndIn in the last animation block
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
        
        // If the mapView frame is moving but the camera isn't programatically flying
        // Aka: if the user zooms/pans the map
        // Alternatively: add a pan & pinch gesture to mapView
        if !isCameraFlying {
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
 
    //called upon creation of LocationManager and upon permission changes (either from within app or in settings)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        CustomSwiftMessages.showError(errorDescription: "Something went wrong")
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
    
    //Consider not letting "withDuration" be passed, but let it be calculated here when it's actually needed. the duration might change based on the zoomOut
    func slowFlyTo(lat: Double,
                   long: Double,
                   incrementalZoom: Bool,
                   withDuration duration: Double,
                   completion: @escaping (Bool) -> Void) {
        isCameraFlying = true
        var newCLLDistance: Double = 500
        let destination = CLLocationCoordinate2D(latitude: lat, longitude: long)
        if incrementalZoom {
            newCLLDistance = self.mapView.camera.centerCoordinateDistance / 3
        }
        let finalCamera = MKMapCamera(lookingAtCenter: destination,
                                         fromDistance: newCLLDistance,
                                         pitch: 50,
                                         heading: 0)
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: {
            self.mapView.camera = finalCamera
        }) { finished in
            completion(finished)
        }
    }
    
    //You could make this a for loop, where you create like 10 midpoints between the origin and destination, and animate between all of them
    func slowFlyOutAndIn(lat: Double,
                           long: Double,
                           withDuration duration: Double,
                           completion: @escaping (Bool) -> Void) {
        var finalDistance: Double = 500
        let destination = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let finalCamera = MKMapCamera(lookingAtCenter: destination,
                                         fromDistance: finalDistance,
                                         pitch: 50,
                                         heading: 0)
        
       
//        if !mapView.visibleMapRect.contains(MKMapPoint(destination)) {
        let currentLocation = mapView.camera.centerCoordinate
        let midwayPoint = currentLocation.geographicMidpoint(betweenCoordinates: [destination])
        let distanceBetween = currentLocation.distance(from: destination)
        let midwayDistance = mapView.camera.centerCoordinateDistance +  distanceBetween * 2
        let preRotationCamera = MKMapCamera(lookingAtCenter: midwayPoint,
                                            fromDistance: midwayDistance,
                                         pitch: 40,
                                         heading: 0)
        isCameraFlying = true
        isCameraFlyingOutAndIn = true
        UIView.animate(withDuration: duration*2,
                       delay: 0,
                       options: .curveEaseIn,
                       animations: {
            self.mapView.camera = preRotationCamera
        }) { _ in
            UIView.animate(withDuration: duration*2,
                           delay: 0.1,
                           options: .curveEaseOut,
                           animations: {
                self.mapView.camera = finalCamera
            }, completion: completion)
        }
        
    }
    
    func toggleMapDimension(_ completion: @escaping () -> Void) {
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
        isCameraFlying = true
        let rotationCamera = MKMapCamera(lookingAtCenter: mapView.camera.centerCoordinate,
                                         fromDistance: mapView.camera.centerCoordinateDistance,
                                         pitch: newPitch,
                                         heading: mapView.camera.heading)
        UIView.animate(withDuration: cameraAnimationDuration,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: {
            self.mapView.camera = rotationCamera
        }) { finished in
            completion()
        }
    }
    
    //This seems to work as good as it's gonna get... which is better than the slow fly in that it accounts
    //for coordinates located within, but then it cant
    func zoomInAsCloseAsPossibleOn(cluster: MKClusterAnnotation) {
        var clusterPoints = [MKMapPoint]()
        cluster.memberAnnotations.forEach { memberAnnotation in
            clusterPoints.append(MKMapPoint(memberAnnotation.coordinate))
        }
        
        //Center a candidate rect around the cluster
        let rectX = mapView.visibleMapRect.width
        let rectY = mapView.visibleMapRect.height
        var candidateRect = MKMapRect(origin: MKMapPoint(cluster.coordinate),
                                      size: mapView.visibleMapRect.size)
        candidateRect = candidateRect.offsetBy(dx: -rectX / 2,
                                               dy: -rectY / 2)
        
        //Shrink the canidate rect so it just fits the cluster points
        var isCandidateRectTooSmall = false
        while !isCandidateRectTooSmall {
            candidateRect = candidateRect.insetBy(dx: rectX/10, dy: rectY/10)
            clusterPoints.forEach { clusterPoint in
                if !candidateRect.contains(clusterPoint) {
                    isCandidateRectTooSmall = true
                }
            }
        }
        candidateRect = candidateRect.insetBy(dx: -rectX/10, dy: -rectY/10)
        let span = MKCoordinateRegion(candidateRect).span //could i use span to find the appropriate camera distance, then animate the camera? probably
        UIView.animate(withDuration: cameraAnimationDuration,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: {
            self.mapView.visibleMapRect = candidateRect
        }, completion: nil)
    }
    
    func zoomByAFactorOf(_ factor: Double, _ completion: @escaping () -> Void) {
        isCameraFlying = true
        let newDistance = mapView.camera.centerCoordinateDistance * factor
        let newPitch = min(mapView.camera.pitch, 30) //I use 30 instead of 50 just to add the extra pitch transition to make it more dnamic when zooming out
        //Note: you have to actually set a newPitch value like above. It seems that if you use the old pitch value for rotationCamera, sometimes the camera won't actually be changed for some reason
        let rotationCamera = MKMapCamera(lookingAtCenter: mapView.camera.centerCoordinate,
                                         fromDistance: newDistance,
                                         pitch: newPitch,
                                         heading: mapView.camera.heading)
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: {
            self.mapView.camera = rotationCamera
        }) { finished in
            completion()
        }
    }
    
    func deselectOneAnnotationIfItExists() {
        if mapView.selectedAnnotations.count > 0 {
            print("deselecting one because it exists")
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

//MARK: - PreventAnnotationViewInteractionDelay

//This code is needed on the Map
extension MapViewController {
    
    // AnnotationQuickSelect: 1 of 3
    // Allows for noticeably faster zooms to the annotationview
    // Turns isZoomEnabled off and on immediately before and after a click on the map.
    // This means that in case the tap happened to be on an annotation, there's less delay.
    // Downside: double tap features are not possible
    //https://stackoverflow.com/questions/35639388/tapping-an-mkannotation-to-select-it-is-really-slow
    func setupGestureRecognizerToPreventInteractionDelay() {
        let quickSelectGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleMapTapForAnnotationQuickSelect(_:)))
        quickSelectGestureRecognizer.numberOfTapsRequired = 1
        quickSelectGestureRecognizer.numberOfTouchesRequired = 1
        mapView.addGestureRecognizer(quickSelectGestureRecognizer)
    }

    // AnnotationQuickSelect: 2 of 3
    @objc func handleMapTapForAnnotationQuickSelect(_ sender: UITapGestureRecognizer? = nil) {
        //disabling zoom, so the didSelect triggers immediately
        mapView.isZoomEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mapView.isZoomEnabled = true // in case the tap was not an annotation
        }
    }
    
}
