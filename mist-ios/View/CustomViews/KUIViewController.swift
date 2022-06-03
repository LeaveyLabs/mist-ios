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
    var isAuthKUIView = false
    var shouldKUIViewKeyboardDismissOnBackgroundTouch = false
    
    @objc func keyboardWillShow(sender: NSNotification) {
        print("keyboard will show")
        // I was trying out this code because in EnterEmailViewController, when autocorrectiontype = no, and there were suggested options displayed to the user, and they clicked on the textview again, the textview/button would bounce. This was solved by setting autocorrecitontype = default, and i found no problem when the iphone default was set to either no or yes autocorrect
//        if bottomConstraintForKeyboard.constant > 0 {
//            return //keyboard is already shown, so dont try to readjust the constraint
//        }
        
        let i = sender.userInfo!
        let s: TimeInterval = (i[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let k = (i[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height

        bottomConstraintForKeyboard.constant = k - view.safeAreaInsets.bottom
        // Note. that is the correct, actual value. Some prefer to use:
        // bottomConstraintForKeyboard.constant = k - bottomLayoutGuide.length
        
        if !isAuthKUIView {
            UIView.animate(withDuration: s) { self.view.layoutIfNeeded() }
        }
    }

    @objc func keyboardWillHide(sender: NSNotification) {
        if !isAuthKUIView {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardNotifications()
        let t = UITapGestureRecognizer(target: self, action: #selector(clearKeyboard))
        view.addGestureRecognizer(t)
        
        //in PostViewController, this line below prevents the submit button tap from being registered while keyboard is up. do not uncomment it, because we want other touches in the view to be registered
//        t.cancelsTouchesInView = false
    }
}
