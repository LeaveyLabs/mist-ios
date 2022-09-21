//
//  UITableView+DeselectAll.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/20/22.
//

import Foundation

extension UITableView {
    func deselectAllRows(inSection section: Int, animated: Bool) {
        guard let selectedRows = indexPathsForSelectedRows else { return }
        for indexPath in selectedRows {
            if indexPath.section == section {
                deselectRow(at: indexPath, animated: animated)
            }
        }
    }
    
    func getAllIndexPathsInSection(section : Int) -> [IndexPath] {
        let count = numberOfRows(inSection: section);
        return (0..<count).map { IndexPath(row: $0, section: section) }
    }
}
