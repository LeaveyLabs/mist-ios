//
//  WritePostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit
import CoreLocation
import MapKit
import InputBarAccessoryView

let BODY_PLACEHOLDER_TEXT = "pour your heart out"
let TITLE_PLACEHOLDER_TEXT = "a cute title"
let LOCATION_PLACEHOLDER_TEXT = "location name"
let TEXT_LENGTH_BEYOND_MAX_PERMITTED = 5

let TITLE_CHARACTER_LIMIT = 40
let LOCATION_NAME_CHARACTER_LIMIT = 25
let BODY_CHARACTER_LIMIT = 999

let PROGRESS_DEFAULT_DURATION: Double = 6 // Seconds
let PROGRESS_DEFAULT_MAX: Float = 0.8 // 80%

class NewPostViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var postBubbleView: UIView!
    let keyboardManager = KeyboardManager() //InputBarAccessoryView
    
    //Top
    @IBOutlet weak var pinButton: UIButton!
    @IBOutlet weak var pinArrowButton: UIButton!
    @IBOutlet weak var dateTimeTextField: NewPostTextView!
    @IBOutlet var locationNameTextField: NewPostTextField!
        
    var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker(frame: .zero)
        datePicker.datePickerMode = .dateAndTime
        datePicker.locale = Locale(identifier: "en_US")
        if #available(iOS 14, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.maximumDate = Date()
        datePicker.minimumDate = Calendar.current.date(byAdding: .month,
                                                       value: -1,
                                                       to: Date())
        return datePicker
    }()
    
    //Lower section
    @IBOutlet var titleTextView: NewPostTextView!
    @IBOutlet var bodyTextView: NewPostTextView!
    var titlePlaceholderLabel: UILabel!
    var bodyPlaceholderLabel: UILabel!
    
    //Indicator views
    @IBOutlet weak var pinLilacIndicator: UIView!
    @IBOutlet weak var locationNameLilacIndicator: UIView!
    @IBOutlet weak var titleLilacIndicator: UIView!
    @IBOutlet weak var bodyLilacIndicator: UIView!
    
    var currentPin: CLLocationCoordinate2D? {
        didSet {
            if let _ = currentPin {
                pinButton.tintColor = Constants.Color.mistBlack
                pinArrowButton.tintColor = Constants.Color.mistBlack
                pinButton.setImage(UIImage(systemName: "mappin.circle", withConfiguration: UIImage.SymbolConfiguration(scale: .small)), for: .normal)
            } else {
                switch LocationManager.Shared.authorizationStatus {
                case .authorizedAlways, .authorizedWhenInUse:
                    pinButton.tintColor = Constants.Color.mistBlack
                    pinArrowButton.tintColor = Constants.Color.mistBlack
                    pinButton.setImage(UIImage(systemName: "location", withConfiguration: UIImage.SymbolConfiguration(scale: .small)), for: .normal)
                default:
                    pinButton.tintColor = .lightGray
                    pinArrowButton.tintColor = .lightGray
                    pinButton.setImage(UIImage(systemName: "mappin.circle", withConfiguration: UIImage.SymbolConfiguration(scale: .small)), for: .normal)
                }
            }
            validateAllFields()
        }
    }
    
    var postStartTime: DispatchTime?
    
    //Progress
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var guidelinesButton: UIButton!
    
    // Search
    var mySearchController: UISearchController!
    var searchSuggestionsVC: SearchSuggestionsTableViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
        postBubbleView.transformIntoPostBubble(arrowPosition: .right)
        setupProgressView()
        setupTextViews()
        setupIndicatorViews()
        loadFromNewPostContext() //should come after setting up views
        validateAllFields()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)), style: .plain, target: self, action: #selector(cancelButtonDidPressed(_:)))

        if !DeviceService.shared.hasBeenShowedGuidelines() {
            presentExplanationVC()
        } else {
            titleTextView.becomeFirstResponder()
        }
        addKeyboardObservers()
    }
    
    // MARK: - Setup
    
    func loadFromNewPostContext() {
        datePicker.date = Date(timeIntervalSince1970: NewPostContext.timestamp ?? Date().timeIntervalSince1970)
        currentPin = NewPostContext.pin
        titleTextView.text = NewPostContext.title
        bodyTextView.text = NewPostContext.body
        locationNameTextField.text = NewPostContext.locationName
        
        //Extra checks necessary after updating the textView's text
        bodyPlaceholderLabel.isHidden = !bodyTextView.text.isEmpty
        titlePlaceholderLabel.isHidden = !titleTextView.text.isEmpty

        NewPostContext.clear()
    }
    
    func saveToNewPostContext() {
        NewPostContext.title = titleTextView.text
        NewPostContext.body = bodyTextView.text
        NewPostContext.timestamp = datePicker.date.timeIntervalSince1970
        NewPostContext.pin = currentPin
        NewPostContext.locationName = locationNameTextField.text ?? ""
    }
    
    func setupTextViews() {
        titleTextView.delegate = self
        titleTextView.initializerToolbar(target: self, doneSelector: #selector(dismissKeyboard), withProgressBar: true)
        titleTextView.textContainer.lineFragmentPadding = 0 //fixes textview strange leading offset
        titlePlaceholderLabel = titleTextView.addAndReturnPlaceholderLabelTwo(withText: TITLE_PLACEHOLDER_TEXT)
        titleTextView.maxLength = TITLE_CHARACTER_LIMIT
        
        bodyTextView.delegate = self
        bodyTextView.initializerToolbar(target: self, doneSelector: #selector(dismissKeyboard), withProgressBar: true)
        bodyTextView.textContainer.lineFragmentPadding = 0 //fixes textview strange leading offset
        bodyPlaceholderLabel = bodyTextView.addAndReturnPlaceholderLabelTwo(withText: BODY_PLACEHOLDER_TEXT)
        bodyTextView.maxLength = BODY_CHARACTER_LIMIT
        
        locationNameTextField.delegate = self
        locationNameTextField.initializerToolbar(target: self, doneSelector: #selector(dismissKeyboard), withProgressBar: true)
        locationNameTextField.maxLength = LOCATION_NAME_CHARACTER_LIMIT
        locationNameTextField.placeholder = LOCATION_PLACEHOLDER_TEXT
        locationNameTextField.applyLightShadow()
        locationNameTextField.layer.cornerRadius = 10
        locationNameTextField.layer.cornerCurve = .continuous
        
        dateTimeTextField.inputView = datePicker
        datePicker.addTarget(self, action: #selector(updateDateTime), for: .valueChanged)
        dateTimeTextField.applyLightShadow()
        dateTimeTextField.text = "just now"
        dateTimeTextField.layer.cornerRadius = 10
        dateTimeTextField.layer.cornerCurve = .continuous
        dateTimeTextField.initializerToolbar(target: self, doneSelector: #selector(dismissKeyboard), withProgressBar: false)
    }
    
    func setupIndicatorViews() {
        locationNameLilacIndicator.roundCorners(corners: .allCorners, radius: 4)
        pinLilacIndicator.roundCorners(corners: .allCorners, radius: 4)
        bodyLilacIndicator.roundCorners(corners: .allCorners, radius: 4)
        titleLilacIndicator.roundCorners(corners: .allCorners, radius: 4)
    }

    func setupButtons() {
        pinButton.layer.cornerRadius = 10
        pinButton.layer.cornerCurve = .continuous
        pinButton.applyLightShadow()
        postButton.roundCornersViaCornerRadius(radius: 5)
        postButton.clipsToBounds = true
        postButton.setBackgroundImage(UIImage.imageFromColor(color: Constants.Color.mistLilac), for: .normal)
        postButton.setTitleColor(.white, for: .normal)
        postButton.setTitleColor(.lightGray, for: .disabled)
        postButton.setBackgroundImage(UIImage.imageFromColor(color: .systemGray5.withAlphaComponent(0.5)), for: .disabled)
        postButton.isEnabled = false
        postButton.adjustsImageWhenDisabled = true
        postButton.adjustsImageWhenHighlighted = true
        postButton.backgroundColor = .clear
    }
    
    func setupProgressView() {
        progressView.isHidden = true
    }

    // MARK: - User Interaction
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if !DeviceService.shared.hasBeenShowedGuidelines() {
            DeviceService.shared.showGuidelinesForFirstTime()
            
            guard segue.identifier == Constants.SBID.Segue.ToExplain else { return }
            let destination = segue.destination as! GuidelinesViewController // change that to the real class
            destination.callback = {
                self.titleTextView.becomeFirstResponder()
            }
        }
    }
    
    @objc func presentExplanationVC() {
        performSegue(withIdentifier: Constants.SBID.Segue.ToExplain, sender: self)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func cancelButtonDidPressed(_ sender: UIBarButtonItem) {
        let hasMadeEdits = !bodyTextView.text.isEmpty || !titleTextView.text.isEmpty || currentPin != nil
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
        if let userSetPin = currentPin {
            postLocationCoordinate = userSetPin
        } else {
            switch LocationManager.Shared.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                guard let coordinate = LocationManager.Shared.currentLocation?.coordinate
                else {
                    CustomSwiftMessages.showInfoCard("still updating your location", "try again in just a second", emoji: " 🫠 ")
                    return
                }
                postLocationCoordinate = coordinate
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
            let trimmedTitleText = titleTextView?.text.trimmingCharacters(in: .whitespacesAndNewlines),
            let trimmedBodyText = bodyTextView?.text.trimmingCharacters(in: .whitespacesAndNewlines),
            let postLocationText = locationNameTextField?.text?.trimmingCharacters(in: .whitespaces).lowercased(),
            let postLocationCoordinate = postLocationCoordinate
        else {
            CustomSwiftMessages.displayError("incorrect formatting", "please try again")
            return
        }

        view.isUserInteractionEnabled = false
        scrollView.scrollToTop()
        setAllInteractionTo(false)
        animateProgressBar()
        Task {
            do {
                //We need to reset the filter and reload posts before uploading because uploading the post will immediately insert it at index 0 of explorePosts
                PostService.singleton.resetFilter()
                try await PostService.singleton.loadExplorePosts()
                try await PostService.singleton.uploadPost(title: trimmedTitleText, text: trimmedBodyText, locationDescription: postLocationText, latitude: postLocationCoordinate.latitude, longitude: postLocationCoordinate.longitude, timestamp: datePicker.date.timeIntervalSince1970)
                await MainActor.run {
                    handleSuccessfulNewPost()
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.progressView.progress = 0
                    self?.setAllInteractionTo(true)
                    CustomSwiftMessages.displayError(error)
                }
            }
        }
    }

    @IBAction func userDidTappedPostButton(_ sender: UIButton) {
        tryToPost()
    }
    
    @MainActor
    func handleSuccessfulNewPost() {
        let tbc = presentingViewController as! UITabBarController
        tbc.selectedIndex = 0
        let homeNav = tbc.selectedViewController as! UINavigationController
        let homeParent = homeNav.topViewController as! HomeExploreParentViewController
        
        finishAnimationProgress() {
            homeParent.isHandlingNewPost = true
            self.dismiss(animated: true) {
                homeParent.handleNewlySubmittedPost()
            }
        }
    }
    
    @IBAction func userDidTappedPinButton(_ sender: UIButton) {
        let pinParentVC = PinParentViewController.create(currentPin: currentPin, completionHandler: { [self] newPin in
            currentPin = newPin
            locationNameTextField.becomeFirstResponder() //they updated their pin, so they probably want to update the location name too
        })
        navigationController?.pushViewController(pinParentVC, animated: true)
    }
}

//MARK: - UITextFieldDelegate

extension NewPostViewController: UITextFieldDelegate {
    
    //IMPLMENET MAX LENGTH
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        if sender == locationNameTextField {
            locationNameTextField.updateProgress()
            if sender.text!.count > LOCATION_NAME_CHARACTER_LIMIT {
                sender.deleteBackward()
            }
        }
        validateAllFields()
    }
    
    @objc func updateDateTime() {
        let (date, time) = getDateAndTimeForNewPost(selectedDate: datePicker.date)
        dateTimeTextField.text = date.lowercased() + ", " +  time.lowercased()
//        if date.contains(" ") { //"aug 31"
//            dateTimeTextField.text = date.lowercased()
//        }
        validateAllFields()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if titleTextView.text.isEmpty {
            titleTextView.becomeFirstResponder()
        } else if bodyTextView.text.isEmpty {
            bodyTextView.becomeFirstResponder()
        } else {
            resignFirstResponder()
        }
        return true
    }
}

extension NewPostViewController: UITextViewDelegate {
    
    //MARK: - TextView
            
    func textViewDidChange(_ textView: UITextView) {
        // UITextView has a quirk when last char is a newline...
        //  its size is not updated until another char is entered
        //  so, this will force the textView to scroll down
        if let selectedRange = textView.selectedTextRange,
           let txt = textView.text,
           !txt.isEmpty,
           txt.last == "\n" {
            print("WILL DO THIS NOW")
            let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            print(cursorPosition, txt.count)
            if cursorPosition == txt.count {
                //the two methods below were not working on newline. the above works better
                var visibleRect = bodyTextView.frame
                visibleRect.size.height += 65 - view.safeAreaInsets.bottom
                scrollView.scrollRectToVisible(visibleRect, animated: true)
                
//                if !scrollView.isAtTop { //scrollToBottom does not work when pressing "return" key
//                    scrollView.contentOffset.y += 25
//                }
//                scrollView.scrollToBottom(animated: false)
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
                return true
//                return textView.shouldAllowNewline(in: textView.text, at: range.location)
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
        pinButton.titleLabel?.text = LOCATION_PLACEHOLDER_TEXT
        datePicker.date = Date()
    }
    
    func setAllInteractionTo(_ shouldBeEnabled: Bool) {
        postButton.isEnabled = shouldBeEnabled
        pinButton.isEnabled = shouldBeEnabled
        guidelinesButton.isEnabled = shouldBeEnabled
        locationNameTextField.isEnabled = shouldBeEnabled
        datePicker.isEnabled = shouldBeEnabled
        titleTextView.isEditable = shouldBeEnabled
        bodyTextView.isEditable = shouldBeEnabled
    }
    
    //my guess is it had something to do with this validate all fields
    func validateAllFields() {
        locationNameLilacIndicator.isHidden = !locationNameTextField.text!.isEmpty
        pinLilacIndicator.isHidden = currentPin != nil || LocationManager.Shared.authorizationStatus == .authorizedWhenInUse || LocationManager.Shared.authorizationStatus == .authorizedAlways
        titleLilacIndicator.isHidden = titleTextView.text.count != 0 && titleTextView.text.count <= titleTextView.maxLength
        bodyLilacIndicator.isHidden = bodyTextView.text.count != 0 && bodyTextView.text.count <= bodyTextView.maxLength
        postButton.isEnabled = locationNameLilacIndicator.isHidden && pinLilacIndicator.isHidden && titleLilacIndicator.isHidden && bodyLilacIndicator.isHidden
    }
}
