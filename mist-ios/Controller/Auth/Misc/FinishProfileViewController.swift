//
//  FinishProfileViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/9/22.
//

import Foundation
import UIKit

class FinishProfileViewController: KUIViewController, UITextFieldDelegate {
    
//    //MARK: - Properties
//    
//    @IBOutlet weak var firstLabel: UILabel!
//    @IBOutlet weak var secondLabel: UILabel!
//    
//    @IBOutlet weak var profilePictureButton: UIButton!
//    @IBOutlet weak var miniCameraButton: UIButton!
//    
//    @IBOutlet weak var firstNameTextField: UITextField!
//    @IBOutlet weak var lastNameTextField: UITextField!
//    @IBOutlet weak var continueButton: UIButton!
//    
//    var isSubmitting: Bool = false {
//        didSet {
//            continueButton.isEnabled = !isSubmitting
//            continueButton.setNeedsUpdateConfiguration()
//        }
//    }
//    var isValidInput: Bool! {
//        didSet {
//            continueButton.isEnabled = isValidInput
//            continueButton.setNeedsUpdateConfiguration()
//        }
//    }
//    var imagePicker: ImagePicker!
//    var profilePic: UIImage? {
//        didSet {
//            continueButton.isEnabled = validateInput()
//            miniCameraButton.isHidden = !validateInput()
//            continueButton.setNeedsUpdateConfiguration()
//            
//            if validateInput() {
//                profilePictureButton.setImage(profilePic?.withRenderingMode(.alwaysOriginal), for: .normal)
//            } else {
//                profilePictureButton.setImage(defaultPic, for: .normal)
//            }
//        }
//    }
//    let defaultPic = UIImage(systemName: "camera.circle")
//    
//    //MARK: - Lifecycle
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        validateInput()
//        shouldNotAnimateKUIAccessoryInputView = true
//        setupTextFields()
//        setupImagePicker()
//        setupButtons()
//        setupLabels()
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        enableInteractivePopGesture()
//        firstNameTextField.becomeFirstResponder()
//        validateInput()
//    }
//    
//    //MARK: - Setup
//    
//    func setupTextFields() {
//        firstNameTextField.delegate = self
//        firstNameTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
//        firstNameTextField.layer.cornerRadius = 5
//        firstNameTextField.setLeftAndRightPadding(10)
//        firstNameTextField.becomeFirstResponder()
//        
//        lastNameTextField.delegate = self
//        lastNameTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
//        lastNameTextField.layer.cornerRadius = 5
//        lastNameTextField.setLeftAndRightPadding(10)
//    }
//    
//    func setupButtons() {
//        continueButton.configurationUpdateHandler = { button in
//            if button.isEnabled {
//                button.configuration = ButtonConfigs.enabledConfig(title: "Start")
//            }
//            else {
//                button.configuration = ButtonConfigs.disabledConfig(title: "Start")
//            }
//        }
//        // Setup miniCameraButton
//        miniCameraButton.isHidden = !validateInput()
//        miniCameraButton.becomeRound()
//        profilePictureButton.imageView?.becomeProfilePicImageView(with: UIImage(systemName: "camera.circle")!)
//    }
//    
//    func setupImagePicker() {
//        imagePicker = ImagePicker(presentationController: self, delegate: self)
//        profilePic = defaultPic
//    }
//    
//    func setupLabels() {
//        
//    }
//    
//    //MARK: - User Interaction
//    
//    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
//        navigationController?.popViewController(animated: true)
//    }
//    
//    @IBAction func didPressedContinueButton(_ sender: UIButton) {
//        tryToContinue()
//    }
//    
//    @IBAction func didPressedChoosePhotoButton(_ sender: UIButton) {
//        imagePicker.present(from: sender)
//    }
//    
//    //MARK: - TextField Delegate
//    
//    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
//        validateInput()
//    }
//    
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        if textField == firstNameTextField {
//            lastNameTextField.becomeFirstResponder()
//        } else {
//            if isValidInput {
//                tryToContinue()
//            }
//        }
//        return false
//    }
//    
//    // Max length UI text field: https://stackoverflow.com/questions/25223407/max-length-uitextfield
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        guard let textFieldText = textField.text,
//            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
//                return false
//        }
//        let substringToReplace = textFieldText[rangeOfTextToReplace]
//        let count = textFieldText.count - substringToReplace.count + string.count
//        return count <= 15
//    }
//    
//    //MARK: - Helpers
//    
//    func tryToContinue() {
//        if let firstName = firstNameTextField.text, let lastName = lastNameTextField.text, let selectedProfilePic = profilePictureButton.imageView?.image {
//            isSubmitting = true
//            Task {
//                do {
//                    AuthContext.firstName = firstName
//                    AuthContext.lastName = lastName
//                    let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterBios)
//                    self.navigationController?.pushViewController(vc, animated: true)
//                    
////                    try await UserService.singleton.createUser(
////                        username: AuthContext.username,
////                        firstName: AuthContext.firstName,
////                        lastName: AuthContext.lastName,
////                        profilePic: selectedProfilePic,
////                        email: AuthContext.email,
////                        password: AuthContext.password)
////                    try await loadEverything()
////                    transitionToHomeAndRequestPermissions() { [weak self] in
////                        self?.isSubmitting = false
////                    }
//                } catch {
//                    handleFailure(error)
//                }
//            }
//        }
//    }
//    
//    func handleFailure(_ error: Error) {
//        isSubmitting = false
//        profilePic = defaultPic
//        CustomSwiftMessages.displayError(error)
//    }
//    
//    func validateInput() -> Bool {
//        isValidInput = firstNameTextField.text!.count > 0 && lastNameTextField.text!.count > 0 && profilePic != defaultPic && profilePic != nil
//        return isValidInput
//    }
}

//extension FinishProfileViewController: ImagePickerDelegate {
//
//    func didSelect(image: UIImage?) {
//        profilePic = image
//    }
//}
