//
//  WritePostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

typealias NewPostCompletionHandler = ((Post) -> Void)

class NewPostViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var messageTextView: UITextViewFixed!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    var messagePlaceholderLabel : UILabel!
    
    var completionHandler: NewPostCompletionHandler? //for if presented by segue
    let MESSAGE_PLACEHOLDER_TEXT = "Spill your heart out"
    let LOCATION_PLACEHOLDER_TEXT = "Doheny Library"
    
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
        messagePlaceholderLabel.font = messageTextView.font;
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
        
        PostService.uploadPost(title: titleTextField.text!, location: locationTextField.text!, message: messageTextView.text!) { newPost in
            if let newPost = newPost {
                clearAllFields();
                self.dismiss(animated: true) {
                    //TODO: send to home view controller
                }
                
                //this "completion handler" code below is not currently used
                if let completionHandler = completionHandler {
                    completionHandler(newPost);
                }
            } else {
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
    
    //TODO: better understand this function vs the one below it
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
        if (messageTextView.textColor == UIColor.placeholderText || messageTextView.text! == "" || locationTextField.text! == "" || titleTextField.text! == "" ) {
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
