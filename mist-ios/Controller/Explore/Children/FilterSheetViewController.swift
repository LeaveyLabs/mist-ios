//
//  FilterSheetViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/16/22.
//

import Foundation
import UIKit

protocol FilterDelegate {
    func handleUpdatedExploreFilter()
}

class FilterSheetViewController: UIViewController {
        
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var trendingButton: ToggleButton!
    @IBOutlet weak var bestButton: ToggleButton!
    @IBOutlet weak var newButton: ToggleButton!
//    @IBOutlet weak var refreshButton: UIButton!

    @IBOutlet weak var backgroundView: UIView!

    var filterDelegate: FilterDelegate!
    
    class func create(delegate: FilterDelegate) -> FilterSheetViewController {
        let filterSheetVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Filter) as! FilterSheetViewController
        filterSheetVC.filterDelegate = delegate
        return filterSheetVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundView()
        
        newButton.selectedImage = UIImage.init(systemName: "clock.fill")!
        newButton.notSelectedImage = UIImage.init(systemName: "clock")!
        newButton.selectedTitle = "new"
        newButton.notSelectedTitle = "new"
        
        bestButton.selectedImage = UIImage.init(systemName: "star.fill")!
        bestButton.notSelectedImage = UIImage.init(systemName: "star")!
        bestButton.selectedTitle = "best"
        bestButton.notSelectedTitle = "best"

        trendingButton.selectedImage = UIImage.init(systemName: "flame.fill")!
        trendingButton.notSelectedImage = UIImage.init(systemName: "flame")!
        trendingButton.selectedTitle = "trending"
        trendingButton.notSelectedTitle = "trending"
        
        switch PostService.singleton.getExploreFilter().postSort {
        case .RECENT:
            newButton.isSelected = true
//            newButton.backgroundColor = .green
        case .BEST:
            bestButton.isSelected = true
//            bestButton.backgroundColor = .yellow
        case .TRENDING:
            trendingButton.isSelected = true
//            trendingButton.backgroundColor = .red
        }
    }
    
    func setupBackgroundView() {
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(closeButtonDidPressed(_:)))
        view.addGestureRecognizer(dismissTap)
        backgroundView.layer.cornerRadius = 10
        backgroundView.layer.cornerCurve = .continuous
        backgroundView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
    
    func deselectAllButtons() {
        newButton.isSelected = false
        bestButton.isSelected = false
        trendingButton.isSelected = false
    }
    
    //MARK: - User Interaction
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func trendingButtonDidPressed(_ sender: UIButton) {
        PostService.singleton.updateFilter(newPostSort: .TRENDING)
        filterDelegate.handleUpdatedExploreFilter()
        deselectAllButtons()
        trendingButton.isSelected = true
        view.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func bestButtonDidPressed(_ sender: UIButton) {
        PostService.singleton.updateFilter(newPostSort: .BEST)
        filterDelegate.handleUpdatedExploreFilter()
        deselectAllButtons()
        bestButton.isSelected = true
        view.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func newButtonDidPressed(_ sender: UIButton) {
        PostService.singleton.updateFilter(newPostSort: .RECENT)
        filterDelegate.handleUpdatedExploreFilter()
        deselectAllButtons()
        newButton.isSelected = true
        view.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.dismiss(animated: true)
        }
    }
    
}