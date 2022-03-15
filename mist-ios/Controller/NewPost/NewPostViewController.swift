//
//  WritePostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit
import CoreLocation
import MapKit

let MESSAGE_PLACEHOLDER_TEXT = "To the boy who..."
let LOCATION_PLACEHOLDER_TEXT = "Drop a pin"

class NewPostViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var titleTextField: UITextField!
    var messagePlaceholderLabel : UILabel!
    var currentlyPinnedAnnotation: MKPointAnnotation?
        
    @objc func tapDone(sender: Any) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
       super.viewDidLoad();
        disablePostButton();
        //TODO: fix button positioning
//        locationButton.configuration?.imagePadding = .greatestFiniteMagnitude
//        locationButton.configuration?.imagePadding = CGFloat(180)
//        NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                
        locationButton.titleLabel!.adjustsFontSizeToFitWidth = false
        locationButton.titleLabel!.lineBreakMode = .byTruncatingTail
        titleTextField.becomeFirstResponder();
        messageTextView.delegate = self;
        titleTextField.delegate = self;
        messageTextView.addDoneButton(title: "Done", target: self, selector: #selector(tapDone(sender:)))
        
        //add placeholder text to messageTextView
        //reference: https://stackoverflow.com/questions/27652227/add-placeholder-text-inside-uitextview-in-swift
        messagePlaceholderLabel = UILabel()
        messagePlaceholderLabel.text = MESSAGE_PLACEHOLDER_TEXT
        messagePlaceholderLabel.font = messageTextView.font
        messagePlaceholderLabel.sizeToFit()
        messageTextView.addSubview(messagePlaceholderLabel)
        messagePlaceholderLabel.textColor = UIColor.placeholderText
        messagePlaceholderLabel.isHidden = !messageTextView.text.isEmpty
   }
    
    // MARK: -Buttons
    
    @IBAction func outerViewGestureDidTapped(_ sender: UITapGestureRecognizer) {
        messageTextView.resignFirstResponder();
        titleTextField.resignFirstResponder();
    }
    
    @IBAction func deleteDidPressed(_ sender: UIBarButtonItem) {
        //TODO: prompt save as draft?
        clearAllFields();
        self.dismiss(animated: true)
    }
    
    @IBAction func userDidTappedPostButton(_ sender: UIButton) {
        if !validateAllFields() {
            return;
        }
        
        Task {
            do {
                try await PostService.uploadPost(title: titleTextField.text!, location: locationButton.titleLabel!.text!, message: messageTextView.text!)
                self.clearAllFields()
                self.dismiss(animated: true)
            } catch {
                //handle post service failed to upload
                print("upload failed!");
            }
        }
        return;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let pinMapVC = segue.destination as! PinMapViewController
        //get the coordinates from the pin that the user just dropped
        pinMapVC.pinnedAnnotation = currentlyPinnedAnnotation
        pinMapVC.completionHandler = { [self] (newAnnotation, newDescription) in
            currentlyPinnedAnnotation = newAnnotation
            locationButton!.setTitle(newDescription, for: .normal)
            locationButton!.setTitleColor(.black, for: .normal)
        }
    }
    
    //MARK: -TextField
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        if validateAllFields() {
            postButton.isEnabled = true
        } else {
            postButton.isEnabled = false;
        }
    }
    
    //MARK: -TextView
    
    func textViewDidChange(_ textView: UITextView) {
        messagePlaceholderLabel.isHidden = !messageTextView.text.isEmpty
        if validateAllFields() {
            enablePostButton();
        } else {
            disablePostButton()
        }
    }
    
    //MARK: -Util
    
    func clearAllFields() {
        messageTextView.text! = ""
        titleTextField.text! = "";
        locationButton.titleLabel!.text! = LOCATION_PLACEHOLDER_TEXT;
    }
    
    func validateAllFields() -> Bool {
        if (messageTextView.text! == "" || locationButton.titleLabel!.text! == "" || titleTextField.text! == "" ) {
            return false
        } else {
            return true;
        }
    }
    
    func enablePostButton() {
         postButton.isEnabled = true;
         postButton.alpha = 1;
    }
    
    func disablePostButton() {
         postButton.isEnabled = false;
         postButton.alpha = 0.99;
    }
}
