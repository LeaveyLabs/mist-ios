//
//  ClusterAnnotationView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/08.
//

import Foundation
import MapKit
import CenteredCollectionView

protocol AnnotationViewWithPosts {
    func movePostUpAfterEmojiKeyboardRaised()
    func movePostBackDownAfterEmojiKeyboardDismissed()
    func rerenderCalloutForUpdatedPostData()
    func derenderCallout()
}

class ClusterAnnotationView: MKMarkerAnnotationView {
    
    //MARK: - Properties
    
    let centeredCollectionViewFlowLayout = CenteredCollectionViewFlowLayout()
    var collectionView: PostCollectionView?
    var postDelegate: PostDelegate?
    var isFinishingSwipe: Bool = false
    var swipeDelegate: AnnotationViewSwipeDelegate?
    var xtranslation: Double = 0
    lazy var MAP_VIEW_WIDTH: Double = Double(mapView?.bounds.width ?? 350)
    lazy var POST_VIEW_WIDTH: Double = MAP_VIEW_WIDTH * 0.5 + 100
    lazy var POST_VIEW_MARGIN: Double = (MAP_VIEW_WIDTH - POST_VIEW_WIDTH) / 2
    lazy var POST_VIEW_MAX_HEIGHT: Double = (((mapView?.frame.height ?? 500) * 0.75) - 110.0)
    
    var quickSelectGestureRecognizer: UITapGestureRecognizer!

    var mapView: MKMapView? {
        var view = superview
        while view != nil {
            if let mapView = view as? MKMapView { return mapView }
            view = view?.superview
        }
        return nil
    }
    
    var memberCount: Int {
        guard let cluster = annotation as? MKClusterAnnotation else { return 0 }
        return cluster.memberAnnotations.count
    }
    
    var memberPostAnnotations: [PostAnnotation]? {
        return ((annotation as? MKClusterAnnotation)?.memberAnnotations.compactMap { $0 as? PostAnnotation } )
    }
    
    var currentlyVisiblePostIndex: Int?
    
    var localCopyOfAllMapPostIds = [Int]()
    var sortedMemberPosts = [Post]()
    
    func sortMemberPosts(from memberAnnotations: [MKAnnotation]) -> [Post] {
        var sortedPosts = [Post]()
        for mapPostId in localCopyOfAllMapPostIds {
            for annotation in memberAnnotations {
                guard let annotationPost = (annotation as? PostAnnotation)?.post else { continue }
                if annotationPost.id == mapPostId {
                    sortedPosts.append(annotationPost)
                }
            }
        }
        return sortedPosts
    }
    var sortMemberPostsTask: Task<Void, Never>?

    override var annotation: MKAnnotation? {
        willSet {
            guard let newCluster = newValue as? MKClusterAnnotation else {
                return }
            animatesWhenAdded = true
            canShowCallout = false
            setupMarkerTintColor(newCluster)
            displayPriority = .required
            currentlyVisiblePostIndex = nil
//            glyphText = newCluster.memberAnnotations..post.emoji_dict.first?.key

            localCopyOfAllMapPostIds = PostService.singleton.getExploreMapPostsSortedIds()
                                
            sortMemberPostsTask = Task {
                sortedMemberPosts = sortMemberPosts(from: newCluster.memberAnnotations)
                //on main thread:
                DispatchQueue.main.async { [weak self] in
                    newCluster.updateClusterTitle(newTitle: self?.sortedMemberPosts.first?.title)
                    self?.glyphText = self?.sortedMemberPosts.first?.topEmoji
                    return
                }
            }
        }
    }
    
    //MARK: - Initialization
        
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupGestureRecognizerToPreventInteractionDelay()
        centerOffset = CGPoint(x: 0, y: -10) // Offset center point to animate better with marker annotations
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Setup
    
    private func setupMarkerTintColor(_ clusterAnnotation: MKClusterAnnotation?) {
        guard let memberAnnotationCount: Int = clusterAnnotation?.memberAnnotations.count else { return }
        if memberAnnotationCount < 10 {
            markerTintColor = Constants.Color.mistLilac
        } else {
            markerTintColor = UIColor(hex: "#AC73F5")
        }
    }
    
