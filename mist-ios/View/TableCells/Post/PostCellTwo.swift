//
//  PostCellTwo.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/19/22.
//

import UIKit

class PostCellTwo: UITableViewCell {
    
    var postView: PostView!
    
    //MARK: - Public Interface
    
    func configurePostCell(post: Post, postDelegate: PostDelegate, bubbleTrianglePosition: BubbleTrianglePosition) {
        postView.postDelegate = postDelegate
        postView.backgroundBubbleButton.isUserInteractionEnabled = false
        postView.configurePost(post: post, bubbleTrianglePosition: bubbleTrianglePosition) //must come after setting constraints
    }
    
    //MARK: - Suggestion TableViewCell

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: "PostCellTwo")
        print("INIT")
        
        postView = PostView()
        postView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(postView)
        
        let verticalConstraints = [
            postView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15),
            postView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),]
        verticalConstraints.forEach { constraint in constraint.priority = .defaultHigh }
        NSLayoutConstraint.activate([
//            postView.heightAnchor.constraint(greaterThanOrEqualToConstant: 1), //the min height of PostView
            postView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -55),
            postView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 2),
            verticalConstraints[0],
            verticalConstraints[1],
        ])
    }
    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        print("AWAKE FROM NIB")
//
//        postView = PostView()
//        postView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(postView)
//
//        let verticalConstraints = [
//            postView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15),
//            postView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),]
//        verticalConstraints.forEach { constraint in constraint.priority = .defaultHigh }
//        NSLayoutConstraint.activate([
////            postView.heightAnchor.constraint(greaterThanOrEqualToConstant: 1), //the min height of PostView
//            postView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -55),
//            postView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 2),
//            verticalConstraints[0],
//            verticalConstraints[1],
//        ])
//    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        print("PREPARING FOR RESUSE")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print("LAYING OUT SUBVIEWS")
    }
    
}
