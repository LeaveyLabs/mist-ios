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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension EnterProfilePictureViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        self.profilePictureView.image = image
    }
}
