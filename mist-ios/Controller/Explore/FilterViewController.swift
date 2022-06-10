//
//  OkViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

protocol FilterDelegate {
    func handleUpdatedFilter(_ newPostFilter: PostFilter, shouldReload: Bool, _ afterFilterUpdate: @escaping () -> Void)
}

class FilterViewController: SheetViewController {
        
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var featuredButton: UIButton!
    @IBOutlet weak var friendsButton: UIButton!
    @IBOutlet weak var matchesButton: UIButton!
    @IBOutlet weak var dateSlider: UISlider!
    @IBOutlet weak var dateLabel: UILabel!
    
    var selectedFilter: PostFilter!
    var delegate: FilterDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.layer.cornerRadius = 5
        
        //since zil is below 0, the user can only drag to zil if the line below is uncommented
//        isModalInPresentation = true //prevents the VC from being dismissed by the user
        
        setupSheet(prefersGrabberVisible: true,
                   detents: [._detent(withIdentifier: "s", constant: 250), Constants.Detents.zil], //tall=375, short=275
                   largestUndimmedDetentIdentifier: "zil") //zil size is useful for making transitions prettier
        
        updateButtonLabels()
        updateSliderLabel()
        dateSlider.value = selectedFilter.postTimeframe //update slider position
        dateSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
    }
    
    //MARK: - User Interaction
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                break
            case .moved:
                handleSliderValChange()
            case .ended:
                break
            default:
                break
            }
        }
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        delegate.handleUpdatedFilter(selectedFilter, shouldReload: false, {})
        dismiss(animated: true)
    }

    @IBAction func allButtonDidPressed(_ sender: UIButton) {
        handleButtonPress(.All)
    }
    
    @IBAction func featuredButtonDidPressed(_ sender: UIButton) {
        handleButtonPress(.Featured)
    }
    
    @IBAction func friendsButtonDidPressed(_ sender: UIButton) {
        handleButtonPress(.Friends)
    }
    
    @IBAction func matchesButtonDidPressed(_ sender: UIButton) {
        handleButtonPress(.Matches)
    }
    
    //MARK: - Helpers
    
    func handleSliderValChange() {
        selectedFilter.postTimeframe = dateSlider.value
        let prevDateText = dateLabel.text
        updateSliderLabel() //must come after selectedFilter is updated
        delegate.handleUpdatedFilter(selectedFilter, shouldReload: prevDateText != dateLabel.text, {})
    }
    
    func handleButtonPress(_ newPostType: PostType) {
        var needsSliderUpdate: Bool
        if selectedFilter.postType == .All {
            needsSliderUpdate = newPostType != .All
        } else {
            needsSliderUpdate = newPostType == .All
        }
        
        selectedFilter.postType = newPostType
        if needsSliderUpdate {
            dateSlider.value = 1
            selectedFilter.postTimeframe = dateSlider.value
            updateSliderLabel() //must come after selectedFilter and dateSlider is adjusted
        }

        updateButtonLabels() //must come after selectedFilter is updated
        delegate.handleUpdatedFilter(selectedFilter, shouldReload: true, {})
//        if !needsSliderUpdate {
//            dismiss(animated: true)
//        }
    }
    
    //MARK: - UI Updates
    
    func updateSliderLabel() {
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
    
    func updateButtonLabels() {
        let heavyAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Heavy, size: 24)!]
        let normalAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 24)!]
        
        // Unbold all button labels
        allButton.setAttributedTitle(NSMutableAttributedString(string: PostType.All.displayNameWithExtraSpace, attributes: normalAttributes), for: .normal)
        featuredButton.setAttributedTitle(NSMutableAttributedString(string: PostType.Featured.displayNameWithExtraSpace, attributes: normalAttributes), for: .normal)
        friendsButton.setAttributedTitle(NSMutableAttributedString(string: PostType.Friends.displayNameWithExtraSpace, attributes: normalAttributes), for: .normal)
        matchesButton.setAttributedTitle(NSMutableAttributedString(string: PostType.Matches.displayNameWithExtraSpace, attributes: normalAttributes), for: .normal)
        
        // Bold the selected button's label
        switch selectedFilter.postType {
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
