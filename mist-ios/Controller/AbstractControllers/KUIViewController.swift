//
//  KUIViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit

//reference: https://stackoverflow.com/questions/30691740/resize-the-screen-when-keyboard-appears
class KUIViewController: UIViewController {

    // KBaseVC is the KEYBOARD variant BaseVC. more on this later

    @IBOutlet var bottomConstraintForKeyboard: NSLayoutConstraint!
    var shouldNotAnimateKUIAccessoryInputView = false
    var shouldKUIViewKeyboardDismissOnBackgroundTouch = false
    var isKeyboardPresented = false
    
    var k: CGFloat = 0
    
    @objc func keyboardWillShow(sender: NSNotification) {
        isKeyboardPresented = true
                
        let i = sender.userInfo!
        let s: TimeInterval = (i[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let previousK = k
        k = (i[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        
        //Wait 0.05 seconds in case the keyboard was adjusted twice during that time frame because of keyboard autocorrection updates.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
            if k != previousK {
                bottomConstraintForKeyboard.constant = k - view.safeAreaInsets.bottom
                // Note. that is the correct, actual value. Some prefer to use:
                // bottomConstraintForKeyboard.constant = k - bottomLayoutGuide.length
                
                if !shouldNotAnimateKUIAccessoryInputView {
                    UIView.animate(withDuration: s) { self.view.layoutIfNeeded() }
                }
            }
        }
        
        //Alternatively, only adjust the keyboard when it increases in height or when it's entirely dismissed.
        //Don't adjust the keyboard when the height remains the same or becomes smaller.
        //This prevents flickers when pressing "return" key with apple autocomplete
        //Autocorrection = yes also prevents this issue within a textfield. However, it doesn't prevent the issue when jumping from one textview to the next within the same VC. To prevent that flicker, we need the below code
//        if k > previousK || k == 0 {
//            bottomConstraintForKeyboard.constant = k - view.safeAreaInsets.bottom
//            // Note. that is the correct, actual value. Some prefer to use:
//            // bottomConstraintForKeyboard.constant = k - bottomLayoutGuide.length
//
//            if !shouldNotAnimateKUIAccessoryInputView {
//                UIView.animate(withDuration: s) { self.view.layoutIfNeeded() }
//            }
//        }
    }

    @objc func keyboardWillHide(sender: NSNotification) {
        isKeyboardPresented = false
        if !shouldNotAnimateKUIAccessoryInputView {
            let info = sender.userInfo!
            let s: TimeInterval = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            bottomConstraintForKeyboard.constant = 0
            UIView.animate(withDuration: s) { self.view.layoutIfNeeded() }
        }
    }
    
    @objc func clearKeyboard() {
        if shouldKUIViewKeyboardDismissOnBackgroundTouch {
            view.endEditing(true)
        }
        // (subtle iOS bug/problem in obscure cases: see note below
        // you may prefer to add a short delay here)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let t = UITapGestureRecognizer(target: self, action: #selector(clearKeyboard))
        view.addGestureRecognizer(t)
        
        //in PostViewController, this line below prevents the submit button tap from being registered while keyboard is up. do not uncomment it, because we want other touches in the view to be registered
//        t.cancelsTouchesInView = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardNotifications()
    }
    
    func keyboardNotifications() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
}
