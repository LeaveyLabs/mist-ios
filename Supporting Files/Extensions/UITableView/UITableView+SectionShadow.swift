//
//  UITableView+SectionShadow.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/18/22.
//

import Foundation
import UIKit

extension UITableView {
    
    //apply shadow just to the tableView's sections, and not to the headers, too
    //perhaps another way around this issue is just to use a custom header view instead of the header text... anyways, this works for now
    
    //NOTE: this works for the explore search suggestions, since the uitableview will never be TOO long.
    //but for tableviews that could be very long, a new way of calculating the bacgkroundview's height is necessary
    
    //have to use exploreVC's view and not superview for this to work in explore search controller
    func setupTableViewSectionShadows(behindView: UIView, withBGColor bgColor: UIColor) {
        backgroundColor = .clear
        subviews.forEach { subview in
            subview.applyMediumShadow()
        }
                
        //setup white map cover to compensite for tableview's clear background.
        //make it much longer than the suggestion results tableview would ever be
        let tableViewExtraBackgroundView = UIView.init(frame: .init(x: behindView.frame.minX,
                                                     y: behindView.frame.minY - 500,
                                                     width: behindView.frame.width,
                                                     height: behindView.frame.height + 1000))
        tableViewExtraBackgroundView.backgroundColor = bgColor
        addSubview(tableViewExtraBackgroundView)
        sendSubviewToBack(tableViewExtraBackgroundView)
        
        //i couldnt get constraints to work for some reason
//        whiteMapCoverView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            whiteMapCoverView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 0),
//            whiteMapCoverView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
//            whiteMapCoverView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: -1),
//            whiteMapCoverView.centerXAnchor.constraint(equalTo: tableView.leftAnchor),
//        ])
    }
    
}
