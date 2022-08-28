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
}

class ClusterAnnotationView: MKMarkerAnnotationView {
    
    //MARK: - Properties
    
    let centeredCollectionViewFlowLayout = CenteredCollectionViewFlowLayout()
    var collectionView: PostCollectionView?
    var postDelegate: PostDelegate?
    lazy var MAP_VIEW_WIDTH: Double = Double(mapView?.bounds.width ?? 350)
    lazy var POST_VIEW_WIDTH: Double = MAP_VIEW_WIDTH * 0.83
    lazy var POST_VIEW_MARGIN: Double = (MAP_VIEW_WIDTH - POST_VIEW_WIDTH) / 2
    let POST_VIEW_MAX_HEIGHT: Double = 400

    var mapView: MKMapView? {
        var view = superview
        while view != nil {
            if let mapView = view as? MKMapView { return mapView }
            view = view?.superview
        }
        return nil
    }
    
    var memberCount: Int? {
        return (annotation as? MKClusterAnnotation)?.memberAnnotations.count
    }
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let newCluster = newValue as? MKClusterAnnotation else {
                return }
            animatesWhenAdded = true
            canShowCallout = false
            setupMarkerTintColor(newCluster)
            displayPriority = .required
        }
    }
    
    
    
    //MARK: - Initialization
        
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupGestureRecognizerToPreventInteractionDelay()
        setupCarouselView()
        centerOffset = CGPoint(x: 0, y: -10) // Offset center point to animate better with marker annotations
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Setup
    
    func setupCarouselView() {
        
    }
    
    private func setupMarkerTintColor(_ clusterAnnotation: MKClusterAnnotation?) {
        guard let memberAnnotations: Int = clusterAnnotation?.memberAnnotations.count else { return }
        let totalNumberOfAnnotationsRendered: Int = mapView?.annotations.count ?? PostService.singleton.getExplorePostCount()
        let density = Double(memberAnnotations) / Double(totalNumberOfAnnotationsRendered)
        if density < 0.1 {
            markerTintColor = UIColor(hex: "#AE75F7")
        } else if density < 0.2 {
            markerTintColor = Constants.Color.mistPurple
        } else if density < 0.4 {
            markerTintColor = UIColor(hex: "#8D4BE2")
        } else {
            markerTintColor = Constants.Color.mistNight
        }
    }
    
    //MARK: - User Interaction
        
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            glyphTintColor = Constants.Color.mistLilac
            markerTintColor = Constants.Color.mistPink
            guard let collectionView = collectionView else { return }
            collectionView.removeFromSuperview() // This check shouldn't be needed, but just in case
        } else {
            print("DESELECTED!")
            glyphTintColor = .white
            setupMarkerTintColor(annotation as? MKClusterAnnotation)
            endEditing(true)
            guard let collectionView = collectionView else { return }
            collectionView.fadeOut(duration: 0.25, delay: 0, completion: { Bool in
                collectionView.isHidden = true
                collectionView.removeFromSuperview()
            })
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
        guard let currentpage = centeredCollectionViewFlowLayout.currentCenteredPage,
              let maxPages = memberCount else { return false }
        if pointInMapView.x > POST_VIEW_WIDTH + POST_VIEW_MARGIN, currentpage < maxPages - 1 {
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
    
    func loadCollectionView(on mapView: MKMapView, withPostDelegate postDelegate: ExploreViewController) {
        collectionView = PostCollectionView(centeredCollectionViewFlowLayout: centeredCollectionViewFlowLayout)
        guard let collectionView = collectionView else { return }
        self.postDelegate = postDelegate

        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)

        // register collection cells
        collectionView.register( ClusterCarouselCell.self, forCellWithReuseIdentifier: String(describing: ClusterCarouselCell.self))

        // configure layout
        centeredCollectionViewFlowLayout.itemSize = CGSize(
            width: POST_VIEW_WIDTH,
            height: POST_VIEW_MAX_HEIGHT
        )
        centeredCollectionViewFlowLayout.minimumLineSpacing = 20
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
                
        NSLayoutConstraint.activate([
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -70),
            collectionView.widthAnchor.constraint(equalTo: mapView.widthAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: POST_VIEW_MAX_HEIGHT + 15), //15 for the bottom arrow
            collectionView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
        ])
        
        collectionView.alpha = 0
        collectionView.isHidden = true
        collectionView.fadeIn(duration: 0.1, delay: 0)
    }
}

//MARK: - AnnotationViewWithPosts

extension ClusterAnnotationView: AnnotationViewWithPosts {
    
    //The callout is currently presented, and we want to update the postView's UI with the new data
    func rerenderCalloutForUpdatedPostData() {
        guard
            let page = centeredCollectionViewFlowLayout.currentCenteredPage,
            let collectionView = collectionView
        else { return }
        collectionView.reloadItems(at: [IndexPath(item: page, section: 0)])
    }
    
    func movePostUpAfterEmojiKeyboardRaised() {
        layoutIfNeeded()
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.constraints.first { $0.firstAnchor == self?.collectionView?.bottomAnchor }?.constant = -160
            self?.layoutIfNeeded()
        }
    }
        
    func movePostBackDownAfterEmojiKeyboardDismissed() {
        layoutIfNeeded()
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.constraints.first { $0.firstAnchor == self?.collectionView?.bottomAnchor }?.constant = -70
            self?.layoutIfNeeded()
        }
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
        let quickSelectGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(asdf))
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


//These are not being called for some reason
extension ClusterAnnotationView: UICollectionViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.endEditing(true)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        print("should")
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected Cell #\(indexPath.row)")
        if let currentCenteredPage = centeredCollectionViewFlowLayout.currentCenteredPage,
            currentCenteredPage != indexPath.row {
            centeredCollectionViewFlowLayout.scrollToPage(index: indexPath.row, animated: true)
        }
    }
        
}

extension ClusterAnnotationView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let clusterAnnotation = annotation as? MKClusterAnnotation else { return 0 }
        return clusterAnnotation.memberAnnotations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ClusterCarouselCell.self), for: indexPath) as! ClusterCarouselCell
        
        guard
            let clusterAnnotation = annotation as? MKClusterAnnotation,
            let postAnnotation = clusterAnnotation.memberAnnotations[indexPath.row] as? PostAnnotation,
            let postDelegate = postDelegate
        else { return cell }
        
        cell.configureForPost(post: postAnnotation.post, nestedPostViewDelegate: postDelegate, bubbleTrianglePosition: .bottom)
        
        //when the post is tapped, we want to FIRST make sure it's the currently centered one
        
        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("Did end decelerating. Current centered index: \(String(describing: centeredCollectionViewFlowLayout.currentCenteredPage ?? nil))")
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("Did end animation. Current centered index: \(String(describing: centeredCollectionViewFlowLayout.currentCenteredPage ?? nil))")
    }
}
