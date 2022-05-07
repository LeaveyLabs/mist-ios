//
//  ExploreViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    var mapModal: MapModalViewController?
    var prevZoomFactor: Int = 4
    var prevZoomWidth: Double!
    var prevZoom: Double!
    var hasPostRendered: Bool = false
    
    var displayedAnnotations: [PostAnnotation]? {
        willSet {
            if let currentAnnotations = displayedAnnotations {
                mapView.removeAnnotations(currentAnnotations)
            }
        }
        didSet {
            if let newAnnotations = displayedAnnotations {
                mapView.addAnnotations(newAnnotations)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.restoreHairline()
        setupMapView()
        displayedAnnotations = []
    }
    
    // MARK: - Setup
    
    func setupMapView() {
        mapView.delegate = self
        centerMapOnUSC()
        registerMapAnnotationViews()
        
        //set iniital camera pitch (aka camera angle)
        mapView.camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: 4000, pitch: 20, heading: mapView.camera.heading)
        prevZoomWidth = mapView.visibleMapRect.size.width
        prevZoom = mapView.camera.centerCoordinateDistance
        //remove default pointsOfInterest
        //mapView.pointOfInterestFilter = .some(MKPointOfInterestFilter(including: [MKPointOfInterestCategory.cafe, MKPointOfInterestCategory.fitnessCenter, MKPointOfInterestCategory.bakery, MKPointOfInterestCategory.university]))
    }
    
    func registerMapAnnotationViews() {
        mapView.register(PostMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(PostAnnotation.self))
    }
}

//https://developer.apple.com/documentation/mapkit/mkmapviewdelegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let view = view as? PostMarkerAnnotationView {
            view.glyphTintColor = mistUIColor() //this is needed bc for some reason the glyph tint color turns grey even with the mist-heart-pink icon
            view.markerTintColor = mistSecondaryUIColor()
            
            let latitudeOffset = 0.0010
            slowFlyTo(lat: view.annotation!.coordinate.latitude + latitudeOffset, long: view.annotation!.coordinate.longitude)
            loadPostViewFor(annotationView: view)
        }
    }
    
    
    func loadPostViewFor(annotationView: PostMarkerAnnotationView) {
        let annotation = annotationView.annotation as! PostAnnotation
        let cell = Bundle.main.loadNibNamed(Constants.SBID.Cell.Post, owner: self, options: nil)?[0] as! PostCell
        if let mapModalPost = annotation.post {
            cell.configurePostCell(post: mapModalPost, parent: self, bubbleArrowPosition: .bottom)
        }
        
        
        let postView: UIView? = cell.contentView
        if let newPostView = postView {
            newPostView.tag = 999
            newPostView.translatesAutoresizingMaskIntoConstraints = false //allows programmatic settings of constraints
            annotationView.addSubview(newPostView)
            NSLayoutConstraint.activate([
                newPostView.bottomAnchor.constraint(equalTo: annotationView.bottomAnchor, constant: -70),
                newPostView.widthAnchor.constraint(equalTo: mapView.widthAnchor, constant: -10),
                newPostView.heightAnchor.constraint(lessThanOrEqualTo: mapView.heightAnchor, multiplier: 0.57, constant: 0),
                newPostView.centerXAnchor.constraint(equalTo: annotationView.centerXAnchor, constant: 0),
            ])
            newPostView.alpha = 0
            newPostView.isHidden = true
            
            //this duration should be .1 seconds longer than the zoom-in, that way the camera surely does not move anymore once hasPostRendered = true
            newPostView.fadeIn(duration: 0.11, delay: Double(prevZoomFactor)/10 ) { [self] Bool in
                hasPostRendered = true
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        hasPostRendered = false
        
        if let view = view as? PostMarkerAnnotationView {
            view.glyphTintColor = .white
            view.markerTintColor = mistUIColor()
        }
        
        if let postView: UIView = view.viewWithTag(999) {
            postView.fadeOut(duration: 0.5, delay: 0, completion: { Bool in
                postView.isHidden = true
                postView.removeFromSuperview()
                mapView.isScrollEnabled = true
                mapView.isZoomEnabled = true
            })
        }
    }
    
    // The map view asks `mapView(_:viewFor:)` for an appropiate annotation view (the little mist heart) for a specific annotation.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else {
            // Make a fast exit if the annotation is the `MKUserLocation`, as it's not an annotation view we wish to customize.
            return nil
        }
        
        var annotationView: MKAnnotationView?
        if let annotation = annotation as? PostAnnotation {
            annotationView = setupPostAnnotationView(for: annotation, on: mapView)
        }
        return annotationView
    }
    
    // Create an annotation view for the Golden Gate Bridge, customize the color, and add a button to the callout.
    func setupPostAnnotationView(for annotation: PostAnnotation, on mapView: MKMapView) -> MKAnnotationView {
        let identifier = NSStringFromClass(PostAnnotation.self)
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier, for: annotation)
        if let markerAnnotationView = view as? PostMarkerAnnotationView {
            markerAnnotationView.animatesWhenAdded = true
            markerAnnotationView.canShowCallout = false
            markerAnnotationView.markerTintColor = mistUIColor()
            markerAnnotationView.glyphImage = UIImage(named: "mist-heart-pink-padded")
//            markerAnnotationView.selectedGlyphImage = UIImage(named: "mist-pink-heart")
        }
        return view
    }
    
    //updates after each view change is completed
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {

    }

    //updates continuously throughout user drag
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let zoomWidth = mapView.visibleMapRect.size.width
        let zoomFactor = Int(log2(zoomWidth)) - 9
        let zoom = mapView.camera.centerCoordinateDistance
        
        if hasPostRendered {
            if zoom != prevZoom {
                if (mapView.selectedAnnotations.count > 0) {
                    mapView.deselectAnnotation(mapView.selectedAnnotations[0], animated: true)
                }
            }
        }
        prevZoomFactor = zoomFactor
        prevZoomWidth = zoomWidth
        prevZoom = zoom
    }
    
}
    
extension MapViewController {

    //MARK: -Helpers

    //https://stackoverflow.com/questions/21125573/mkmapcamera-pitch-altitude-function
    func slowFlyTo(lat: Double, long: Double) {
        let pinLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let rotationCamera = MKMapCamera(lookingAtCenter: pinLocation, fromDistance: 500, pitch: 50, heading: mapView.camera.heading)

        UIView.animate(withDuration: Double(prevZoomFactor+1)/10, delay: 0, options: .curveEaseInOut, animations: {
            self.mapView.camera = rotationCamera
        }, completion: nil)
    }
    
    func centerMapAt(lat: Double, long: Double) {
        let region = mapView.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: long), latitudinalMeters: 200, longitudinalMeters: 200))
        mapView.setRegion(region, animated: true)
    }
    
    func centerMapOnUSC() {
        let region = mapView.regionThatFits(MKCoordinateRegion(center: Constants.USC_LAT_LONG, latitudinalMeters: 1200, longitudinalMeters: 1200))
        mapView.setRegion(region, animated: true)
    }
}

//was trying to intercept the animation for MKMarkerAnnotationView to slow it down
final class PostMarkerAnnotationView: MKMarkerAnnotationView {
  var onSelect: (() -> Void)?
    

    override func setSelected(_ selected: Bool, animated: Bool) {
//    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//        super.setSelected(false, animated: false)
//    }
  }
}