    //MARK: - User Interaction
        
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        glyphTintColor = selected ? Constants.Color.mistLilac : .white
        if selected {
            markerTintColor = Constants.Color.mistPink
        } else {
            setupMarkerTintColor(annotation as? MKClusterAnnotation)
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitAnnotationView = super.hitTest(point, with: event) {
            return hitAnnotationView
        }

        // If the hit wasn't MKClusterAnnotation, then the hit view must be on the carousel, the the classes's only subview
        guard let collectionView = collectionView else { return nil }
        
        let pointInMapView = convert(point, to: mapView!)
        if detectNeighboringPostTap(pointInMapView: pointInMapView) {
            return UIView() //so the touch doesnt pass through to the map
        }
        
        let pointInCollectionView = convert(point, to: collectionView)
        return collectionView.hitTest(pointInCollectionView, with: event)
    }
    
    //ideally, this would be detected by collectionViewRowWasSelected, but that function isn't being called for some reason
    private func detectNeighboringPostTap(pointInMapView: CGPoint) -> Bool {
        guard let currentpage = centeredCollectionViewFlowLayout.currentCenteredPage else { return false }
        if pointInMapView.x > POST_VIEW_WIDTH + POST_VIEW_MARGIN, currentpage < memberCount - 1 {
            centeredCollectionViewFlowLayout.scrollToPage(index: currentpage + 1, animated: true)
            return true
        } else if pointInMapView.x < POST_VIEW_MARGIN, currentpage >= 1 {
            centeredCollectionViewFlowLayout.scrollToPage(index: currentpage - 1, animated: true)
            return true
        }
        return false
    }
    
}

//MARK: - Public Interface

extension ClusterAnnotationView {
    
    func loadCollectionView(on mapView: MKMapView,
                            withPostDelegate postDelegate: PostDelegate,
                            withDelay delay: Double,
                            withDuration duration: Double,
                            swipeDelegate: AnnotationViewSwipeDelegate, selectionType: AnnotationSelectionType) {
        Task {
            guard let task = sortMemberPostsTask else { return }
            await task.value
            guard sortedMemberPosts.count > 0 else { return }
            DispatchQueue.main.async { [self] in
                collectionView = PostCollectionView(centeredCollectionViewFlowLayout: centeredCollectionViewFlowLayout)
                guard let collectionView = collectionView else { return }
                self.postDelegate = postDelegate
                self.swipeDelegate = swipeDelegate

                collectionView.backgroundColor = UIColor.clear
                collectionView.delegate = self
                collectionView.dataSource = self
                collectionView.translatesAutoresizingMaskIntoConstraints = false
                collectionView.clipsToBounds = false
                addSubview(collectionView)

                // register collection cells
                collectionView.register( ClusterCarouselCell.self, forCellWithReuseIdentifier: String(describing: ClusterCarouselCell.self))

                // configure layout
                centeredCollectionViewFlowLayout.itemSize = CGSize(
                    width: POST_VIEW_WIDTH,
                    height: POST_VIEW_MAX_HEIGHT - 20
                )
                centeredCollectionViewFlowLayout.minimumLineSpacing = 16
                collectionView.showsVerticalScrollIndicator = false
                collectionView.showsHorizontalScrollIndicator = false
                
                //SHOOOOTTTT: okay i got an error for constraining collectionView's width to the mapview because collection view (and its parent) werent a part of the mapview yet. so the annotation was clicked on too soon before it was even properly added to the map view
                NSLayoutConstraint.activate([
                    collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -60),
                    collectionView.widthAnchor.constraint(equalToConstant: MAP_VIEW_WIDTH),
                    collectionView.heightAnchor.constraint(equalToConstant: POST_VIEW_MAX_HEIGHT + 15), //15 for the bottom arrow
                    collectionView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
                ])
                
                if selectionType == .swipeLeft {
                    currentlyVisiblePostIndex = 0
                } else if selectionType == .swipeRight {
                    currentlyVisiblePostIndex = memberCount - 1
                } else if let previouslyVisiblePostIndex = currentlyVisiblePostIndex {
                    currentlyVisiblePostIndex = previouslyVisiblePostIndex
                    if previouslyVisiblePostIndex > memberCount - 1 {
                        currentlyVisiblePostIndex = memberCount - 1
                    }
                } else {
                    currentlyVisiblePostIndex = 0
                }
                
                let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
                longPress.minimumPressDuration = 0.2 //in order to prevent long presses from falling through to the map behind
                self.addGestureRecognizer(longPress)
                longPress.require(toFail: collectionView.panGestureRecognizer) //so that long pressing on the post doesnt prevent the pan
                
                let preventDismissOnPanGesture = UIPanGestureRecognizer(target: self, action: nil)
                self.addGestureRecognizer(preventDismissOnPanGesture)
                preventDismissOnPanGesture.require(toFail: collectionView.panGestureRecognizer)
                        
                if duration != 0 { //produces an error on the very first selection sometimes
                    if memberCount > 0  {
                        collectionView.layoutIfNeeded()
                        collectionView.scrollToItem(at: IndexPath(item: currentlyVisiblePostIndex!, section: 0), at: .centeredHorizontally, animated: false)
                    } //on initial app launch & auto selecting an annotation, sometimes the cluster has no member counts when it is selected
                }
                collectionView.alpha = 0
                collectionView.isHidden = true
                collectionView.fadeIn(duration: duration, delay: delay - 0.3)
            }
        }
    }
    
    @objc func longPress() {
        print("LONG PRESS TO PREVENT ANNOTATION SELECTION BEHIND")
    }
}

