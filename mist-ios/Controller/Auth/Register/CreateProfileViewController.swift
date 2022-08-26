//
//  CreateProfileViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/25/22.
//

import Foundation
import UIKit
import dnssd


class CreateProfileViewController: KUIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var profilePictureButton: UIButton!
    @IBOutlet weak var miniCameraButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    
    var imagePicker: ImagePicker!
    
    var isValidInput: Bool! {
        didSet {
            continueButton.isEnabled = isValidInput
            continueButton.setNeedsUpdateConfiguration()
            profilePictureButton.setImage(profilePic, for: .normal)
            miniCameraButton.isHidden = profilePic == defaultPic
        }
    }
    var isSubmitting: Bool = false {
        didSet {
            continueButton.isEnabled = !isSubmitting
            continueButton.setNeedsUpdateConfiguration()
        }
    }
    var profilePic: UIImage? {
        didSet {
            validateInput()
        }
    }
    let defaultPic = UIImage(systemName: "camera.circle")!.withRenderingMode(.alwaysTemplate)

    override func viewDidLoad() {
        super.viewDidLoad()
        shouldNotAnimateKUIAccessoryInputView = true
        profilePic = defaultPic
        setupButtons()
        setupTextFields()
        firstNameTextField.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupImagePicker()
        validateInput()
        enableInteractivePopGesture()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    //MARK: - Setup
    
    func setupButtons() {
        continueButton.configurationUpdateHandler = { button in
            if button.isEnabled {
                button.configuration = ButtonConfigs.enabledConfig(title: "start")
            }
            else {
                button.configuration = ButtonConfigs.disabledConfig(title: "start")
            }
            button.configuration?.showsActivityIndicator = self.isSubmitting
        }
        // Setup miniCameraButton
        miniCameraButton.isHidden = true
        miniCameraButton.becomeRound()
        profilePictureButton.imageView?.becomeProfilePicImageView(with: defaultPic)
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
            return textField.shouldChangeCharactersGivenMaxLengthOf(30, range, string)
        }
        if textField == lastNameTextField {
            if didAutofillTextfield {
                DispatchQueue.main.async {
                    self.usernameTextField.becomeFirstResponder()
                }
            }
            return textField.shouldChangeCharactersGivenMaxLengthOf(30, range, string)
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
                    email: AuthContext.email,
                    phoneNumber: AuthContext.phoneNumber,
                    dob: AuthContext.dob)
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
        isValidInput = false
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
    }

}

extension CreateProfileViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        guard let newImage = image else { return }
        profilePic = newImage.withRenderingMode(.alwaysOriginal)
    }
    
}
