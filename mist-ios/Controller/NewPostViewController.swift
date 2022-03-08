//
//  WritePostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

class NewPostViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    override func viewDidLoad() {
       super.viewDidLoad();
   }
    
//    private let DEFINITION_PLACEHOLDER = "뜻을 입력해주세요"
//    private let QUOTE_PLACEHOLDER = "단어를 실생활에서 쓴 예를 들어주세요          (예: '너 완전 바보야...')"
//
//    @IBOutlet weak var contentGuideliensButton: UIButton!
//    @IBOutlet weak var submitPostButton: UIButton!
//    @IBOutlet weak var cancelButton: UIButton!
//
//    @IBOutlet weak var wordTextField: UITextField!
//    @IBOutlet weak var definitionTextView: UITextView!
//    @IBOutlet weak var quoteTextView: UITextView!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        definitionTextView.addDoneButton(title: "완료", target: self, selector: #selector(tapDone(sender:)))
//        quoteTextView.addDoneButton(title: "완료", target: self, selector: #selector(tapDone(sender:)))
//
//        definitionTextView.text = DEFINITION_PLACEHOLDER
//        definitionTextView.textColor =  UIColor.lightGray
//        quoteTextView.text = QUOTE_PLACEHOLDER
//        quoteTextView.textColor = UIColor.lightGray
//
//        wordTextField.delegate = self
//        definitionTextView.delegate = self
//        quoteTextView.delegate = self
//
//        submitPostButton.isEnabled = false
//        submitPostButton.alpha = 0.2
//    }
//
//    @objc func tapDone(sender: Any) {
//        self.view.endEditing(true)
//    }
//
//    func clearFields() {
//        wordTextField.text! = ""
//        definitionTextView.text! = ""
//        quoteTextView.text! = ""
//    }
//
//    @IBAction func outerViewGestureDidTapped(_ sender: UITapGestureRecognizer) {
//        wordTextField.resignFirstResponder()
//        definitionTextView.resignFirstResponder()
//        quoteTextView.resignFirstResponder()
//    }
//
//    @IBAction func submitPostButtonDidPressed(_ sender: UIButton) {
//        PostService.myPosts.uploadPost(word: wordTextField.text!, definition: definitionTextView.text!, quote: quoteTextView.text!) { submitSuccess in
//            if submitSuccess {
//                self.clearFields()
//                self.tabBarController!.selectedIndex = 0
//
//            } else {
//                print("something went wrong!")
//            }
//        }
//    }
//
//    @IBAction func cancelButtonDidPressed(_ sender: UIButton) {
//        clearFields()
//        tabBarController!.selectedIndex = 0
//    }
//
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//    }
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//    }
//
//    //MARK: - editing did end
//
//    @IBAction func nameEditingDidEnd(_ sender: UITextField) {
//        if validateAllFields() {
//            submitPostButton.isEnabled = true
//            submitPostButton.alpha = 1
//        } else {
//            submitPostButton.isEnabled = false
//            submitPostButton.alpha = 0.2
//        }
//    }
//
//    func validateAllFields() -> Bool {
//        if (wordTextField.text! == "" || definitionTextView.text! == "" || quoteTextView.text! == "") {
//            return false
//        }
//        return true
//    }
//
//    //MARK: - manipulating placeholder text
//    func textViewDidBeginEditing(_ textView: UITextView) {
//        print("being")
//        if textView.textColor == UIColor.lightGray {
//            textView.text = ""
//            textView.textColor = UIColor.black
//        }
//    }
//
//    func textViewDidEndEditing(_ textView: UITextView) {
//        print("end")
//        if textView.text.isEmpty {
//            if (textView.accessibilityIdentifier == "definitionTextView") {
//                textView.text = DEFINITION_PLACEHOLDER
//                textView.textColor = UIColor.lightGray
//            } else if (textView.accessibilityIdentifier == "quoteTextView") {
//                textView.text = QUOTE_PLACEHOLDER
//                textView.textColor = UIColor.lightGray
//            }
//        }
//        if validateAllFields() {
//            submitPostButton.isEnabled = true
//            submitPostButton.alpha = 1
//        } else {
//            submitPostButton.isEnabled = false
//            submitPostButton.alpha = 0.2
//        }
//    }
}
