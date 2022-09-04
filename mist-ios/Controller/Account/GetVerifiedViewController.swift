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
    @IBOutlet weak var nameButton: UIButton!
    
    var imagePicker: ImagePicker!
    let VERIFY_BUTTON_TEXT = "get verfied with a selfie"

    var isVerifying: Bool = false {
        didSet {
            verifyButton.isEnabled = !isVerifying
            verifyButton.loadingIndicator(isVerifying)
        }
    }
    
    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupImagePicker()
        nameButton.setTitle(UserService.singleton.getFirstLastName(), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        profilePicImageView.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
    }
    
    //MARK: - Setup
    
    @IBAction func verifyButtonDidPressed(_ sender: UIButton) {
        guard UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) else {
            CustomSwiftMessages.showSettingsAlertController(title: "allow camera access for mist in settings", message: "", on: self)
            return
        }
        imagePicker.present(from: sender)
    }
    
    func setupVerifyButton() {
        verifyButton.roundCornersViaCornerRadius(radius: 10)
        verifyButton.clipsToBounds = true
        verifyButton.isEnabled = false
        verifyButton.setBackgroundImage(UIImage.imageFromColor(color: Constants.Color.mistLilac), for: .normal)
        verifyButton.setBackgroundImage(UIImage.imageFromColor(color: Constants.Color.mistLilac.withAlphaComponent(0.2)), for: .disabled)
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.setTitleColor(Constants.Color.mistLilac, for: .disabled)
        verifyButton.setTitle(VERIFY_BUTTON_TEXT, for: .normal)
    }
    
    //MARK: - User Interaction
    
    @IBAction func dismissButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }

    func setupImagePicker() {
        imagePicker = ImagePicker(presentationController: self, delegate: self, pickerSources: [.camera])
    }

    func verify(selfie: UIImage) {
        isVerifying = true
        Task {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.isVerifying = false
                let verified = true
                if verified {
                    //if verified, set that on the device
                    CustomSwiftMessages.showInfoCentered("successfully verified!", "enjoy your lilac badge", emoji: "✅") {
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
