//
//  EnterProfilePictureViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 5/6/22.
//

import UIKit


class EnterProfilePictureViewController: UIViewController {
    
    @IBOutlet weak var profilePictureView: UIImageView!
    
    var imagePicker: ImagePicker!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
    }
    
    @IBAction func didPressedChoosePhotoButton(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }

    @IBAction func didPressedContinue(_ sender: Any) {
        Task {
            if let selectedProfilePic = self.profilePictureView.image {
                do {
                    try await UserService.singleton.updateProfilePic(to: selectedProfilePic)
                    let vc = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.TabBarController)
                    self.navigationController?.pushViewController(vc, animated: true)
                } catch {
                    print(error)
                }
            }
        }
    }

}

extension EnterProfilePictureViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        self.profilePictureView.image = image
    }
}
