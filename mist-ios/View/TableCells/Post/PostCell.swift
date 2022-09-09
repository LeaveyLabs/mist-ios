//
//  PostCellTwo.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/19/22.
//

import UIKit

class PostCell: UITableViewCell {
    
    var postView: PostView!
    var topConstraint: NSLayoutConstraint!
    var bottomConstraint: NSLayoutConstraint!
    
    //MARK: - Public Interface
    
    func configurePostCell(post: Post, nestedPostViewDelegate: PostDelegate, bubbleTrianglePosition: BubbleTrianglePosition, isWithinPostVC: Bool, updatedCommentCount: Int? = nil) {
        topConstraint.constant = isWithinPostVC ? 5 : 25
        bottomConstraint.constant = isWithinPostVC ? -20 : -10
        UIView.performWithoutAnimation { //this is necessary with our current approach to the input accessory view and keyboardlayoutguide. tableview ends up getting animated, but that creates weird animations for the cells, too. so dont allow the cell updates to animate
            postView.configurePost(post: post, delegate: nestedPostViewDelegate, updatedCommentCount: updatedCommentCount) //must come after setting constraints
        }
    }
    
    //MARK: - Suggestion TableViewCell

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: Constants.SBID.Cell.Post)
        
        selectionStyle = .none
        separatorInset = .init(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        
        postView = PostView()
        postView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(postView)
        topConstraint = postView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 25)
        bottomConstraint = postView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        topConstraint.priority = .defaultHigh
        bottomConstraint.priority = .defaultHigh //in order to prevent conflicts with "UIView-Encapsulated-Layout-Height" of cell's contentView upon initial load
        NSLayoutConstraint.activate([
            postView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -52),
            postView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 2),
            topConstraint,
            bottomConstraint
        ])
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
