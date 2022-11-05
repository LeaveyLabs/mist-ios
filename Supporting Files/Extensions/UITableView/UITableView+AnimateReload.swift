//
//  UITableView+AnimateReload.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/10/14.
//

import Foundation

extension UITableView {
    
    func reloadDataWithRowAnimation(_ animation: UITableView.RowAnimation) {
        reloadSections(IndexSet(integersIn: 0..<numberOfSections), with: animation)
    }
    
    func reloadDataWithViewAnimation(_ animation: UIView.AnimationOptions, duration: Double) {
        UIView.transition(with: self, duration: duration, options: animation, animations: {
            self.reloadData()
        }, completion: nil)
    }
    
}
