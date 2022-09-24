//
//  CreateProfileViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/25/22.
//

import Foundation
import UIKit

class CreateProfileViewController: KUIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var profilePictureButton: UIButton!
    @IBOutlet weak var miniCameraButton: UIButton!
    @IBOutlet weak var profilePicTextLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var firstNameIndicatorView: UIView!
    @IBOutlet weak var lastNameIndicatorView: UIView!
    @IBOutlet weak var usernameIndicatorView: UIView!
    @IBOutlet weak var profilePicIndicatorView: UIView!

    @IBOutlet weak var headerTitleView: UIView!
    @IBOutlet weak var headerSpacingView: UIView!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    
    var imagePicker: ImagePicker!
    
    var isValidInput: Bool! {
        didSet {
            continueButton.isEnabled = isValidInput
            profilePictureButton.imageView?.becomeProfilePicImageView(with: profilePic)
            profilePicTextLabel.isHidden = profilePic != defaultPic
            miniCameraButton.isHidden = profilePic == defaultPic
        }
    }
    var isSubmitting: Bool = false {
        didSet {
            continueButton.setTitle(isSubmitting ? "" : "continue", for: .normal)
            continueButton.loadingIndicator(isSubmitting)
        }
    }
    
    var profilePic: UIImage? {
        didSet {
            validateInput()
        }
    }
    let defaultPic = UIImage(systemName: "circle.fill")!.withRenderingMode(.alwaysTemplate)

    override func viewDidLoad() {
        super.viewDidLoad()
        shouldNotAnimateKUIAccessoryInputView = true
        profilePic = defaultPic
        setupButtons()
        setupTextFields()
        setupHeaderAndImageBasedOnScreenSize()
        firstNameTextField.becomeFirstResponder()
        setupIndicatorViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        print(view.bounds.height)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupImagePicker()
        validateInput()
        disableInteractivePopGesture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        enableInteractivePopGesture()
    }
    
    //MARK: - Setup
    
    func setupIndicatorViews() {
        profilePicIndicatorView.roundCornersViaCornerRadius(radius: 4)
        firstNameIndicatorView.roundCornersViaCornerRadius(radius: 4)
        lastNameIndicatorView.roundCornersViaCornerRadius(radius: 4)
        usernameIndicatorView.roundCornersViaCornerRadius(radius: 4)
    }
    
    func setupButtons() {
        continueButton.roundCornersViaCornerRadius(radius: 10)
        continueButton.clipsToBounds = true
        continueButton.isEnabled = false
        continueButton.setBackgroundImage(UIImage.imageFromColor(color: Constants.Color.mistLilac), for: .normal)
        continueButton.setBackgroundImage(UIImage.imageFromColor(color: Constants.Color.mistLilac.withAlphaComponent(0.2)), for: .disabled)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.setTitleColor(Constants.Color.mistLilac, for: .disabled)
        continueButton.setTitle("start", for: .normal)
        // Setup miniCameraButton
        miniCameraButton.isHidden = true
        miniCameraButton.becomeRound()
        profilePictureButton.imageView?.becomeProfilePicImageView(with: defaultPic)
        profilePictureButton.contentHorizontalAlignment = .fill //so that the systemimage expands
        profilePictureButton.contentVerticalAlignment = .fill
    }
    
    func setupTextFields() {
        usernameTextField.delegate = self
        usernameTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        usernameTextField.layer.cornerRadius = 5
        usernameTextField.setLeftAndRightPadding(10)
        
        firstNameTextField.delegate = self
        firstNameTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        firstNameTextField.layer.cornerRadius = 5
        firstNameTextField.setLeftAndRightPadding(10)
        
        lastNameTextField.delegate = self
        lastNameTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        lastNameTextField.layer.cornerRadius = 5
        lastNameTextField.setLeftAndRightPadding(10)
    }
    
    func setupImagePicker() {
        imagePicker = ImagePicker(presentationController: self, delegate: self, pickerSources: [.camera, .photoLibrary])
    }
    
    func setupHeaderAndImageBasedOnScreenSize() {
        let screenHeight = view.bounds.height
        if screenHeight < 600 {
            headerTitleView.isHidden = true
            headerSpacingView.isHidden = true
        } else if screenHeight > 900 {
            imageViewWidthConstraint.constant += 90
        } else if screenHeight > 850 {
            imageViewWidthConstraint.constant += 60
        } else if screenHeight > 700 {
            imageViewWidthConstraint.constant += 30
        } else if screenHeight > 600 {
            imageViewWidthConstraint.constant += 8
        }
    }
    
    //MARK: - TextField Delegate
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        validateInput()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameTextField {
            lastNameTextField.becomeFirstResponder()
        }
        if textField == lastNameTextField {
            usernameTextField.becomeFirstResponder()
        }
        if textField == usernameTextField {
            tryToContinue()
        }
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let didAutofillTextfield = range == NSRange(location: 0, length: 0) && string.count > 1
        if textField == firstNameTextField {
            if didAutofillTextfield {
                DispatchQueue.main.async {
                    self.lastNameTextField.becomeFirstResponder()
                }
            }
            return textField.shouldChangeCharactersGivenMaxLengthOf(20, range, string)
        }
        if textField == lastNameTextField {
            if didAutofillTextfield {
                DispatchQueue.main.async {
                    self.usernameTextField.becomeFirstResponder()
                }
            }
            return textField.shouldChangeCharactersGivenMaxLengthOf(20, range, string)
        }
        if textField == usernameTextField {
            return textField.shouldChangeCharactersGivenMaxLengthOf(30, range, string)
        }
        return true
    }
    
    //MARK: - User Interaction
    
    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didPressedContinueButton(_ sender: UIButton) {
        tryToContinue()
    }
    
    @IBAction func didPressedChoosePhotoButton(_ sender: UIButton) {
        imagePicker.present(from: sender)
    }
    
    @IBAction func didPressExplainProfileButton(_ sender: UIButton) {
        let explainProfileVC = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ExplainProfile) as! ExplainProfileViewController
        present(explainProfileVC, animated: true)
    }
    
    //MARK: - Helpers

    func tryToContinue() {
        guard
            isValidInput,
            let uploadedProfilePic = profilePictureButton.imageView?.image,
            let username = usernameTextField.text,
            let firstName = firstNameTextField.text,
            let lastName = lastNameTextField.text
        else { return }
        isSubmitting = true
        Task {
            do {
                try await UserService.singleton.createUser(
                    username: username,
                    firstName: firstName,
                    lastName: lastName,
                    profilePic: uploadedProfilePic,
                    phoneNumber: AuthContext.phoneNumber,
                    accessCode: AuthContext.accessCode,
                    email: AuthContext.email)
                try await loadEverything()
                AuthContext.reset()
                isSubmitting = false
                transitionToHomeAndRequestPermissions() { }
            } catch {
                handleFailure(error)
            }
        }
    }
    
    //TODO: make sure these error messages are descriptive
    func handleFailure(_ error: Error) {
        isSubmitting = false
        CustomSwiftMessages.displayError(error)
        //        DispatchQueue.main.async { [self] in
        //            transitionToStoryboard(storyboardID: Constants.SBID.SB.Auth,
        //                                        viewControllerID: Constants.SBID.VC.AuthNavigation,
        //                                        duration: Env.LAUNCH_ANIMATION_DURATION) { _ in}
        //        }
    }
    
    func validateInput() {
        let validPic = profilePic != defaultPic && profilePic != nil
        let validUsername = Validate.validateUsername(usernameTextField.text ?? "")
        let validName = firstNameTextField.text!.count > 0 && lastNameTextField.text!.count > 0
        isValidInput = validPic && validUsername && validName
        
        firstNameIndicatorView.isHidden = firstNameTextField.text!.count > 0
        lastNameIndicatorView.isHidden = lastNameTextField.text!.count > 0
        usernameIndicatorView.isHidden = usernameTextField.text!.count > 0
        profilePicIndicatorView.isHidden = validPic
    }

}

extension CreateProfileViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        guard let newImage = image else { return }
        profilePic = newImage.withRenderingMode(.alwaysOriginal)
    }
    
}
