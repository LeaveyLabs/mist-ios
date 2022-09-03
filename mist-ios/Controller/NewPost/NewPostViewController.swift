//
//  WritePostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit
import CoreLocation
import MapKit

let BODY_PLACEHOLDER_TEXT = "pour your heart out"
let TITLE_PLACEHOLDER_TEXT = "a cute title"
let LOCATION_PLACEHOLDER_TEXT = "current location"
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
        
    //TODO: add a "current location" option in search
    
    var currentlyPinnedPlacemark: MKPlacemark? {
        didSet {
            if let newPlacemark = currentlyPinnedPlacemark {
                locationButton.setTitle(newPlacemark.name?.lowercased(), for: .normal)
                locationButton.setImage(UIImage(systemName: "mappin.circle", withConfiguration: UIImage.SymbolConfiguration(scale: .medium)), for: .normal)
            } else {
                locationButton.setTitle(LOCATION_PLACEHOLDER_TEXT, for: .normal)
                locationButton.setImage(UIImage(systemName: "location", withConfiguration: UIImage.SymbolConfiguration(scale: .small)), for: .normal)
            }
            validateAllFields()
        }
    }
    var postStartTime: DispatchTime?
    
    //Progress
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var postButton: UIButton!
    
    // Search
    var mySearchController: UISearchController!
    var searchSuggestionsVC: SearchSuggestionsTableViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationButton()
        postBubbleView.transformIntoPostBubble(arrowPosition: .right)
        setupDatePicker()
        setupDatePicker()
        setupProgressView()
        validateAllFields()
        setupTextViews()
        setupSearchBar()
        loadFromNewPostContext() //should come after setting up views
