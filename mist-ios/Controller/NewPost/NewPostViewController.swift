//
//  WritePostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit
import CoreLocation
import MapKit

let BODY_PLACEHOLDER_TEXT = "To the barista at Starbucks..."
let TITLE_PLACEHOLDER_TEXT = "A cute title"
let LOCATION_PLACEHOLDER_TEXT = "Drop a pin"

struct NewPostCache {
    static var annotation: PostAnnotation?
    static var timestamp: Double?
    static var title: String?
    static var body: String?
    
    static func clear() {
        annotation = nil
        timestamp = nil
        title = nil
        body = nil
    }
}

//TODO: allow user to scroll through their post if their post is really long while keyboard is up

class NewPostViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var postBubbleView: UIView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dateLabelWrapperView: UIView! // To add padding around dateLabel to shrink its size
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var bodyTextView: UITextView!
    var titlePlaceholderLabel: UILabel!
    var bodyPlaceholderLabel: UILabel!
    
    var currentlyPinnedAnnotation: PostAnnotation?
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var postButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadNewPostCache()
        postBubbleView.transformIntoPostBubble(arrowPosition: .right)
        setupTextViews()
        setupLocationButton()
        setupDatePicker()
        setupDatePicker()
        setupProgressView()
   }
    
    // MARK: - Setup
    
    func loadNewPostCache() {
        datePicker.date = Date(timeIntervalSince1970: NewPostCache.timestamp ?? Date().timeIntervalSince1970)
        currentlyPinnedAnnotation = NewPostCache.annotation
        titleTextView.text = NewPostCache.title
        bodyTextView.text = NewPostCache.body
    }
    
    func setupTextViews() {
        titleTextView.delegate = self
        titleTextView.addNewPostToolbar(target: self, selector: #selector(presentExplanationVC))
        titleTextView.textContainer.lineFragmentPadding = 0 //fixes textview strange leading offset
        titlePlaceholderLabel = titleTextView.addAndReturnPlaceholderLabelTwo(withText: TITLE_PLACEHOLDER_TEXT)
        titleTextView.becomeFirstResponder()

        bodyTextView.delegate = self
        bodyTextView.addNewPostToolbar(target: self, selector: #selector(presentExplanationVC))
        bodyTextView.textContainer.lineFragmentPadding = 0 //fixes textview strange leading offset
        bodyPlaceholderLabel = bodyTextView.addAndReturnPlaceholderLabelTwo(withText: BODY_PLACEHOLDER_TEXT)
    }
    
    // Can't use new button with buttonConfiguration because you can't limit the number of lines
    // https://developer.apple.com/forums/thread/699622?login=true#reply-to-this-question
    func setupLocationButton() {
        locationButton.layer.cornerRadius = 10
        locationButton.layer.cornerCurve = .continuous
    }
    
    func setupDatePicker() {
        datePicker.maximumDate = .now

        dateLabelWrapperView.layer.cornerRadius = 10
        dateLabelWrapperView.layer.cornerCurve = .continuous
        dateLabelWrapperView.layer.masksToBounds = true //necessary for curving edges
        timeLabel.layer.cornerRadius = 10
        timeLabel.layer.cornerCurve = .continuous
        timeLabel.layer.masksToBounds = true //necessary for curving edges
        
        let (date, time) = getDateAndTimeForNewPost(selectedDate: datePicker.date)
        dateLabel.text = date
        timeLabel.text = time
    }
    
    func setupProgressView() {
        progressView.isHidden = true
    }

    // MARK: - User Interaction
    
    @objc func presentExplanationVC() {
        view.endEditing(true)
    }
    
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        let (date, time) = getDateAndTimeForNewPost(selectedDate: datePicker.date)
        dateLabel.text = date
        timeLabel.text = time
    }
    
    @IBAction func datePickerEditingBegin(_ sender: Any, forEvent event: UIEvent) {
        // Could add code to determine which label was pressed aka which label to highlight
        // To do this, set user interaction of labels/uiview to yes, and then manually pass the touch event through
        // https://stackoverflow.com/questions/2793242/detect-if-certain-uiview-was-touched-amongst-other-uiviews
    }
    
    @IBAction func outerViewGestureDidTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @IBAction func cancelButtonDidPressed(_ sender: UIBarButtonItem) {
        CustomSwiftMessages.showAlert(onDiscard: {
            NewPostCache.clear()
            self.dismiss(animated: true)
        }, onSave: { [self] in
            NewPostCache.title = titleTextView.text
            NewPostCache.body = bodyTextView.text
            NewPostCache.timestamp = datePicker.date.timeIntervalSince1970
            NewPostCache.annotation = currentlyPinnedAnnotation
            self.dismiss(animated: true)
        })
    }
    
    @IBAction func userDidTappedPostButton(_ sender: UIButton) {
        animateProgressBar()
        Task {
            do {
                let syncedPost = try await UserService.singleton.uploadPost(title: titleTextView.text!,
                                                                        text: bodyTextView.text!,
                                                                        locationDescription: locationButton.titleLabel!.text!,
                                                                        latitude: currentlyPinnedAnnotation!.coordinate.latitude,
                                                                        longitude: currentlyPinnedAnnotation!.coordinate.longitude,
                                                                        timestamp: datePicker.date.timeIntervalSince1970)
                // Post was a success! Now navigate to ExploreMap and handle the new post
                let tbc = tabBarController
                tbc!.selectedIndex = 0
                let homeNav = tbc!.selectedViewController as! UINavigationController
                let homeExplore = homeNav.visibleViewController as! ExploreMapViewController
                homeExplore.handleNewlySubmittedPost(syncedPost) { [weak self] in
                    self?.dismiss(animated: true)
                }
            } catch {
                CustomSwiftMessages.showError(errorDescription: error.localizedDescription)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Prepare for PinMapVC Segue
        if let pinMapVC = segue.destination as? PinMapViewController {
            pinMapVC.pinnedAnnotation = currentlyPinnedAnnotation // Load the currently pinned annotation, if one exists
            pinMapVC.completionHandler = { [self] (newAnnotation, newDescription) in //TODO: delete newDescription with refactor
                currentlyPinnedAnnotation = newAnnotation
                locationButton!.setTitle(newAnnotation.title, for: .normal)
                validateAllFields()
            }
        }
        // Don't prepare for RulesVC Segue
    }
    
    //MARK: - TextView
    
    func textViewDidChange(_ textView: UITextView) {
        bodyPlaceholderLabel.isHidden = !bodyTextView.text.isEmpty
        titlePlaceholderLabel.isHidden = !titleTextView.text.isEmpty
        validateAllFields()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Don't allow user to press "return" in title
        if textView == titleTextView && text == "\n" {
            bodyTextView.becomeFirstResponder()
            return false
        }
        return true
    }
    
    //MARK: - Util
    
    // Reference: https://stackoverflow.com/questions/23803464/uiview-animatewithduration-and-uiprogressview-setprogress
    func animateProgressBar() {
        progressView.isHidden = false
        UIView.animate(withDuration: 0.0, animations: {
            self.progressView.layoutIfNeeded()
        }, completion: { finished in
            self.progressView.progress = 1.0

            UIView.animate(withDuration: 5, delay: 0.0, options: [.curveLinear], animations: {
                self.progressView.layoutIfNeeded()
            }, completion: { finished in
                print("animation completed")
            })
        })
    }
    
    func clearAllFields() {
        bodyTextView.text = ""
        titleTextView.text = ""
        bodyPlaceholderLabel.isHidden = false
        titlePlaceholderLabel.isHidden = false
        progressView.isHidden = true
        progressView.progress = 0.01
        locationButton.titleLabel!.text = LOCATION_PLACEHOLDER_TEXT
        datePicker.date = Date()
    }
    
    func validateAllFields() {
        if bodyTextView.text! == "" ||
            titleTextView.text! == "" ||
            currentlyPinnedAnnotation == nil {
            postButton.isEnabled = false
        } else {
            postButton.isEnabled = true
        }
    }
}
