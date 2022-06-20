//
//  PostCellTwo.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/19/22.
//

import UIKit

class PostCell: UITableViewCell {
    
    var postView: PostView!
    
    //MARK: - Public Interface
    
    func configurePostCell(post: Post, nestedPostViewDelegate: PostDelegate, bubbleTrianglePosition: BubbleTrianglePosition) {
        postView.postDelegate = nestedPostViewDelegate
        postView.configurePost(post: post, bubbleTrianglePosition: bubbleTrianglePosition) //must come after setting constraints
        ensureTapsDontPreventScrolling()
    }
    
    // We need to disable the backgroundButton and add a tapGestureRecognizer so that drags can be detected on the tableView. The purpose of the backgroundButton is to prevent taps from dismissing the calloutView when the post is within an annotation on the map
    func ensureTapsDontPreventScrolling() {
        postView.backgroundBubbleButton.isUserInteractionEnabled = false
        postView.likeLabelButton.isUserInteractionEnabled = false
        postView.backgroundBubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleCellBackgroundViewTap) ))
    }
    
    @objc func handleCellBackgroundViewTap() {
        postView.postDelegate?.handleBackgroundTap(post: postView.post)
    }
    
    //MARK: - Suggestion TableViewCell

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: Constants.SBID.Cell.Post)
        
        postView = PostView()
        postView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(postView)
        
        let verticalConstraints = [
            postView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15),
            postView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),]
        verticalConstraints.forEach { constraint in constraint.priority = .defaultHigh } //in order to prevent conflicts with "UIView-Encapsulated-Layout-Height" of cell's contentView upon initial load
        NSLayoutConstraint.activate([
            postView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -55),
            postView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 2),
            verticalConstraints[0],
            verticalConstraints[1],
        ])
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
