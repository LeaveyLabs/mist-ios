//
//  GetVerifiedViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/25/22.
//

import Foundation
import UIKit

class GetVerifiedViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var learnMoreLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func verifyButtonDidPressed(_ sender: UIButton) {
        openCamera()
    }
    
    @IBAction func dismissButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
//        presentingViewController!.dismiss(animated: true)
    }
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func verify(selfie: UIImage) {
        
    }
    
}

extension GetVerifiedViewController: UIImagePickerControllerDelegate, ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        guard let image = image else {
            print("nil image..?")
            return
        }
        verify(selfie: image)
    }
    
}
