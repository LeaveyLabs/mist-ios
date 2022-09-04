//
//  PostCarouselCell.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/27/22.
//

import Foundation
import ScalingCarousel

class ClusterCarouselCell: ScalingCarouselCell {
    
    let postView = PostView()
    var bottomConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        mainView = postView
        postView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(postView)
        bottomConstraint = postView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15)
        NSLayoutConstraint.activate([
            postView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: 0),
            postView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 0),
            postView.heightAnchor.constraint(lessThanOrEqualTo: contentView.heightAnchor),
            bottomConstraint
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureForPost(post: Post, nestedPostViewDelegate: PostDelegate, bubbleTrianglePosition: BubbleTrianglePosition) {
        postView.configurePost(post: post, delegate: nestedPostViewDelegate, arrowPosition: .bottom) //must come after setting constraints
    }
    
    //todo for later
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
////        if let hitAnnotationView = super.hitTest(point, with: event) {
////            return hitAnnotationView
////        }
//
//        // If the hit wasn't MKClusterAnnotation, then the hit view must be on the carousel, the the classes's only subview
////        guard let collectionView = collectionView else { return nil }
//
//        let pointInPostView = convert(point, to: postView)
//        if let postView = postView.hitTest(pointInPostView, with: event) {
//            return postView
//        }
//        return nil
//
////        let pointInCollectionView = convert(point, to: collectionView)
////        return collectionView.hitTest(pointInCollectionView, with: event)
//    }
    
}
