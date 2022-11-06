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
        fatalError("mist collection view VC doesnt support loadNewMapPosts")
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
        fatalError("not supporrted")
    }

    //Old implementation of Mist, with the map and feed on same VC:
//    @MainActor
//    func handleNewlySubmittedPost(didJustShowNotificaitonsRequest: Bool) {
//        isHandlingNewPost = false
//        annotationSelectionType = .submission
//
////        guard let newSubmission = PostService.singleton.getSubmissions().first else { return }
//
//        flowLayout.scrollToPage(index: 0, animated: true)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
//            visibleFeed!.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
//            visibleFeedCell!.posts = PostService.singleton.getExploreNewPosts()
//            visibleFeed!.reloadData() //need to reload data after rearranging posts
//            renderNewPostsOnMap(withType: .newPost)
//        }
//    }
    
    func renderNewPostsOnMap(withType reloadType: ReloadType) {
        
    }
    
}
