//
//  WritePostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

typealias NewPostCompletionHandler = ((Post) -> Void)
let MESSAGE_PLACEHOLDER_TEXT = "spill your heart out"
let LOCATION_PLACEHOLDER_TEXT = "doheny Library"

class NewPostViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    var messagePlaceholderLabel : UILabel!
    
    var completionHandler: NewPostCompletionHandler? //for if presented by segue
    
    @objc func tapDone(sender: Any) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
       super.viewDidLoad();
        disablePostButton();
        
        titleTextField.becomeFirstResponder();
        messageTextView.delegate = self;
        locationTextField.delegate = self;
        titleTextField.delegate = self;
        messageTextView.addDoneButton(title: "Done", target: self, selector: #selector(tapDone(sender:)))
        
        //add placeholder text to messageTextView
        //reference: https://stackoverflow.com/questions/27652227/add-placeholder-text-inside-uitextview-in-swift
        messagePlaceholderLabel = UILabel()
        messagePlaceholderLabel.text = "to the boy who..."
        messagePlaceholderLabel.font = messageTextView.font
        messagePlaceholderLabel.sizeToFit()
        messageTextView.addSubview(messagePlaceholderLabel)
        messagePlaceholderLabel.textColor = UIColor.placeholderText
        messagePlaceholderLabel.isHidden = !messageTextView.text.isEmpty
   }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    // MARK: -Buttons
    
    @IBAction func outerViewGestureDidTapped(_ sender: UITapGestureRecognizer) {
        messageTextView.resignFirstResponder();
        titleTextField.resignFirstResponder();
        locationTextField.resignFirstResponder();
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
                try await PostService.uploadPost(title: titleTextField.text!, location: locationTextField.text!, message: messageTextView.text!)
                self.clearAllFields()
                self.dismiss(animated: true)
            } catch {
                //handle post service failed to upload
                print("upload failed!");
            }
        }
        return;
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
        locationTextField.text! = "";
    }
    
    func validateAllFields() -> Bool {
        if (messageTextView.text! == "" || locationTextField.text! == "" || titleTextField.text! == "" ) {
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
