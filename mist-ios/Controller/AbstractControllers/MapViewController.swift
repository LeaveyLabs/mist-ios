//
//  ExploreViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit
import SwiftMessages
import FirebaseCore
import FirebaseAnalytics

//override UIColor {
//    override var systemBrown
//    @property (class, nonatomic, readonly) UIColor *systemBrownColor        API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);

    
//}

class MapViewController: UIViewController {
    
    //MARK: - Properties

    // UI
    @IBOutlet weak var mapView: MyMapView!
    @IBOutlet weak var userTrackingButton: UIButton!
    @IBOutlet weak var mapDimensionButton: UIButton!
    @IBOutlet weak var trackingDimensionStackView: UIStackView!
    @IBOutlet weak var zoomSlider: TapUISlider!
    
    // User location
    let locationManager = CLLocationManager()
    
    // Camera
    static let STARTING_ZOOM_DISTANCE: Double = 3000
    static let MIN_CAMERA_DISTANCE: Double = 500
    var maxCameraPitch: Double = 20
//    static let MIN_CAMERA_PITCH: Double = 0 //not implemented yet
    static let ANNOTATION_ZOOM_THRESHOLD: Double = STARTING_ZOOM_DISTANCE + 200
    let minSpanDelta = 0.02
    var isCameraFlyingOutAndIn: Bool = false
    var isCameraFlying: Bool = false {
        didSet {
            mapView.isUserInteractionEnabled = !isCameraFlying
        }
    }
    
    var isCameraZooming: Bool = false
    var modifyingMap: Bool = false
    var latitudeOffsetForOneKMDistance: Double = 0.00133
    //remove one of these three
    var prevZoomFactor: Int = 4
    var prevZoomWidth: Double! //when the pitch increases, zoomWidth's value increases
    var prevZoom: Double! //when pitch increases, zoom goes UP then down. when pitch decreases, zoom goes DOWN then up
    private var isThreeDimensional:Bool = true {
        didSet {
            if isThreeDimensional {
                mapDimensionButton.setTitle("2D", for: .normal)
            } else {
                mapDimensionButton.setTitle("3D", for: .normal)
            }
        }
    }
    var cameraAnimationDuration: Double {
        //add up to 0.3 seconds to rotate the heading of the camera
        return Double(prevZoomFactor+2)/10 + ((180-fabs(180.0 - mapView.camera.heading)) / 180 * 0.3)
    }
    
    //Annotations
    var placeAnnotations = [PlaceAnnotation]()
    var postAnnotations = [PostAnnotation]()
    
