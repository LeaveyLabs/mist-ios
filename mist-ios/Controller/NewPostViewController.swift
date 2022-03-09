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
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    
    var completionHandler: NewPostCompletionHandler? //for if presented by segue
    let MESSAGE_PLACEHOLDER_TEXT = "Spill your heart out"
    let LOCATION_PLACEHOLDER_TEXT = "Doheny Library"
    
    @objc func tapDone(sender: Any) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
       super.viewDidLoad();
        disablePostButton();
        messageTextView.textColor = UIColor.placeholderText;
        titleTextField.becomeFirstResponder();
        messageTextView.delegate = self;
        locationTextField.delegate = self;
        titleTextField.delegate = self;
        messageTextView.selectedTextRange = messageTextView.textRange(from: messageTextView.beginningOfDocument, to: messageTextView.beginningOfDocument) //puts cursor infront of plcaeholder text
        messageTextView.addDoneButton(title: "Done", target: self, selector: #selector(tapDone(sender:)))
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
        if validateAllFields() {
            enablePostButton();
        } else {
            disablePostButton()
        }
    }
    
    //detect changes in textView
    //source: https://stackoverflow.com/questions/27652227/add-placeholder-text-inside-uitextview-in-swift
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        // Combine the textView text and the replacement text to
        // create the updated text string
        let currentText:String = textView.text
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)

        // If updated text view will be empty, add the placeholder
        // and set the cursor to the beginning of the text view
        if updatedText.isEmpty {
            textView.text = MESSAGE_PLACEHOLDER_TEXT
            textView.textColor = UIColor.placeholderText;
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)

        }

        // Else if the text view's placeholder is showing and the
        // length of the replacement string is greater than 0, set
        // the text color to black then set its text to the
        // replacement string
         else if textView.textColor == UIColor.placeholderText && !text.isEmpty {
            textView.textColor = UIColor.black
            textView.text = text

        }

        // For every other case, the text should change with the usual behavior...
        else {
            if validateAllFields() {
                enablePostButton();
            } else {
                disablePostButton()
            }
            return true
        }
        
        //TODO: is this code below ever actually reached?
        if validateAllFields() {
            enablePostButton();
        } else {
            disablePostButton()
        }

        // ...otherwise return false since the updates have already been made
        return false
    }
    
    //prevent user from changing cursor position while placeholder text is visible
    func textViewDidChangeSelection(_ textView: UITextView) {
        //textViewDidChangeSelection is called before the view loads so only check the text view's color if the window is visible
        if self.view.window != nil {
            if textView.textColor == UIColor.placeholderText {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
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
