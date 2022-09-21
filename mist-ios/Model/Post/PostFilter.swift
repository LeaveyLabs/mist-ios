//
//  SortBy.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation
import MapKit

struct PostFilter {    
    static let MIN_PAGE_NUMBER = 1
    var pageNumber: Int = PostFilter.MIN_PAGE_NUMBER
    var isFeedFullyLoaded: Bool = false
    var postSort: SortOrder = .TRENDING {
        didSet {
            pageNumber = PostFilter.MIN_PAGE_NUMBER
            isFeedFullyLoaded = false
            searchedMapRegions = [:]
        }
    }
//    var mapFilterMethod: MapFilterMethod = .top100
    
    var currentMapPlaneAndRegion: (Int, MKCoordinateRegion) = (1, MKCoordinateRegion(center: Constants.Coordinates.USC, span: MKCoordinateSpan(latitudeDelta: MapViewController.MIN_SPAN_DELTA, longitudeDelta: MapViewController.MIN_SPAN_DELTA)))
    var searchedMapRegions: [Int:[MKCoordinateRegion]] = [:]
}

//enum MapFilterMethod: String {
//    case all, top100
//}