    var mapViewLegalLabelYOffset: Double = 90
    
    
    //MARK: - View Lifecycle
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize variables
        prevZoomWidth = mapView.visibleMapRect.size.width
        prevZoom = mapView.camera.centerCoordinateDistance
        setupMapButtons()
        setupMapView()
        setupLocationManager()
        setupZoomSlider()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moveMapLegalLabel()
    }
    
    // MARK: - Setup
    
    @IBOutlet weak var zoomSliderGradientImageView: UIImageView!
    func setupZoomSlider() {
        zoomSlider.transform = CGAffineTransform(rotationAngle: -.pi/2)
        zoomSlider.value = currentZoomSliderValue
        zoomSlider.addTarget(self, action: #selector(onZoomSlide(slider:event:)), for: .valueChanged)
        zoomSlider.trackRectWidth = 4
        zoomSlider.thumbRectHorizontalOffset = -19
        zoomSliderGradientImageView.alpha = 0.5
        zoomSliderGradientImageView.applyMediumShadow()
        zoomSlider.setThumbImage(UIImage(named: "thumb"), for: .normal)
        zoomSlider.setThumbImage(UIImage(named: "thumb"), for: .highlighted)
    }
    
    var currentZoomSliderValue: Float = 3
    @objc func onZoomSlide(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                self.zoomSlider.maximumTrackTintColor = .clear
                self.zoomSlider.minimumTrackTintColor = .clear
                UIView.animate(withDuration: 0.3, delay: 0) {
                    self.zoomSliderGradientImageView.alpha = 1
                    self.zoomSlider.alpha = 1
                }
                isCameraZooming = true
                handleZoomSliderValChange(previousZoom: currentZoomSliderValue, newZoom: zoomSlider.value)
                break
            case .moved:
                handleZoomSliderValChange(previousZoom: currentZoomSliderValue, newZoom: zoomSlider.value)
            case .ended:
                UIView.animate(withDuration: 0.3) {
                    self.zoomSliderGradientImageView.alpha = 0
                    self.zoomSlider.alpha = 0.02
                } completion: { completed in
                    self.zoomSlider.minimumTrackTintColor = .white
                    self.zoomSlider.maximumTrackTintColor = .white
                }
                handleZoomSliderValChange(previousZoom: currentZoomSliderValue, newZoom: zoomSlider.value)
                isCameraZooming = false
            default:
                break
            }
        }
        currentZoomSliderValue = zoomSlider.value
    }
    
    func handleZoomSliderValChange(previousZoom: Float, newZoom: Float) {
        mapView.camera.centerCoordinateDistance += Double(previousZoom - newZoom) * mapView.camera.centerCoordinateDistance * 2
    }
    
    func moveMapLegalLabel() {
        mapView.subviews.first { "\(type(of: $0))" == "MKAttributionLabel" }?.frame.origin.y = mapView.frame.maxY + 4.0 - mapViewLegalLabelYOffset
        mapView.subviews.first { "\(type(of: $0))" == "MKAttributionLabel" }?.frame.origin.x = 66.0
        mapView.subviews.first { "\(type(of: $0))" == "MKAppleLogoImageView" }?.frame.origin.y = mapView.frame.maxY - mapViewLegalLabelYOffset - 1
    }
    
    func setupMapView() {
        // GENERAL SETTINGS
        mapView.tintColor = Constants.Color.mistPurple
        mapView.cameraZoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: MapViewController.MIN_CAMERA_DISTANCE) // Note: this creates an effect where, when the camera is pretty zoomed in, if you try to increase the pitch past a certian point, it automatically zooms in more. Not totally sure why. This is slightly undesirable but not that deep
        //310 is range from which you view a post, that way you cant zoom in more afterwards
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.delegate = self
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
                                     fromDistance: MapViewController.STARTING_ZOOM_DISTANCE,
                                     pitch: maxCameraPitch,
                                     heading: mapView.camera.heading)
        isCameraFlying = false
    }
    
    // NOTE: If you want to change the clustering identifier based on location, you should probably delink the annotationview and reuse identifier like below (watch the wwdc video again) so you can change the constructor of AnnotationViews/ClusterANnotationViews to include map height
    func registerMapAnnotationViews() {
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    }
    
    private func setupMapButtons() {
        mapDimensionButton.roundCorners(corners: [.topLeft, .bottomLeft], radius: 10)
        userTrackingButton.roundCorners(corners: [.topRight, .bottomRight], radius: 10)
        applyShadowOnView(trackingDimensionStackView)
    }
    
    let blurredStatusBar = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    func setupBlurredStatusBar() {
//        let blurredStatusBar = UIImageView(image: UIImage.imageFromColor(color: .white))
//        blurredStatusBar.applyMediumShadow()
        blurredStatusBar.translatesAutoresizingMaskIntoConstraints = false
        if blurredStatusBar.superview != view {
            view.addSubview(blurredStatusBar)
            blurredStatusBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            blurredStatusBar.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            blurredStatusBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            blurredStatusBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        }
        blurredStatusBar.alpha = 1
    }
    
    func removeBlurredStatusBar() {
        blurredStatusBar.alpha = 0
    }
}

//MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    
    // Setup
    
    private func setupLocationManager(){
        locationManager.delegate = self
    }
    
    // Helper
    
    func requestUserLocationPermissionIfNecessary() {
        if CLLocationManager.authorizationStatus() == .denied ||
            CLLocationManager.authorizationStatus() == .notDetermined { //this check should also exist here for when the function is called after registering/logging in
            CustomSwiftMessages.showPermissionRequest(permissionType: .userLocation) { approved in
                if approved {
//                    callback(approved)
                    if CLLocationManager.authorizationStatus() == .notDetermined {
                        self.locationManager.requestWhenInUseAuthorization()
                    } else {
                        CustomSwiftMessages.showSettingsAlertController(title: "turn on location services for mist in settings", message: "", on: self)
                    }
                }
            }
        }
    }
    
    //called upon creation of LocationManager and upon permission changes (either from within app or in settings)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        CustomSwiftMessages.displayError(error)
    }
}

