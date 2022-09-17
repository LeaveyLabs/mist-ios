//
//  SortBy.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation
import MapKit

struct PostFilter {
    var postType: PostType = .All
    
    var pageNumber: Int = 0
    var isFeedFullyLoaded: Bool = false
    var postSort: SortOrder = .TRENDING {
        didSet {
            pageNumber = 0
            isFeedFullyLoaded = false
        }
    }
    
    var currentMapPlaneAndRegion: (Int, MKCoordinateRegion) = (1, MKCoordinateRegion(center: Constants.Coordinates.USC, span: MKCoordinateSpan(latitudeDelta: MapViewController.MIN_SPAN_DELTA, longitudeDelta: MapViewController.MIN_SPAN_DELTA)))
    var searchedMapRegions: [Int:[MKCoordinateRegion]] = [:]
}

enum PostType: String {
    case All, Featured, Matches, Friends
}
