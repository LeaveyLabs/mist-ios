//
//  UsernameSettingViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/01.
//

import UIKit

class UsernameSettingViewController: UITableViewController {

//    @IBOutlet weak var settingTableView: UITableView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var username: String = "adamvnovak"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveButton.isEnabled = false
        usernameTextField.becomeFirstResponder()
        tableView.isScrollEnabled = false
        
        usernameTextField.text = "@" + username
        
        //TODO: add shadow/border around a section in "inset groupped" table view
        tableView.layer.shadowColor = UIColor.gray.cgColor
    }
    
    //MARK: -UserInteraction
    @IBAction func cancelButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func saveButtonDidPressed(_ sender: UIBarButtonItem) {
        if !validateAllFields() {
            return;
        }
        updateUsernameInDatabase(username: usernameTextField.text!)
        
        //TODO: if bad result, display button that flies up
        navigationController?.popViewController(animated: true)
    }
    
    //MARK: -Database
    func updateUsernameInDatabase(username: String) {
        //TODO:
    }
    
    //MARK: -TextField
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        //TODO: ensure at least "@" is always there
        
        if validateAllFields() {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false;
        }
    }
    
    func validateAllFields() -> Bool {
        if (usernameTextField.text! == "" || usernameTextField.text! == "@"+username) {
            return false
        } else {
            return true;
        }
    }
}