//MARK: - User Interaction

extension MapViewController {
        
    @IBAction func userTrackingButtonDidPressed(_ sender: UIButton) {
        // Ideally: stop the camera. Otherwise, the camera might keep moving after moving to userlocation. But not sure how to do that
        
        if CLLocationManager.authorizationStatus() == .denied ||
            CLLocationManager.authorizationStatus() == .notDetermined {
            requestUserLocationPermissionIfNecessary()
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
    
//    @IBAction func zoomInButtonDidPressed(_ sender: UIButton) {
//        let analyticsTitle = "zoomInButtonDidPressed"
//        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
//          AnalyticsParameterItemID: "id-\(analyticsTitle)",
//          AnalyticsParameterItemName: analyticsTitle,
//        ])
//
//        zoomByAFactorOf(0.25) {
//            self.view.isUserInteractionEnabled = true //in case the user scrolled map before pressing
//        }
//    }
    
//    @IBAction func zoomOutButtonDidPressed(_ sender: UIButton) {
//        let analyticsTitle = "zoomOutButtonDidPressed"
//        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
//          AnalyticsParameterItemID: "id-\(analyticsTitle)",
//          AnalyticsParameterItemName: analyticsTitle,
//        ])
//
//        zoomByAFactorOf(4) {
//            self.view.isUserInteractionEnabled = true //in case the user scrolled map before pressing
//        }
//    }
    
}

//MARK: - MKMapViewDelegate

var cameraDistance: Double = 0

extension MapViewController: MKMapViewDelegate {
    
    // Updates after each view change is completed
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        moveMapLegalLabel()
        // When the camera flies out and in, it pauses between animations and this function is called. we need to wait to have it
        if isCameraFlying && !isCameraFlyingOutAndIn {
            isCameraFlying = false
        }
        if isCameraFlying && isCameraFlyingOutAndIn {
            isCameraFlyingOutAndIn = false //so that on the next call of regionDidChangeAnimated, aka when the camera is done flying back in, isCameraFlying will be set to false
            //note: this doesnt work for more than one chaining... for that. you'll have to set isCameraFlyingOutAndIn in the last animation block
        }
        
        if !zoomSlider.isTracking {
            UIView.animate(withDuration: 0.3) {
                self.zoomSlider.alpha = 0.02
                self.zoomSliderGradientImageView.alpha = 0.3
            }
        }
    }
    
    //This could be useful, i'm not using this function at all up until now
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        moveMapLegalLabel()
        
//        if !zoomSlider.isTracking {
//            UIView.animate(withDuration: 0.3) {
//                self.zoomSliderGradientImageView.alpha = 1
//            }
//        }
    }

    //updates continuously throughout user drag
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let zoomWidth = mapView.visibleMapRect.size.width
        let zoomFactor = Int(log2(zoomWidth)) - 9
        let zoom = mapView.camera.centerCoordinateDistance //centerCoordinateDistance takes pitch into account
        
        // Limit minimum pitch. Doing this because of weird behavior with clicking on posts from a pitch less than 50
        if mapView.camera.pitch > maxCameraPitch && !modifyingMap {
            modifyingMap = true
            mapView.camera.pitch = maxCameraPitch
            modifyingMap = false
        }
        
        //DONT do this on scroll did begin
        if abs(cameraDistance - mapView.camera.centerCoordinateDistance) > 1 {
            print(zoomSliderGradientImageView.alpha)
            if zoomSliderGradientImageView.alpha < 0.35 {
                UIView.animate(withDuration: 0.3) {
                    self.zoomSliderGradientImageView.alpha = 1
                }
            }
            //update the side indicator value?
//            let asdf = pow(mapView.camera.centerCoordinateDistance, (1/10)) - 0.5
//            zoomSlider.value = Float(1 - asdf)
        }
        cameraDistance = mapView.camera.centerCoordinateDistance
        
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
        
        if let annotation = annotation as? PostAnnotation {
            return PostAnnotationView(annotation: annotation, reuseIdentifier: PostAnnotationView.ReuseID)
        }
        if let annotation = annotation as? PlaceAnnotation {
            return PlaceAnnotationView(annotation: annotation, reuseIdentifier: PlaceAnnotationView.ReuseID)
        }
        
