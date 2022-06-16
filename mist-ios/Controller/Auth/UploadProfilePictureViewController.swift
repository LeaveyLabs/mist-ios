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
        setupImagePicker()
        setupButtons()
        setupLabels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enableInteractivePopGesture()
    }
    
    //MARK: - Setup
    
    func setupButtons() {
        continueButton.configurationUpdateHandler = { button in
            if button.isEnabled {
                button.configuration = ButtonConfigs.enabledConfig(title: "Start")
            }
            else {
                button.configuration = ButtonConfigs.disabledConfig(title: "Start")
            }
        }
        // Setup miniCameraButton
        miniCameraButton.isHidden = !validateInput()
        miniCameraButton.becomeRound()
        
        // Setup profilePictureButton
        profilePictureButton.becomeRound()
        profilePictureButton.imageView?.contentMode = .scaleAspectFill
        
    }
    
    func setupImagePicker() {
        imagePicker = ImagePicker(presentationController: self, delegate: self)
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
            isSubmitting = true
            if let selectedProfilePic = profilePictureButton.imageView?.image {
                do {
                    try await UserService.singleton.createUser(
                        username: AuthContext.username,
                        firstName: AuthContext.firstName,
                        lastName: AuthContext.lastName,
                        profilePic: selectedProfilePic,
                        email: AuthContext.email,
                        password: AuthContext.password)
                    try await PostsService.loadInitialPosts()
                    transitionToHomeAndRequestPermissions() { [weak self] in
                        self?.isSubmitting = false
                    }
                } catch {
                    handleFailure(error)
                }
            }
        }
    }
    
    func handleFailure(_ error: Error) {
        isSubmitting = false
        profilePic = defaultPic
        CustomSwiftMessages.showError(errorDescription: error.localizedDescription)
    }
    
    func validateInput() -> Bool {
        return profilePic != defaultPic
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
