//
//  PlaceAnnotationView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/09.
//

import Foundation
import MapKit

final class PlaceAnnotationView: MKMarkerAnnotationView {
    
    static let ReuseID = "Place"

    // MapView annotation views are reused like TableView cells,
    // so everytime they're set, you should prepare them
    override var annotation: MKAnnotation? {
        willSet {
            animatesWhenAdded = true
            canShowCallout = false
            if let annotation = annotation as? PlaceAnnotation {
                glyphImage = UIImage(systemName: annotation.category?.symbolName ?? MKPointOfInterestCategory.defaultSymbolName)
            }
            glyphTintColor = mistUIColor()
            markerTintColor = .white
            displayPriority = .required
        }
    }
    
    //MARK: - Initializaiton
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: - User Interaction
        
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            
        } else {
            
        }
    }

}