        if let _ = annotation as? MKUserLocation {
            
        }
        return nil // handles views for default annotations like user location
    }
}

//MARK: - Camera Adjustment
    
extension MapViewController {
    
    func centerMapOnUSC() {
        let region = mapView.regionThatFits(MKCoordinateRegion(center: Constants.Coordinates.USC, latitudinalMeters: 1200, longitudinalMeters: 1200))
        mapView.setRegion(region, animated: true)
    }
    
    func centerMapOn(lat: Double, long: Double) {
        let newCamera = MKMapCamera(lookingAtCenter: CLLocationCoordinate2D.init(latitude: lat, longitude: long), fromDistance: mapView.camera.centerCoordinateDistance, pitch: maxCameraPitch, heading: 0)
        mapView.camera = newCamera
    }
    
    //Consider not letting "withDuration" be passed, but let it be calculated here when it's actually needed. the duration might change based on the zoomOut
    func slowFlyTo(lat: Double,
                   long: Double,
                   incrementalZoom: Bool,
                   withDuration duration: Double,
                   withLatitudeOffset: Bool = false,
                   completion: @escaping (Bool) -> Void) {
        isCameraFlying = true
        var newCLLDistance: Double = 2000
        let dynamicLatOffset = (latitudeOffsetForOneKMDistance / 1000) * newCLLDistance
        
        let newLat = withLatitudeOffset ? lat + dynamicLatOffset : lat
        let destination = CLLocationCoordinate2D(latitude: newLat, longitude: long)
        if incrementalZoom {
            newCLLDistance = pow(self.mapView.camera.centerCoordinateDistance, 8/10)
        }
        let finalCamera = MKMapCamera(lookingAtCenter: destination,
                                         fromDistance: newCLLDistance,
                                      pitch: maxCameraPitch,
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
    
    //This function is used when selecting a cluster within the clusterThresholdDistance
    //We don't want to zoom in because that makes it likely the cluster will disperse and the postCalloutView won't be selected
    func slowFlyWithoutZoomTo(lat: Double,
                              long: Double,
                              withDuration duration: Double,
                              withLatitudeOffset: Bool = false,
                              completion: @escaping (Bool) -> Void) {
        isCameraFlying = true
        
        //NOTE: unlike the other slowFlyTo functions, in this one, we're calculating the latitude offset dynamically, based on the current map zoom level
        //This is because we are adjusting the camera at the same distance, without zoom in or zoom out
        let currentDistance = mapView.camera.centerCoordinateDistance
        let dynamicLatOffset = (latitudeOffsetForOneKMDistance / 1000) * currentDistance
        
        let newLat = withLatitudeOffset ? lat + dynamicLatOffset : lat
        let destination = CLLocationCoordinate2D(latitude: newLat, longitude: long)
        let finalCamera = MKMapCamera(lookingAtCenter: destination,
                                      fromDistance: currentDistance,
                                      pitch: maxCameraPitch,
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
        let finalDistance: Double = 500
        let destination = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let finalCamera = MKMapCamera(lookingAtCenter: destination,
                                         fromDistance: finalDistance,
                                      pitch: maxCameraPitch,
                                         heading: 0)
        let currentLocation = mapView.camera.centerCoordinate
        let midwayPoint = currentLocation.geographicMidpoint(betweenCoordinates: [destination])
        let distanceBetween = currentLocation.distance(from: destination)
        let midwayDistance = mapView.camera.centerCoordinateDistance +  distanceBetween * 2
        let preRotationCamera = MKMapCamera(lookingAtCenter: midwayPoint,
                                            fromDistance: midwayDistance,
                                         pitch: maxCameraPitch,
                                         heading: 0)
        isCameraFlying = true
        isCameraFlyingOutAndIn = true
        
        //EXPERIMENTAL
//        UIView.animateKeyframes(withDuration: duration*2, delay: 0, options: .calculationModeCubic, animations: {
//            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
//                self.mapView.camera = preRotationCamera
//            }
//            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
//                self.mapView.camera = finalCamera
//            }
//        })
        
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
    
    func getRegionCenteredAround(_ annotations: [MKAnnotation]) -> MKCoordinateRegion? {
        return getRegionCenteredAround(annotations.map({ annotation in annotation.coordinate }))
    }
    
    func getRegionCenteredAround(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }
        var maxLat = coordinates[0].latitude
        var minLat = coordinates[0].latitude
        var maxLong = coordinates[0].longitude
        var minLong = coordinates[0].longitude
        coordinates.forEach { coordinate in
            maxLat = max(maxLat, coordinate.latitude)
            minLat = min(minLat, coordinate.latitude)
            maxLong = max(maxLong, coordinate.longitude)
            minLong = min(minLong, coordinate.longitude)
        }
        let somekindofmiddle = CLLocationCoordinate2D
            .geographicMidpoint(betweenCoordinates:[CLLocationCoordinate2D(latitude: maxLat, longitude: maxLong),
                                                    CLLocationCoordinate2D(latitude: minLat, longitude: minLong)])
        let latDelta = max(minSpanDelta,  1.3 * (maxLat - minLat))
        let longDelta = max(minSpanDelta, 1.3 * (maxLong - minLong))
        return MKCoordinateRegion(center: somekindofmiddle,
                                            span: .init(latitudeDelta: latDelta,
                                                        longitudeDelta: longDelta))
    }
    
    // Zoomin / zoomout button
    func zoomByAFactorOf(_ factor: Double, _ completion: @escaping () -> Void) {
        isCameraZooming = true
        isCameraFlying = true
        let newDistance = mapView.camera.centerCoordinateDistance * factor
        let newAdjustedDistance = max(newDistance, MapViewController.MIN_CAMERA_DISTANCE)
        let newPitch = mapView.camera.pitch //min(mapView.camera.pitch, MapViewController.MAX_CAMERA_PITCH)  //using pitch with zoom was cuasing issues for drop a pin
        //I use 30 instead of 50 just to add the extra pitch transition to make it more dnamic when zooming out
        //Note: you have to actually set a newPitch value like above. It seems that if you use the old pitch value for rotationCamera, sometimes the camera won't actually be changed for some reason
        let rotationCamera = MKMapCamera(lookingAtCenter: mapView.camera.centerCoordinate,
                                         fromDistance: newAdjustedDistance,
                                         pitch: newPitch,
                                         heading: mapView.camera.heading)
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: {
            self.mapView.camera = rotationCamera
        }) { [weak self] finished in
            completion()
            self?.isCameraZooming = false
        }
    }
    
    // Dimension button
    func toggleMapDimension(_ completion: @escaping () -> Void) {
        isThreeDimensional = !isThreeDimensional
        
        // Prepare the new pitch based on the new value of isThreeDimensional
        var newPitch: Double
        if isThreeDimensional {
            newPitch = maxCameraPitch
        } else {
            newPitch = 0.0
        }
        
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
    
}

//MARK: - Annotations

extension MapViewController {
    
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
                    mapView.selectAnnotation(mapView.annotations[1], animated: true)
                    return
                }
            }
        }
    }
    
    func turnPostsIntoAnnotations(_ posts: [Post]) {
        postAnnotations = posts.map { post in PostAnnotation(withPost: post) }
    }
    
    func turnPlacesIntoAnnotations(_ places: [MKMapItem]) {
        let closestPlaces = Array(places.sorted(by: { first, second in
            mapView.centerCoordinate.distance(from: first.placemark.coordinate) < mapView.centerCoordinate.distance(from: second.placemark.coordinate)
        }).prefix(8))
        placeAnnotations = closestPlaces.map({ place in PlaceAnnotation(withPlace: place) })
    }
    
    func removeExistingPlaceAnnotationsFromMap() {
        mapView.annotations.forEach { annotation in
            if let placeAnnotation = annotation as? PlaceAnnotation {
                mapView.removeAnnotation(placeAnnotation)
            }
        }
    }
    
    func removeExistingPostAnnotationsFromMap() {
        mapView.annotations.forEach { annotation in
            if let postAnnotation = annotation as? PostAnnotation {
                mapView.removeAnnotation(postAnnotation)
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

//MARK: - Map Gradient Shadow

//private func applyGradientUnderneathNavbar() {
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
//}

//MARK: - Deprecated

extension MapViewController {
    
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
//        let span = MKCoordinateRegion(candidateRect).span //could i use span to find the appropriate camera distance, then animate the camera? probably
        UIView.animate(withDuration: cameraAnimationDuration,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: {
            self.mapView.visibleMapRect = candidateRect
        }, completion: nil)
    }
}
