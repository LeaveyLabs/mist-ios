//
//  BadgesCell.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/6/22.
//

import UIKit

class BadgesCell: UITableViewCell {
    
//    var badges: [Post] {
//        return PostService.singleton.getSubmissions()
//    }
    
    //WILL IMPLEMENT THIS LATER
//    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var badgeBackground: UIView!
    @IBOutlet weak var badgeTitleLabel: UILabel!
    @IBOutlet weak var badgeIconLabel: UILabel!
    @IBOutlet weak var noBadgesLabel: UIView!
    
    var username: String = ""
    var badges: [String] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        badgeBackground.applyMediumShadow()
        badgeBackground.roundCornersViaCornerRadius(radius: 8)
        let badgeTap = UITapGestureRecognizer(target: self, action: #selector(badgeDidTapped))
        badgeBackground.addGestureRecognizer(badgeTap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupCollectionView() {
        
//        collectionView.delegate = self
//        collectionView.dataSource = self
//
//        // register collection cells
//        collectionView.register( ClusterCarouselCell.self, forCellWithReuseIdentifier: String(describing: ClusterCarouselCell.self))
//
////        UICollectionViewLayout
////        collectionView.itemsiz
//        // configure layout
////        centeredCollectionViewFlowLayout.itemSize = CGSize(
////            width: POST_VIEW_WIDTH,
////            height: POST_VIEW_MAX_HEIGHT - 20
////        )
//
////        centeredCollectionViewFlowLayout.minimumLineSpacing = 16
//        collectionView.showsVerticalScrollIndicator = false
//        collectionView.showsHorizontalScrollIndicator = false
    }
    
    func configureWith(username: String, badges: [String]) {
        if badges.isEmpty && username == UserService.singleton.getUsername() {
            noBadgesLabel.isHidden = false
            badgeBackground.isHidden = true
        } else {
            badgeBackground.isHidden = false
            noBadgesLabel.isHidden = true
            self.username = username
            self.badges = badges
            badgeIconLabel.text = "💌"
            badgeTitleLabel.text = "love, mist"
        }
    }
    
    @objc func badgeDidTapped() {
        CustomSwiftMessages.displayBadgePopup(name: username, badge: "💌")
    }
    
}

//extension BadgesCell: UICollectionViewDelegate, UICollectionViewDataSource {
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return 1 //badges.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        <#code#>
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
////        CustomSwiftMessages.showBadge
//    }
//}

