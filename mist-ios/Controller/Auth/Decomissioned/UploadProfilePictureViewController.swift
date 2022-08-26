//
//  UploadProfilePictureViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 5/6/22.
//

import UIKit


class UploadProfilePictureViewController: UIViewController {
    
    @IBOutlet weak var profilePictureButton: UIButton!
    @IBOutlet weak var miniCameraButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var errorView: SpringView!
    
    var imagePicker: ImagePicker!
    var isSubmitting: Bool = false {
        didSet {
            continueButton.isEnabled = !isSubmitting
            continueButton.setNeedsUpdateConfiguration()
        }
    }
    var profilePic: UIImage? {
        didSet {
            continueButton.isEnabled = validateInput()
            miniCameraButton.isHidden = !validateInput()
            continueButton.setNeedsUpdateConfiguration()
            
            if validateInput() {
                profilePictureButton.setImage(profilePic?.withRenderingMode(.alwaysOriginal), for: .normal)
            } else {
                profilePictureButton.setImage(defaultPic, for: .normal)
            }
        }
    }
    let defaultPic = UIImage(systemName: "camera.circle")

    override func viewDidLoad() {
        super.viewDidLoad()
        profilePic = defaultPic
        setupButtons()
        setupLabels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enableInteractivePopGesture()
        setupImagePicker()
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
        miniCameraButton.isHidden = !validateInput()
        miniCameraButton.becomeRound()
        profilePictureButton.imageView?.becomeProfilePicImageView(with: UIImage(systemName: "camera.circle")!)
    }
    
    func setupImagePicker() {
        imagePicker = ImagePicker(presentationController: self, delegate: self, pickerSources: [.camera, .photoLibrary])
    }
    
    func setupLabels() {
        usernameLabel.text = "@" + AuthContext.username
        nameLabel.text = AuthContext.firstName + " " + AuthContext.lastName
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
        Task {
            if let selectedProfilePic = profilePictureButton.imageView?.image {
                isSubmitting = true
                do {
                    try await UserService.singleton.createUser(
                        username: AuthContext.username,
                        firstName: AuthContext.firstName,
                        lastName: AuthContext.lastName,
                        profilePic: selectedProfilePic,
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
    }
    
    //TODO: better error handling here
    func handleFailure(_ error: Error) {
        isSubmitting = false
//        profilePic = defaultPic
        CustomSwiftMessages.displayError(error)
        
//        DispatchQueue.main.async { [self] in
//            transitionToStoryboard(storyboardID: Constants.SBID.SB.Auth,
//                                        viewControllerID: Constants.SBID.VC.AuthNavigation,
//                                        duration: Env.LAUNCH_ANIMATION_DURATION) { _ in}
//        }
    }
    
    func validateInput() -> Bool {
        return profilePic != defaultPic && profilePic != nil
    }

}

extension UploadProfilePictureViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        profilePic = image
    }
}

// Error View functions
extension UploadProfilePictureViewController {
    
    func setupErrorLabel() {
        errorView.layer.cornerRadius = 10
        errorView.layer.masksToBounds = true
        errorView.isHidden = true
        errorView.layer.cornerCurve = .continuous
    }
    
    func handleError(_ error: Error) {
        isSubmitting = false
        profilePic = nil
        errorLabel.attributedText = CustomAttributedString.errorMessage(errorText: "That didn't work.", size: 16)
        errorView.isHidden = false
        errorView.animation = "shake"
        errorView.animate()
    }
}
