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
                   detents: [._detent(withIdentifier: "s", constant: 260)],
                   largestUndimmedDetentIdentifier: "s")
        
        updateHighlightedButtonText(for: selectedFilter.postType)
        dateSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
    }
    
    //MARK: - Navigation
    
    func activityViewDidDismiss() {
        self.dismiss(animated: true)
    }
    
    //MARK: - User Interaction
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                break
            case .moved:
                let prevDateText = dateLabel.text
                dateLabel.text = getDateFromSlider(indexFromZeroToOne: slider.value)
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
    
    func updateHighlightedButtonText(for postType: PostType) {
        allButton.setAttributedTitle(NSAttributedString(string: "⭐️  All").withAttribute(.textColor(.gray)).withFont(UIFont(name: Constants.Font.Medium, size: 24)!), for: .normal)
        featuredButton.setAttributedTitle(NSAttributedString(string: "Featured").withAttribute(.textColor(.gray)).withFont(UIFont(name: Constants.Font.Medium, size: 24)!), for: .normal)
        friendsButton.setAttributedTitle(NSAttributedString(string: "👀  Friends").withAttribute(.textColor(.gray)).withFont(UIFont(name: Constants.Font.Medium, size: 24)!), for: .normal)
        matchesButton.setAttributedTitle(NSAttributedString(string: "💞  Matches").withAttribute(.textColor(.gray)).withFont(UIFont(name: Constants.Font.Medium, size: 24)!), for: .normal)
        
        switch postType {
        case .All:
            allButton.setAttributedTitle(NSAttributedString(string: "⭐️  All").withAttribute(.textColor(.black)).withFont(UIFont(name: Constants.Font.Heavy, size: 24)!), for: .normal)
        case .Featured:
            featuredButton.setAttributedTitle(NSAttributedString(string: "Featured").withAttribute(.textColor(.black)).withFont(UIFont(name: Constants.Font.Heavy, size: 24)!), for: .normal)
        case .Friends:
            friendsButton.setAttributedTitle(NSAttributedString(string: "👀  Friends").withAttribute(.textColor(.black)).withFont(UIFont(name: Constants.Font.Heavy, size: 24)!), for: .normal)
        case .Matches:
            matchesButton.setAttributedTitle(NSAttributedString(string: "💞  Matches").withAttribute(.textColor(.black)).withFont(UIFont(name: Constants.Font.Heavy, size: 24)!), for: .normal)
        }
    }
    
}
