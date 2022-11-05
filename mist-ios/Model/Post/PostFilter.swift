//
//  SortBy.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation
import MapKit

struct FeedPostFilter {
    var postSort: SortOrder! //must be set
    static let MIN_PAGE_NUMBER = 1
    var pageNumber: Int = FeedPostFilter.MIN_PAGE_NUMBER
    var isFeedFullyLoaded: Bool = false
    var textFilter: [String]? = nil {
        didSet {
            pageNumber = FeedPostFilter.MIN_PAGE_NUMBER
            isFeedFullyLoaded = false
        }
    }
    
    init(postSort: SortOrder) {
        self.postSort = postSort
    }
    
}

struct MapPostFilter {
    var postSort: SortOrder = .RECENT
    var currentMapPlaneAndRegion: (Int, MKCoordinateRegion) = (1, MKCoordinateRegion(center: Constants.Coordinates.USC, span: MKCoordinateSpan(latitudeDelta: MapViewController.MIN_SPAN_DELTA, longitudeDelta: MapViewController.MIN_SPAN_DELTA)))
    var searchedMapRegions: [Int:[MKCoordinateRegion]] = [:]
    
    var textFilter: [String]? = nil {
        didSet {
            searchedMapRegions = [:]
        }
    }
}

//    var mapFilterMethod: MapFilterMethod = .top100
//enum MapFilterMethod: String {
//    case all, top100
//}