//        shouldKUIViewKeyboardDismissOnBackgroundTouch = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)), style: .plain, target: self, action: #selector(cancelButtonDidPressed(_:)))
        titleTextView.becomeFirstResponder()
   }
    
    // MARK: - Setup
    
    func loadFromNewPostContext() {
        datePicker.date = Date(timeIntervalSince1970: NewPostContext.timestamp ?? Date().timeIntervalSince1970)
        currentlyPinnedPlacemark = NewPostContext.placemark
        titleTextView.text = NewPostContext.title
        bodyTextView.text = NewPostContext.body
        
        //Extra checks necessary after updating the textView's text
        bodyPlaceholderLabel.isHidden = !bodyTextView.text.isEmpty
        titlePlaceholderLabel.isHidden = !titleTextView.text.isEmpty
        
        NewPostContext.clear()
    }
    
    func saveToNewPostContext() {
        NewPostContext.title = titleTextView.text
        NewPostContext.body = bodyTextView.text
        NewPostContext.timestamp = datePicker.date.timeIntervalSince1970
        NewPostContext.placemark = currentlyPinnedPlacemark
    }
    
    func setupTextViews() {
        titleTextView.delegate = self
        titleTextView.initializerToolbar(target: self, doneSelector: #selector(dismissKeyboard))
        titleTextView.textContainer.lineFragmentPadding = 0 //fixes textview strange leading offset
        titlePlaceholderLabel = titleTextView.addAndReturnPlaceholderLabelTwo(withText: TITLE_PLACEHOLDER_TEXT)
        titleTextView.maxLength = TITLE_CHARACTER_LIMIT
        
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
//        locationButton.setImageToRightSide()
        locationButton.applyLightShadow()
//        locationButton.contentHorizontalAlignment = .center
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
        
        //shadow button
        dateLabelWrapperView.applyLightShadow()
        timeLabelWrapperView.applyLightShadow()
        dateLabelWrapperView.backgroundColor = Constants.Color.mistPink
        timeLabelWrapperView.backgroundColor = Constants.Color.mistPink
        
        updateDateTimeLabels(with: Date())
        datePicker.locale = Locale(identifier: "en_US") //this makes the underlying date picker button actually better fit the overlaying views
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
        updateDateTimeLabels(with: datePicker.date)
    }
    
    func updateDateTimeLabels(with newDate: Date) {
        let (date, time) = getDateAndTimeForNewPost(selectedDate: newDate)
        dateLabel.text = date.lowercased()
        timeLabel.text = time.lowercased()
    }
    
    @IBAction func cancelButtonDidPressed(_ sender: UIBarButtonItem) {
        let hasMadeEdits = !bodyTextView.text.isEmpty || !titleTextView.text.isEmpty || currentlyPinnedPlacemark != nil
        if hasMadeEdits {
            CustomSwiftMessages.showAlert(title: "would you like to save this post as a draft?", body: "", emoji: "🗑", dismissText: "no thanks", approveText: "save", onDismiss: {
                NewPostContext.clear()
                self.dismiss(animated: true)
            }, onApprove: {
                self.saveToNewPostContext()
                self.dismiss(animated: true)
            })
        } else {
            self.dismiss(animated: true)
        }
    }
        
    func tryToPost() {
        var postLocationCoordinate: CLLocationCoordinate2D?
        var postLocationText: String?
        if let userSetPlacemark = currentlyPinnedPlacemark {
            postLocationCoordinate = userSetPlacemark.coordinate
            postLocationText = userSetPlacemark.name
        } else {
            switch LocationManager.Shared.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                guard let coordinate = LocationManager.Shared.currentLocation?.coordinate,
                      let text = LocationManager.Shared.currentLocationTitle
                else {
                    CustomSwiftMessages.showInfoCard("still updating your location", "try again in just a second", emoji: " 🫠 ")
                    return
                }
                postLocationCoordinate = coordinate
                postLocationText = text
            default:
                CustomSwiftMessages.showPermissionRequest(permissionType: .newpostUserLocation) { granted in
                    if LocationManager.Shared.authorizationStatus == .notDetermined {
                        LocationManager.Shared.requestLocation()
                    } else {
                        CustomSwiftMessages.showSettingsAlertController(title: "turn on location services for mist in settings", message: "", on: self)
                    }
                    return
                }
            }
        }
        
        guard
            let trimmedTitleText = titleTextView?.text.trimmingCharacters(in: .whitespaces),
            let trimmedBodyText = bodyTextView?.text.trimmingCharacters(in: .whitespaces),
            let postLocationCoordinate = postLocationCoordinate,
            let postLocationText = postLocationText
        else {
            CustomSwiftMessages.displayError("incorrect formatting", "please try again")
            return
        }

        setAllInteractionTo(false)
        scrollView.scrollToTop()
        view.endEditing(true)
        animateProgressBar()
        Task {
            do {
                //We need to reset the filter and reload posts before uploading because uploading the post will immediately insert it at index 0 of explorePosts
                PostService.singleton.resetFilter()
                try await PostService.singleton.loadExplorePosts()
                try await PostService.singleton.uploadPost(title: trimmedTitleText, text: trimmedBodyText, locationDescription: postLocationText, latitude: postLocationCoordinate.latitude, longitude: postLocationCoordinate.longitude, timestamp: datePicker.date.timeIntervalSince1970)
                handleSuccessfulNewPost()
            } catch {
                progressView.progress = 0
                setAllInteractionTo(true)
                CustomSwiftMessages.displayError(error)
            }
        }
    }

    @IBAction func userDidTappedPostButton(_ sender: UIButton) {
        tryToPost()
    }
    
    func handleSuccessfulNewPost() {
        let tbc = presentingViewController as! UITabBarController
        tbc.selectedIndex = 0
        let homeNav = tbc.selectedViewController as! UINavigationController
        let homeParent = homeNav.topViewController as! HomeExploreParentViewController
        
        finishAnimationProgress() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                homeParent.isHandlingNewPost = true
                self.dismiss(animated: true) {
                    homeParent.handleNewlySubmittedPost()
                }
            })
        }
    }
    
    @IBAction func userDidTappedLocationButton(_ sender: UIButton) {
//        presentExploreSearchController()
        let pinMapVC = storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.PinMap) as! PinMapViewController
        
//        pinMapVC.pinnedAnnotation = currentlyPinnedAnnotation // Load the currently pinned annotation, if one exists
//        pinMapVC.completionHandler = { [self] (newAnnotation) in
//            currentlyPinnedAnnotation = newAnnotation
//        }
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
        if (text == " " || text == "\n") && textView.text.count == 0 {
            textView.text = ""
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
    
    //MARK: - ProgressBar
    
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
    
    //MARK: - Util
    
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
        postButton.isEnabled = bodyTextView.text.count != 0 && bodyTextView.text.count <= bodyTextView.maxLength && titleTextView.text.count != 0 && titleTextView.text.count <= titleTextView.maxLength
    }
}
