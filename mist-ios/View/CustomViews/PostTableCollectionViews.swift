//
//  PostTableCollectionViews.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/27/22.
//

import Foundation

//So that button presses do not prevent scrolling
class PostCollectionView: UICollectionView {
    
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view is UIButton {
            return true
        }
        return super.touchesShouldCancel(in: view)
    }
    
}

class PostTableView: UITableView {
    
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view is UIButton {
            return true
        }
        return super.touchesShouldCancel(in: view)
    }
    
}
