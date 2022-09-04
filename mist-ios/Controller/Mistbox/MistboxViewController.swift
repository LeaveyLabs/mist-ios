//
//  MistboxViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/29/22.
//

import Foundation
import UIKit
import ScalingCarousel

var blurAnimator: UIViewPropertyAnimator!


class CodeCell: ScalingCarouselCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        mainView = UIView(frame: contentView.bounds)
        contentView.addSubview(mainView)
        mainView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MistboxViewController: UIViewController {
    
    // MARK: - Properties
    fileprivate var scalingCarousel: ScalingCarouselView!
    
    var mistboxPosts: [Post] {
        PostService.singleton.getExplorePosts()
    }
    var keywordsView: UIView!
    var mistCountLabel: UILabel!
    var learnMoreButton: UIButton!
    var titleLabel: UILabel!

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addCarousel()
    }
    
    // MARK: - Configuration
    
    private func addCarousel() {
        
        let frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        scalingCarousel = ScalingCarouselView(withFrame: frame, andInset: 20)
        scalingCarousel.scrollDirection = .horizontal
        scalingCarousel.dataSource = self
        scalingCarousel.delegate = self
        scalingCarousel.translatesAutoresizingMaskIntoConstraints = false
//        scalingCarousel.register(CodeCell.self, forCellWithReuseIdentifier: "cell")
        scalingCarousel.register(ClusterCarouselCell.self, forCellWithReuseIdentifier: "cell")

        // Constraints
        view.addSubview(scalingCarousel)
        scalingCarousel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        scalingCarousel.heightAnchor.constraint(equalToConstant: 300).isActive = true
        scalingCarousel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scalingCarousel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
}

extension MistboxViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mistboxPosts.count
    }
    


    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let scalingCell = cell as? ClusterCarouselCell {
            scalingCell.configureForPost(post: mistboxPosts[indexPath.row], nestedPostViewDelegate: self, bubbleTrianglePosition: .left)
            
//            let blurEffect = UIBlurEffect(style: style)
//            let blurEffectView = UIVisualEffectView(effect: blurEffect)
//            blurEffectView.frame = bounds
//            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//            addSubview(blurEffectView)
//
            
            
            
        }
        DispatchQueue.main.async {
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        }

        return cell
    }
}

extension UIView {
    
    @objc func blurBackground(style: UIBlurEffect.Style, fallbackColor: UIColor) {
        if !UIAccessibility.isReduceTransparencyEnabled {
            self.backgroundColor = .clear

            let blurEffect = UIBlurEffect(style: style)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            //always fill the view
            blurEffectView.frame = self.self.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            self.insertSubview(blurEffectView, at: 0)
        } else {
            self.backgroundColor = fallbackColor
        }
    }

}

extension MistboxViewController: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scalingCarousel.didScroll()
    }
    
}

extension MistboxViewController: PostDelegate {
    
    func handleVote(postId: Int, emoji: String, action: VoteAction) {
         
    }
    
    func handleCommentButtonTap(postId: Int) {
         
    }
    
    func handleBackgroundTap(postId: Int) {
         
    }
    
    func handleDeletePost(postId: Int) {
         
    }
    
    func handleReactTap(postId: Int) {
         
    }
    
    
}
