//
//  MistVC+ExploreDelegate.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/10/13.
//

import Foundation
import MapKit

extension MistCollectionViewController: ExploreChildDelegate {
    
    //New Addition
    func toggleHeaderVisibility(visible: Bool) {
        UIView.animate(withDuration: 0.25) {
            self.feedToggleView.alpha = visible ? 1 : 0
        }
    }
    
    func loadNewMapPostsIfNecessary() {
        guard !isFetchingMorePosts && PostService.singleton.isReadyForNewMapSearch() else { return }
        isFetchingMorePosts = true
        Task {
            do {
                try await PostService.singleton.loadAndAppendExploreMapPosts()
                DispatchQueue.main.async { [self] in
                    renderNewPostsOnMap(withType: .addMore)
                    isFetchingMorePosts = false
                }
            } catch {
                print("ERROR LOADING IN MAP POSTS IN BACKGROUND WHILE SCROLLING")
                isFetchingMorePosts = false
            }
        }
    }

    func loadNewFeedPostsIfNecessary() {
        let refreshedFeedType: SortOrder = currentPage == 0 ? .RECENT : .TRENDING
        guard let refreshedFeed = visibleFeed else { return }
        guard let refreshedFeedCell = visibleFeedCell else { return }
        guard !isFetchingMorePosts else { return }
        isFetchingMorePosts = true
        
        Task {
            do {
                try await PostService.singleton.loadExploreFeedPostsIfPossible(feed: refreshedFeedType)
                DispatchQueue.main.async { [self] in
                    refreshedFeedCell.posts = refreshedFeedType == .RECENT ? PostService.singleton.getExploreNewPosts() :  PostService.singleton.getExploreBestPosts()
                    refreshedFeed.reloadData()
                    self.isFetchingMorePosts = false
                }
            } catch {
                print("ERROR LOADING IN MAP POSTS IN BACKGROUND WHILE SCROLLING")
                isFetchingMorePosts = false
            }
        }
    }

    @objc func refreshFeedPosts() {
        let refreshedFeedType: SortOrder = currentPage == 0 ? .RECENT : .TRENDING
        guard let refreshedFeed = visibleFeed else { return }
        guard let refreshedFeedCell = visibleFeedCell else { return }
        guard !isFetchingMorePosts else { return }
        isFetchingMorePosts = true

        Task {
            do {
                try await PostService.singleton.loadExploreFeedPostsIfPossible(feed: refreshedFeedType) //page count is set to 0 when resetting sorting
                DispatchQueue.main.async {
                    refreshedFeedCell.posts = refreshedFeedType == .RECENT ? PostService.singleton.getExploreNewPosts() :  PostService.singleton.getExploreBestPosts()
                    refreshedFeed.reloadData()
                    refreshedFeed.refreshControl?.endRefreshing()
                    self.isFetchingMorePosts = false
                }
            } catch {
                CustomSwiftMessages.displayError(error)
                isFetchingMorePosts = false
                refreshedFeed.refreshControl?.endRefreshing()
            }
        }
    }
    
    @MainActor
    @objc func refreshMapPosts(completion: (() -> Void)? = {  } ) {
        reloadButton.loadingIndicator(true)
        reloadButton.setImage(nil, for: .normal)
        isFetchingMorePosts = true

        Task {
            do {
                try await PostService.singleton.loadAndOverwriteExploreMapPosts()
                DispatchQueue.main.async {
                    self.renderNewPostsOnMap(withType: .firstLoad)
                    self.reloadButton.setImage(UIImage(systemName: "arrow.2.circlepath", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)), for: .normal)
                    self.reloadButton.loadingIndicator(false)
                    self.isFetchingMorePosts = false
                    completion?()
                }
            } catch {
                CustomSwiftMessages.displayError(error)
                DispatchQueue.main.async {
                    self.reloadButton.setImage(UIImage(systemName: "arrow.2.circlepath", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)), for: .normal)
                    self.reloadButton.loadingIndicator(false)
                    self.isFetchingMorePosts = false
                }
            }
        }
    }

    @MainActor
    func handleNewlySubmittedPost(didJustShowNotificaitonsRequest: Bool) {
        isHandlingNewPost = false
        annotationSelectionType = .submission

//        guard let newSubmission = PostService.singleton.getSubmissions().first else { return }

        flowLayout.scrollToPage(index: 0, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            visibleFeed!.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            visibleFeedCell!.posts = PostService.singleton.getExploreNewPosts()
            visibleFeed!.reloadData() //need to reload data after rearranging posts
            renderNewPostsOnMap(withType: .newPost)
        }
    }
    
    
    func renderNewPostsOnMap(withType reloadType: ReloadType) {
        let cachedMapPosts = PostService.singleton.getAllExploreMapPosts()
        
        switch reloadType {
        case .firstLoad:
            removeExistingPostAnnotationsFromMap()
            turnPostsIntoAnnotationsAndReplacePostAnnotations(cachedMapPosts)
            mapView.addAnnotations(postAnnotations)
        case .addMore: //Don't remove postAnnotations. Only add the newExploreMapPosts.
            turnPostsIntoAnnotationsAndAppendToPostAnnotations(PostService.singleton.getNewExploreMapPosts())
            mapView.addAnnotations(postAnnotations)
        case .newSearch: //Relocate map around annotations

            //NOTE: this is just optimized for custom explore right now because of the offset below. we should just rename this section to "customExplore"

            turnPostsIntoAnnotationsAndReplacePostAnnotations(cachedMapPosts)
            //NOTE: we aren't adding place annotations within this function on newSearch as of now
            mapView.addAnnotations(postAnnotations)
            var newRegion = getRegionCenteredAround(postAnnotations + placeAnnotations) ?? MKCoordinateRegion.init(center: Constants.Coordinates.USC, latitudinalMeters: 2000, longitudinalMeters: 2000)
            let dynamicLatOffset = (latitudeOffsetForOneKMDistance / 1000) * mapView.camera.centerCoordinateDistance
            newRegion.center.latitude -= (dynamicLatOffset / 2)
            mapView.setRegion(newRegion, animated: true)
            mapView.camera.pitch = maxCameraPitch //i think the pitch is droped in "setRegion"
            // we want to offset in the opposite direciton and smaller direction than usual because now the feed takes up a larger part of the bottomn

        case .newPost:
            removeExistingPostAnnotationsFromMap()
            turnPostsIntoAnnotationsAndReplacePostAnnotations(cachedMapPosts)
            mapView.addAnnotations(postAnnotations)
        }
    }
    
}