//MARK: - AnnotationViewWithPosts

extension ClusterAnnotationView: AnnotationViewWithPosts {
    
    //The callout is currently presented, and we want to update the postView's UI with the new data
    func rerenderCalloutForUpdatedPostData() {
        guard
            let page = centeredCollectionViewFlowLayout.currentCenteredPage,
            let postCollectionView = collectionView,
            let postCarouselCell = postCollectionView.cellForItem(at: IndexPath(item: page, section: 0)) as? ClusterCarouselCell,
            let _ = PostService.singleton.getPost(withPostId: postCarouselCell.postView.postId)
        else {
            return
        }
        postCollectionView.reloadItems(at: [IndexPath(item: page, section: 0)])
    }
    
    func movePostUpAfterEmojiKeyboardRaised() {
        layoutIfNeeded()
        UIView.animate(withDuration: 0.25) { [self] in
            guard let index = currentlyVisiblePostIndex else { return }
            let currentlyVisiblePostView = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as! ClusterCarouselCell
            currentlyVisiblePostView.bottomConstraint.constant = -100
            layoutIfNeeded()
//                constraints.first { $0.firstAnchor == collectionView?.bottomAnchor }?.constant = -152
//                layoutIfNeeded()
        }
    }
        
    func movePostBackDownAfterEmojiKeyboardDismissed() {
        layoutIfNeeded()
        UIView.animate(withDuration: 0.25) { [self] in
            guard let index = currentlyVisiblePostIndex else { return }
            let currentlyVisiblePostView = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as! ClusterCarouselCell
            currentlyVisiblePostView.bottomConstraint.constant = -15
            layoutIfNeeded()
            
            //old method
//            self?.constraints.first { $0.firstAnchor == self?.collectionView?.bottomAnchor }?.constant = -70
//            self?.layoutIfNeeded()
        }
    }
    
    func derenderCallout() {
        guard let collectionView = collectionView else { return }
        collectionView.removeFromSuperview()
        endEditing(true)
        collectionView.fadeOut(duration: 0.25, delay: 0, completion: { Bool in
            collectionView.isHidden = true
        })
    }
    
}

//MARK: - PreventAnnotationViewInteractionDelay

// Unlike PostAnnotationView, this approach uses a function instead of the GestureRecognizer delegate
// ...I don't THINK there's a difference. Just used a different approach in case one causes an issue later
extension ClusterAnnotationView { //: UIGestureRecognizerDelegate {
    
    // PreventAnnotationViewInteractionDelay: 1 of 2
    // Allows for noticeably faster zooms to the annotationview
    // Turns isZoomEnabled off and on immediately before and after a click on the map.
    // This means that in case the tap happened to be on an annotation, there's less delay.
    // Downside: double tap features are not possible
    //https://stackoverflow.com/questions/35639388/tapping-an-mkannotation-to-select-it-is-really-slow
    private func setupGestureRecognizerToPreventInteractionDelay() {
        quickSelectGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(asdf))
        quickSelectGestureRecognizer.delaysTouchesBegan = false
        quickSelectGestureRecognizer.delaysTouchesEnded = false
        quickSelectGestureRecognizer.numberOfTapsRequired = 1
        quickSelectGestureRecognizer.numberOfTouchesRequired = 1
//        quickSelectGestureRecognizer.delegate = self
        self.addGestureRecognizer(quickSelectGestureRecognizer)
    }
    
    // PreventAnnotationViewInteractionDelay: 2 of 2
    @objc func asdf() {
        mapView?.isZoomEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.mapView?.isZoomEnabled = true
        }
    }
    
}

