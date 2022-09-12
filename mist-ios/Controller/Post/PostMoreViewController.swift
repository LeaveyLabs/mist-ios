//
//  OkViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

class PostMoreViewController: UIViewController {
        
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var favoriteButton: ToggleButton!
    @IBOutlet weak var flagButton: ToggleButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var backgroundView: UIView!

    var postDelegate: PostDelegate!
    var postId: Int!
    var postAuthor: Int!
    
    @IBOutlet weak var superUserVoteInflationSlider: TapUISlider!
    @IBOutlet weak var superUserVoteInflationLabel: UILabel!
    
    class func create(postId: Int, postAuthor: Int, postDelegate: PostDelegate) -> PostMoreViewController {
        let postMoreVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.PostMore) as! PostMoreViewController
        postMoreVC.postId = postId
        postMoreVC.postAuthor = postAuthor
        postMoreVC.postDelegate = postDelegate
        postMoreVC.loadViewIfNeeded() //doesnt work without this function call
        return postMoreVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundView()
        
        if postAuthor != UserService.singleton.getId() {
            deleteButton.isHidden = true
        } else {
            flagButton.isHidden = true
        }
        
        flagButton.selectedImage = UIImage.init(systemName: "flag.fill")!
        flagButton.notSelectedImage = UIImage.init(systemName: "flag")!
        flagButton.selectedTitle = "flagged"
        flagButton.notSelectedTitle = "flag"
        favoriteButton.selectedImage = UIImage(systemName: "bookmark.fill")!
        favoriteButton.notSelectedImage = UIImage(systemName: "bookmark")!
        favoriteButton.selectedTitle = "favorited"
        favoriteButton.notSelectedTitle = "favorite"
        
        flagButton.isSelected = FlagService.singleton.hasFlaggedPost(postId)
        favoriteButton.isSelected = FavoriteService.singleton.hasFavoritedPost(postId)
        
        superUserVoteInflationSlider.value = Float(VoteService.singleton.getCastingVoteRating())
        superUserVoteInflationSlider.addTarget(self, action: #selector(onVoteInflationSliderValChanged(slider:event:)), for: .valueChanged)
        if UserService.singleton.isSuperuser() {
            superUserVoteInflationLabel.text = String(VoteService.singleton.getCastingVoteRating())
            superUserVoteInflationSlider.isHidden = false
            superUserVoteInflationLabel.isHidden = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        let longPress = UILongPressGestureRecognizer(target: self.slider, action: #selector(tapAndSlide(gesture: <#T##UILongPressGestureRecognizer#>)))
//        longPress.minimumPressDuration = 0
//        view.addGestureRecognizer(longPress)
    }
    
    func setupBackgroundView() {
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(closeButtonDidPressed(_:)))
        view.addGestureRecognizer(dismissTap)
        backgroundView.layer.cornerRadius = 10
        backgroundView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
    
    //MARK: - User Interaction
    
    @objc func onVoteInflationSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                handleSliderValChange()
            case .moved:
                handleSliderValChange()
            case .ended:
                handleSliderValChange()
                dismiss(animated: true)
            default:
                break
            }
        }
    }
    
    func handleSliderValChange() {
        superUserVoteInflationLabel.text = String(Int(superUserVoteInflationSlider.value))
        VoteService.singleton.updateInflatedVoteValue(to: Int(superUserVoteInflationSlider.value))
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func shareButton(_ sender: UIButton) {
        dismiss(animated: true) { [self] in
            postDelegate.presentShareActivityVC()
        }
    }
    
    @IBAction func favoriteButtonDidpressed(_ sender: UIButton) {
        // UI Updates
        favoriteButton.isEnabled = false
        favoriteButton.isSelected = !favoriteButton.isSelected
        
        // Remote and storage updates
        postDelegate?.handleFavorite(postId: postId, isAdding: favoriteButton.isSelected)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.favoriteButton.isEnabled = true
            self.dismiss(animated: true)
        }
    }
    
    
    
    @IBAction func reportButton(_ sender: UIButton) {
        // UI Updates
        flagButton.isEnabled = false
        flagButton.isSelected = !flagButton.isSelected
        
        // Remote and storage updates
        postDelegate?.handleFlag(postId: postId, isAdding: flagButton.isSelected)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.flagButton.isEnabled = true
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func deleteButtonDidPressed(_ sender: UIButton) {
        CustomSwiftMessages.showAlert(title: "delete this mist", body: "are you sure you want to delete this mist? this can't be undone.", emoji: "😟", dismissText: "nevermind", approveText: "delete", onDismiss: {
            
        }, onApprove: { [self] in
            deleteButton.isEnabled = false
            Task {
                do {
                    try await PostService.singleton.deletePost(postId: postId)
                    DispatchQueue.main.async { [self] in
                        dismiss(animated: true)
                        postDelegate.handleDeletePost(postId: postId)
                    }
                } catch {
                    CustomSwiftMessages.displayError(error)
                    DispatchQueue.main.async { [self] in
                        dismiss(animated: true)
                    }
                }
            }
        })
    }
}

class TapUISlider: UISlider {
    
    var trackRectWidth: CGFloat = 10
    var thumbRectHorizontalOffset: CGFloat = 0
    
     private var thumbFrame: CGRect {
         return thumbRect(forBounds: bounds, trackRect: trackRect(forBounds: bounds), value: value)
     }


    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        var newRect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        print(bounds, rect)
        newRect.origin.y = thumbRectHorizontalOffset
        return newRect
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
       var newBounds = super.trackRect(forBounds: bounds)
       newBounds.size.height = trackRectWidth
       return newBounds
    }
    
    @objc
    private func sliderTapped(touch: UITouch) {
        let point = touch.location(in: self)
        let percentage = Float(point.x / self.bounds.width)
        let delta = percentage * (self.maximumValue - self.minimumValue)
        let newValue = self.minimumValue + delta
        if newValue != self.value {
            value = newValue
            sendActions(for: .valueChanged)
        }
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        sliderTapped(touch: touch)
        return true
    }
    
}
