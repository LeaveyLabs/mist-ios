//
//  MistboxCollectionCell.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/4/22.
//

import Foundation

protocol MistboxCellDelegate {
    func didSkipMist(postId: Int)
    func didOpenMist(postId: Int)
}

class MistboxCollectionCell: UICollectionViewCell {
    
    var delegate: MistboxCellDelegate!
    var bottomConstraint: NSLayoutConstraint!
    var envelopeView = EnvelopeView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        envelopeView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(envelopeView)
        NSLayoutConstraint.activate([
            envelopeView.widthAnchor.constraint(equalToConstant: contentView.frame.height * EnvelopeView.envelopeImageWidthHeightRatio),
            envelopeView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 0),
            envelopeView.heightAnchor.constraint(equalToConstant: contentView.frame.height),
            envelopeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureForPost(post: Post, delegate: MistboxCellDelegate, panGesture: UIPanGestureRecognizer) {
        envelopeView.configureForPost(post: post, delegate: delegate, panGesture: panGesture)
    }
    
}