//MARK: - CollectionViewDelegate

extension ClusterAnnotationView: UICollectionViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.endEditing(true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected Cell #\(indexPath.row)")
        if let currentCenteredPage = centeredCollectionViewFlowLayout.currentCenteredPage,
            currentCenteredPage != indexPath.row {
            centeredCollectionViewFlowLayout.scrollToPage(index: indexPath.row, animated: true)
        }
    }
    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard !isFinishingSwipe else { return }
//        xtranslation = scrollView.panGestureRecognizer.translation(in: self).x
//        incrementEdgeSwipe()
//    }
//    
//    func incrementEdgeSwipe() {
//        guard let currentIndex = currentlyVisiblePostIndex,
//              let memberCount = memberCount,
//              let collectionView = collectionView else { return }
//        
//        if currentIndex == 0 {
//            collectionView.transform = CGAffineTransform(translationX: max(0,xtranslation/2), y: 0) //a little boost
//            if xtranslation > 0 { //needed for some reason
//                collectionView.alpha = 1 - abs(Double(max(0,xtranslation)) / 100)
//            }
//        } else if currentIndex == memberCount - 1 {
//            collectionView.transform = CGAffineTransform(translationX: min(0,xtranslation/2), y: 0) //to give it a little boost
//            if xtranslation < 0 {
//                collectionView.alpha = 1 - abs(Double(min(0,xtranslation)) / 100)
//            }
//        }
//    }
//    
//    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//        let didSwipeLeft = xtranslation < -75
//        let didSwipeRight = xtranslation > 75
//        guard let currentIndex = currentlyVisiblePostIndex,
//              let memberCount = memberCount else { return }
//        
//        isFinishingSwipe = true
//        if didSwipeLeft && currentIndex == memberCount - 1 {
//            finishSwiping(.left)
//        } else if didSwipeRight && currentIndex == 0 {
//            finishSwiping(.right)
//        } else {
//            finishSwiping(.incomplete)
//        }
//    }
        
    enum SwipeDirection {
        case left, right, incomplete
    }
    
    func finishSwiping(_ direction: SwipeDirection) {
        guard let collectionView = collectionView else { return }
        switch direction {
        case .left:
            swipeDelegate?.handlePostViewSwipeLeft()
            collectionView.alpha = 0
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear) {
            } completion: { finished in
                collectionView.isHidden = true
            }
        case .right:
            collectionView.alpha = 0
            swipeDelegate?.handlePostViewSwipeRight()
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear) {
            } completion: { finished in
                collectionView.isHidden = true
            }
        case .incomplete:
            print("INNCOMPLETE")
            collectionView.alpha = 1
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear) {
                collectionView.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            break
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isFinishingSwipe = false
        }
    }
        
}

//MARK: - CollectionViewDataSource

extension ClusterAnnotationView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sortedMemberPosts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ClusterCarouselCell.self), for: indexPath) as! ClusterCarouselCell
        guard let postDelegate = postDelegate else { return cell }
        
        let postId = sortedMemberPosts[indexPath.item].id
        let cachedPost = PostService.singleton.getPost(withPostId: postId)!
        cell.configureForPost(post: cachedPost, nestedPostViewDelegate: postDelegate, bubbleTrianglePosition: .bottom)
        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("Did end decelerating. Current centered index: \(String(describing: centeredCollectionViewFlowLayout.currentCenteredPage ?? nil))")
        currentlyVisiblePostIndex = centeredCollectionViewFlowLayout.currentCenteredPage
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("Did end animation. Current centered index: \(String(describing: centeredCollectionViewFlowLayout.currentCenteredPage ?? nil))")
        currentlyVisiblePostIndex = centeredCollectionViewFlowLayout.currentCenteredPage
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        recalculateClusterEmoji(scrollView)
    }
    
    func recalculateClusterEmoji(_ scrollView: UIScrollView) {
        guard let index = centeredCollectionViewFlowLayout.currentCenteredPage else { return }
        glyphText = sortedMemberPosts[index].topEmoji
    }
    
}
