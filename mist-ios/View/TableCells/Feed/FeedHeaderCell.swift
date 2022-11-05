////
////  FeedHeaderCell.swift
////  mist-ios
////
////  Created by Adam Novak on 2022/03/13.
////
//
//import UIKit
//
//protocol FeedHeaderCellDelegate {
//    func handleFilterButtonPress()
//}
//
//class FeedHeaderCell: UITableViewCell {
//    
//    var delegate: FeedHeaderCellDelegate?
//
//    @IBOutlet weak var feedHeaderLabel: UILabel!
//    @IBOutlet weak var feedHeaderPreLabel: UILabel!
//    var feedType: ExploreFe?
//
//    override func awakeFromNib() {
//        super.awakeFromNib()
//    }
//    
//    @IBAction func filterButtonDidPressed(_ sender: UIButton) {
//        delegate?.handleFilterButtonPress()
//    }
//    
//}
