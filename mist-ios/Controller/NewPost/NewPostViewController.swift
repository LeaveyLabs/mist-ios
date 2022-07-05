//
//  WritePostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit
import CoreLocation
import MapKit

let BODY_PLACEHOLDER_TEXT = "Pour your heart out"
let TITLE_PLACEHOLDER_TEXT = "A cute title"
let LOCATION_PLACEHOLDER_TEXT = "Drop a pin"
let TEXT_LENGTH_BEYOND_MAX_PERMITTED = 5

let TITLE_CHARACTER_LIMIT = 40
let BODY_CHARACTER_LIMIT = 999

let PROGRESS_DEFAULT_DURATION: Double = 6 // Seconds
let PROGRESS_DEFAULT_MAX: Float = 0.8 // 80%

class NewPostViewController: KUIViewController, UITextViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var postBubbleView: UIView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dateLabelWrapperView: UIView! // To add padding around dateLabel to shrink its size
    @IBOutlet weak var timeLabelWrapperView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet var titleTextView: NewPostTextView!
    @IBOutlet var bodyTextView: NewPostTextView!
    var titlePlaceholderLabel: UILabel!
    var bodyPlaceholderLabel: UILabel!
    var textViewToolbar: UIToolbar?
    
    var currentlyPinnedAnnotation: PostAnnotation? {
        didSet {
            if let newAnnotation = currentlyPinnedAnnotation {
                locationButton.setTitle(newAnnotation.title, for: .normal)
                locationButton.setTitleColor(.black, for: .normal)
                locationButton.tintColor = .black
            } else {
                locationButton.setTitle(LOCATION_PLACEHOLDER_TEXT, for: .normal)
                locationButton.setTitleColor(.placeholderText, for: .normal)
                locationButton.tintColor = .placeholderText
            }
            validateAllFields()
        }
    }
    var hasUserTappedDateLabel: Bool = false {
        didSet {
            if hasUserTappedDateLabel {
                let (date, _) = getDateAndTimeForNewPost(selectedDate: datePicker.date)
                dateLabel.text = date
                dateLabel.textColor = .black
            }
            validateAllFields()
        }
    }
    var hasUserTappedTimeLabel: Bool = false {
        didSet {
            if hasUserTappedTimeLabel {
                let (_, time) = getDateAndTimeForNewPost(selectedDate: datePicker.date)
                timeLabel.text = time
                timeLabel.textColor = .black
            }
            validateAllFields()
        }
    }
    var postStartTime: DispatchTime?
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var postButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationButton()
        postBubbleView.transformIntoPostBubble(arrowPosition: .right)
        setupDatePicker()
        setupDatePicker()
        setupProgressView()
        validateAllFields()
        setupTextViews()
        loadFromNewPostContext() //should come after setting up views
        shouldKUIViewKeyboardDismissOnBackgroundTouch = true
   }
    
    // MARK: - Setup
    
    func loadFromNewPostContext() {
        datePicker.date = Date(timeIntervalSince1970: NewPostContext.timestamp ?? Date().timeIntervalSince1970)
        currentlyPinnedAnnotation = NewPostContext.annotation
        titleTextView.text = NewPostContext.title
        bodyTextView.text = NewPostContext.body
        hasUserTappedTimeLabel = NewPostContext.hasUserTappedTimeLabel
        hasUserTappedDateLabel = NewPostContext.hasUserTappedDateLabel
        
        //Extra checks necessary after updating the textView's text
        bodyPlaceholderLabel.isHidden = !bodyTextView.text.isEmpty
        titlePlaceholderLabel.isHidden = !titleTextView.text.isEmpty
    }
    
    func saveToNewPostContext() {
        NewPostContext.title = titleTextView.text
        NewPostContext.body = bodyTextView.text
        NewPostContext.timestamp = datePicker.date.timeIntervalSince1970
        NewPostContext.annotation = currentlyPinnedAnnotation
        NewPostContext.hasUserTappedDateLabel = hasUserTappedDateLabel
        NewPostContext.hasUserTappedTimeLabel = hasUserTappedTimeLabel
    }
    
    func setupTextViews() {
        titleTextView.delegate = self
        titleTextView.initializerToolbar(target: self, doneSelector: #selector(dismissKeyboard))
        titleTextView.textContainer.lineFragmentPadding = 0 //fixes textview strange leading offset
        titlePlaceholderLabel = titleTextView.addAndReturnPlaceholderLabelTwo(withText: TITLE_PLACEHOLDER_TEXT)
        titleTextView.maxLength = TITLE_CHARACTER_LIMIT
        titleTextView.becomeFirstResponder()
        
        bodyTextView.delegate = self
        bodyTextView.initializerToolbar(target: self, doneSelector: #selector(dismissKeyboard))
        bodyTextView.textContainer.lineFragmentPadding = 0 //fixes textview strange leading offset
        bodyPlaceholderLabel = bodyTextView.addAndReturnPlaceholderLabelTwo(withText: BODY_PLACEHOLDER_TEXT)
        bodyTextView.maxLength = BODY_CHARACTER_LIMIT
    }
    
    // Can't use new button with buttonConfiguration because you can't limit the number of lines
    // https://developer.apple.com/forums/thread/699622?login=true#reply-to-this-question
    func setupLocationButton() {
        locationButton.layer.cornerRadius = 10
        locationButton.layer.cornerCurve = .continuous
        locationButton.setImageToRightSide()
        
        //shadow button
        locationButton.applyLightShadow()
        locationButton.tintColor = .placeholderText
        locationButton.setTitleColor(.placeholderText, for: .normal)
    }
    
    func setupDatePicker() {
        // Max date: today. Min date: 1 month ago
        datePicker.maximumDate = .now
        datePicker.minimumDate = Calendar.current.date(byAdding: .month,
                                                       value: -1,
                                                       to: Date())
        dateLabelWrapperView.layer.cornerRadius = 10
        dateLabelWrapperView.layer.cornerCurve = .continuous
        dateLabelWrapperView.layer.masksToBounds = true //necessary for curving edges
        timeLabelWrapperView.layer.cornerRadius = 10
        timeLabelWrapperView.layer.cornerCurve = .continuous
        timeLabelWrapperView.layer.masksToBounds = true //necessary for curving edge
        
        dateLabel.text = "Day"
        timeLabel.text = "Time"
        
        //shadow button
        dateLabelWrapperView.applyLightShadow()
        timeLabelWrapperView.applyLightShadow()
        dateLabelWrapperView.backgroundColor = mistSecondaryUIColor()
        timeLabelWrapperView.backgroundColor = mistSecondaryUIColor()
        dateLabel.textColor = .placeholderText
        timeLabel.textColor = .placeholderText
    }
    
    func setupProgressView() {
        progressView.isHidden = true
    }

    // MARK: - User Interaction
    
    @objc func presentExplanationVC() {
        performSegue(withIdentifier: Constants.SBID.Segue.ToExplain, sender: self)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        let (date, time) = getDateAndTimeForNewPost(selectedDate: datePicker.date)
        if hasUserTappedDateLabel {
            dateLabel.text = date
        }
        if hasUserTappedTimeLabel {
            timeLabel.text = time
        }
    }
    
    @IBAction func datePickerEditingBegin(_ sender: Any, forEvent event: UIEvent) {
        let isTapWithinDateLabel = true
        let isTapWithinTimeLabel = true
        hasUserTappedDateLabel = isTapWithinDateLabel || hasUserTappedDateLabel
        hasUserTappedTimeLabel = isTapWithinTimeLabel || hasUserTappedTimeLabel
        // Could add code to determine which label was pressed aka which label to highlight
        // To do this, set user interaction of labels/uiview to yes, and then manually pass the touch event through
        //https://stackoverflow.com/questions/2793242/detect-if-certain-uiview-was-touched-amongst-other-uiviews
    }
    
    @IBAction func cancelButtonDidPressed(_ sender: UIBarButtonItem) {
        let hasMadeEdits = !bodyTextView.text.isEmpty || !titleTextView.text.isEmpty || currentlyPinnedAnnotation != nil || hasUserTappedDateLabel == true || hasUserTappedTimeLabel == true
        if hasMadeEdits {
            CustomSwiftMessages.showAlert(onDiscard: {
                NewPostContext.clear()
                self.dismiss(animated: true)
            }, onSave: { [self] in
                saveToNewPostContext()
                self.dismiss(animated: true)
            })
        } else {
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func userDidTappedPostButton(_ sender: UIButton) {
        guard let trimmedTitleText = titleTextView?.text.trimmingCharacters(in: .whitespaces) else { return }
        guard let trimmedBodyText = bodyTextView?.text.trimmingCharacters(in: .whitespaces) else { return }
        guard let locationText = locationButton.titleLabel?.text else { return }
        guard let annotation = currentlyPinnedAnnotation else { return }
        setAllInteractionTo(false)
        scrollView.scrollToTop()
        view.endEditing(true)
        animateProgressBar()
        Task {
            do {
                //We need to reset the filter and reload posts before uploading because uploading the post will immediately insert it at index 0 of explorePosts
                PostService.singleton.resetFilter()
                try await PostService.singleton.loadExplorePosts()
                try await PostService.singleton.uploadPost(title: trimmedTitleText, text: trimmedBodyText, locationDescription: locationText, latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, timestamp: datePicker.date.timeIntervalSince1970)
                handleSuccessfulNewPost()
            } catch {
                progressView.progress = 0
                setAllInteractionTo(true)
                CustomSwiftMessages.displayError(error)
            }
        }
    }
    
    func handleSuccessfulNewPost() {
        let tbc = presentingViewController as! UITabBarController
        tbc.selectedIndex = 0
        let homeNav = tbc.selectedViewController as! UINavigationController
        let homeExplore = homeNav.topViewController as! ExploreViewController
        
        finishAnimationProgress() {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                homeExplore.makeMapVisible()
                self.dismiss(animated: true) {
                    homeExplore.handleNewlySubmittedPost()
               }
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Prepare for PinMapVC Segue
        if let pinMapVC = segue.destination as? PinMapViewController {
            pinMapVC.pinnedAnnotation = currentlyPinnedAnnotation // Load the currently pinned annotation, if one exists
            pinMapVC.completionHandler = { [self] (newAnnotation) in
                currentlyPinnedAnnotation = newAnnotation
            }
        }
    }
    
    //MARK: - TextView
        
    func textViewDidChange(_ textView: UITextView) {
        // UITextView has a quirk when last char is a newline...
        //  its size is not updated until another char is entered
        //  so, this will force the textView to scroll down
        if let selectedRange = textView.selectedTextRange,
           let txt = textView.text,
           !txt.isEmpty,
           txt.last == "\n" {
            let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            if cursorPosition == txt.count {
                
                scrollView.scrollToBottom(animated: false)
            }
        }
        
        if textView == bodyTextView {
            bodyPlaceholderLabel.isHidden = !bodyTextView.text.isEmpty
            bodyTextView.updateProgress()
        } else {
            titlePlaceholderLabel.isHidden = !titleTextView.text.isEmpty
            titleTextView.updateProgress()
        }
        validateAllFields()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Don't allow " " as first character
        if text == " " && textView.text.count == 0 {
            return false
        }
        if text == "\n" {
            // Don't allow newline in title. Instead, skip to bodyTextView
            if textView == titleTextView {
                bodyTextView.becomeFirstResponder()
                return false
            } else {
                return textView.shouldAllowNewline(in: textView.text, at: range.location)
            }
        }
        
        // Only return true if the length of text is within the limit
        let newPostTextView = textView as! NewPostTextView
        return textView.shouldChangeTextGivenMaxLengthOf(newPostTextView.maxLength + TEXT_LENGTH_BEYOND_MAX_PERMITTED, range, text)
    }
    
    //MARK: - Util
    
    func animateProgressBar() {
        progressView.isHidden = false
        progressView.setProgress(PROGRESS_DEFAULT_MAX, animated: false)
        postStartTime = DispatchTime.now()
        UIView.animate(withDuration: PROGRESS_DEFAULT_DURATION,
                       delay: 0,
                       options: .curveLinear) {
            self.progressView.layoutIfNeeded()
        }
    }
    
    // progressView animation could not easily be paused and resume like other animations...
    //... so I had to finesse a little.
    func finishAnimationProgress(completion: @escaping () -> Void) {
        // Pause the progress view at its current progress
        let elapsedTime = (DispatchTime.now().uptimeNanoseconds - postStartTime!.uptimeNanoseconds) / 1_000_000_000
        let currentProgress = min(PROGRESS_DEFAULT_MAX,
                                  PROGRESS_DEFAULT_MAX * Float((Double(elapsedTime)+0.1) / PROGRESS_DEFAULT_DURATION))
        progressView.setProgress(currentProgress, animated: false)
        progressView.layoutIfNeeded()

        // Cancel the animation
        progressView.subviews.forEach { view in
           view.layer.removeAllAnimations()
       }
        // Continue to fully loaded
        progressView.setProgress(1, animated: false)
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       options: .curveLinear) {
            self.progressView.layoutIfNeeded()
        } completion: { bool in
            completion()
        }

    }
    
    func clearAllFields() {
        progressView.progress = 0
        bodyTextView.text = ""
        titleTextView.text = ""
        bodyPlaceholderLabel.isHidden = false
        titlePlaceholderLabel.isHidden = false
        progressView.isHidden = true
        progressView.progress = 0.01
        locationButton.titleLabel?.text = LOCATION_PLACEHOLDER_TEXT
        datePicker.date = Date()
    }
    
    func setAllInteractionTo(_ shouldBeEnabled: Bool) {
        postButton.isEnabled = shouldBeEnabled
        locationButton.isEnabled = shouldBeEnabled
        datePicker.isEnabled = shouldBeEnabled
        titleTextView.isEditable = shouldBeEnabled
        bodyTextView.isEditable = shouldBeEnabled
    }
    
    //my guess is it had something to do with this validate all fields
    func validateAllFields() {
        postButton.isEnabled = bodyTextView.text.count != 0 && bodyTextView.text.count <= bodyTextView.maxLength && titleTextView.text.count != 0 && titleTextView.text.count <= titleTextView.maxLength && currentlyPinnedAnnotation != nil && hasUserTappedDateLabel && hasUserTappedTimeLabel
    }
}
