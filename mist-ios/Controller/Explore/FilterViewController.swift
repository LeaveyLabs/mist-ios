//
//  OkViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

protocol FilterDelegate {
    func reloadPostsAfterFilterUpdate(newPostFilter: PostFilter)
}

class FilterViewController: SheetViewController {
        
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var featuredButton: UIButton!
    @IBOutlet weak var friendsButton: UIButton!
    @IBOutlet weak var matchesButton: UIButton!
    @IBOutlet weak var dateSlider: UISlider!
    @IBOutlet weak var dateLabel: UILabel!
    
    var selectedFilter = PostFilter()
    var delegate: FilterDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.layer.cornerRadius = 5
        setupSheet(prefersGrabberVisible: true,
                   detents: [._detent(withIdentifier: "s", constant: 375)],
                   largestUndimmedDetentIdentifier: "s")
        
        updateHighlightedButtonText(for: selectedFilter.postType)
        updateDateLabel(for: selectedFilter.postType, with: dateSlider.value)
        dateSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
    }
    
    //MARK: - User Interaction
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                break
            case .moved:
                let prevDateText = dateLabel.text
                updateDateLabel(for: selectedFilter.postType, with: slider.value)
                selectedFilter.postTimeframe = slider.value
                if prevDateText != dateLabel.text {
                    setButtonActiveForFilter(selectedFilter.postType, newPostTimeframe: slider.value)
                }
            case .ended:
//                dismiss(animated: true)
                break
            default:
                break
            }
        }
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func sliderValueDidChanged(_ sender: UISlider) {
//        let sliderPostTimeframe = 0.0
    }
    

    @IBAction func allButtonDidPressed(_ sender: UIButton) {
        setButtonActiveForFilter(.All, newPostTimeframe: selectedFilter.postTimeframe)
        dismiss(animated: true)
    }
    
    @IBAction func featuredButtonDidPressed(_ sender: UIButton) {
        setButtonActiveForFilter(.Featured, newPostTimeframe: selectedFilter.postTimeframe)
        dismiss(animated: true)
    }
    
    @IBAction func friendsButtonDidPressed(_ sender: UIButton) {
        setButtonActiveForFilter(.Friends, newPostTimeframe: selectedFilter.postTimeframe)
        dismiss(animated: true)
    }
    
    @IBAction func matchesButtonDidPressed(_ sender: UIButton) {
        setButtonActiveForFilter(.Matches, newPostTimeframe: selectedFilter.postTimeframe)
        dismiss(animated: true)
    }
    
    func setButtonActiveForFilter(_ newPostType: PostType, newPostTimeframe: Float) {
        selectedFilter = PostFilter(postType: newPostType, postTimeframe: newPostTimeframe)
        updateHighlightedButtonText(for: newPostType)
        delegate.reloadPostsAfterFilterUpdate(newPostFilter: selectedFilter)
    }
    
    func updateDateLabel(for postType: PostType, with sliderValue: Float) {
        if selectedFilter.postType == .All {
            dateLabel.text = getDateFromSlider(indexFromZeroToOne: selectedFilter.postTimeframe,
                                               timescale: FilterTimescale.week,
                                               lowercase: false)
        } else {
            dateLabel.text = getDateFromSlider(indexFromZeroToOne: selectedFilter.postTimeframe,
                                               timescale: FilterTimescale.month,
                                               lowercase: false)
        }
    }
    
    func updateHighlightedButtonText(for postType: PostType) {
        let heavyAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Heavy, size: 24)!]
        let normalAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 24)!]
        
        // Unbold all button labels
        allButton.setAttributedTitle(NSMutableAttributedString(string: PostType.All.displayNameWithExtraSpace, attributes: normalAttributes), for: .normal)
        featuredButton.setAttributedTitle(NSMutableAttributedString(string: PostType.Featured.displayNameWithExtraSpace, attributes: normalAttributes), for: .normal)
        friendsButton.setAttributedTitle(NSMutableAttributedString(string: PostType.Friends.displayNameWithExtraSpace, attributes: normalAttributes), for: .normal)
        matchesButton.setAttributedTitle(NSMutableAttributedString(string: PostType.Matches.displayNameWithExtraSpace, attributes: normalAttributes), for: .normal)
        
        // Bold the selected button's label
        switch postType {
        case .All:
            allButton.setAttributedTitle(NSMutableAttributedString(string: PostType.All.displayNameWithExtraSpace, attributes: heavyAttributes), for: .normal)
        case .Featured:
            featuredButton.setAttributedTitle(NSMutableAttributedString(string: PostType.Featured.displayNameWithExtraSpace, attributes: heavyAttributes), for: .normal)
        case .Friends:
            friendsButton.setAttributedTitle(NSMutableAttributedString(string: PostType.Friends.displayNameWithExtraSpace, attributes: heavyAttributes), for: .normal)
        case .Matches:
            matchesButton.setAttributedTitle(NSMutableAttributedString(string: PostType.Matches.displayNameWithExtraSpace, attributes: heavyAttributes), for: .normal)
        }
    }
    
}
