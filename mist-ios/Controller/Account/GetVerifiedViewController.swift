//
//  GetVerifiedViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/25/22.
//

import Foundation
import UIKit

class GetVerifiedViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var profilePicImageView: UIImageView!
    var imagePicker: ImagePicker!
    let VERIFY_BUTTON_TEXT = "get verfied with a selfie"

    var isVerifying: Bool = false {
        didSet {
            verifyButton.isEnabled = !isVerifying
            verifyButton.setNeedsUpdateConfiguration()
        }
    }
    
    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        profilePicImageView.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
        setupImagePicker()
    }
    
    //MARK: - Setup
    
    @IBAction func verifyButtonDidPressed(_ sender: UIButton) {
        guard UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) else {
            let alert  = UIAlertController(title: "camera access not granted", message: "please allow camera access in settings first", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        imagePicker.present(from: sender)
    }
    
    func setupVerifyButton() {
        verifyButton.configurationUpdateHandler = { [self] button in
            if button.isEnabled {
                button.configuration = ButtonConfigs.enabledConfig(title: VERIFY_BUTTON_TEXT)
            }
            else {
                if !isVerifying {
                    button.configuration = ButtonConfigs.disabledConfig(title: VERIFY_BUTTON_TEXT)
                }
            }
            button.configuration?.showsActivityIndicator = isVerifying
        }
    }
    
    //MARK: - User Interaction
    
    @IBAction func dismissButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
        presentingViewController!.dismiss(animated: true)
    }

    func setupImagePicker() {
        imagePicker = ImagePicker(presentationController: self, delegate: self, pickerSources: [.camera])
    }

    func verify(selfie: UIImage) {
        isVerifying = true
        Task {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.isVerifying = false
                let verified = false
                if verified {
                    //if verified, set that on the device
                    CustomSwiftMessages.showInfoCentered("successfully verified!", "enjoy your blue badge", emoji: "✅") {
                        self.dismiss(animated: true)
                    }
                } else {
                    CustomSwiftMessages.showInfoCentered("we couldn't match your selfie with your profile pic", "try uploading a more accurate profile pic or taking another selfie", emoji: "😕") {
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
}


extension GetVerifiedViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        guard let image = image else {
            print("nil image..?")
            return
        }
        verify(selfie: image)
    }
    
}
