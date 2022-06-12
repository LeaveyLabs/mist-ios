//
//  PasswordSettingViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/11.
//

import Foundation
import UIKit

class PasswordSettingViewController: UITableViewController {

    var saveButton: UIButton!

    var existingPassword = "" {
        didSet {
            validateInput()
        }
    }
    var newPassword = "" {
        didSet {
            validateInput()
        }
    }
    var confirmPassword = "" {
        didSet {
            validateInput()
        }
    }

    var isSaving: Bool = false {
        didSet {
            saveButton.isEnabled = !isSaving //this state change forces an update for UIButtonConfiguration
            view.isUserInteractionEnabled = !isSaving
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        registerNibs()
        setupSaveButton()
    }
    
    func setupTableView() {
        tableView.keyboardDismissMode = .interactive
        tableView.sectionHeaderTopPadding = 20
        tableView.sectionFooterHeight = 0
    }
    
    func registerNibs() {
        let inputCellNib = UINib(nibName: Constants.SBID.Cell.SimpleInput, bundle: nil)
        tableView.register(inputCellNib, forCellReuseIdentifier: Constants.SBID.Cell.SimpleInput)
    }
    
    func setupSaveButton() {
        saveButton = UIButton(configuration: .plain())
        saveButton.addTarget(self, action: #selector(tryToUpdatePassword), for: .touchUpInside)
        saveButton.configurationUpdateHandler = { button in
            if self.isSaving {
                button.configuration?.showsActivityIndicator = true
                button.configuration?.title = ""
            } else {
                button.configuration?.showsActivityIndicator = false
                button.configuration?.title = "Save"
            }
        }
        saveButton.configuration?.contentInsets = .zero //important step when using a UIButton with configuration in UIBarButtonItem
        saveButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
        saveButton.isEnabled = false //this must come after setting the UIBarButtonItem
    }
    
    //MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.SimpleInput, for: indexPath) as! SimpleInputCell
        cell.textField.autocorrectionType = .no
        cell.textField.autocapitalizationType = .none
        cell.textField.text = ""
        cell.textField.delegate = self
        cell.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        cell.selectionStyle = .none
        switch indexPath.row {
        case 0:
            cell.textField.tag = 0
            cell.textField.placeholder = "Current password"
            cell.textField.textContentType = .password
        case 1:
            cell.textField.tag = 1
            cell.textField.placeholder = "New password"
            cell.textField.textContentType = .newPassword
        case 2:
            cell.textField.tag = 2
            cell.textField.placeholder = "Confirm password"
            cell.textField.textContentType = .newPassword
        default:
            break
        }
        return cell
    }
    
    //MARK: - User Interaction
    
    @IBAction func forgotPasswordDidPressed(_ sender: UIButton) {
        //do something for forgot password
    }

    @IBAction func cancelButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func tryToUpdatePassword() {
        Task {
            isSaving = true
            do {
//                try await UserService.singleton.updatePassword(to: username)
                isSaving = false
                handleSuccessfulUpdate()
            } catch {
                isSaving = false
                CustomSwiftMessages.showError(errorDescription: error.localizedDescription)
            }
        }
    }
    
    //MARK: - Helpers
    
    func validateInput() {
        let isValid = existingPassword.count >= 8 && newPassword == confirmPassword && newPassword.count >= 8
        saveButton.isEnabled = isValid
    }
    
    func handleSuccessfulUpdate() {
        CustomSwiftMessages.showSuccess("Successfully updated", "It's the little wins that count.")
        existingPassword = ""
        newPassword = ""
        confirmPassword = ""
        validateInput()
    }
    
}

// UITextField Target

extension PasswordSettingViewController: UITextFieldDelegate {
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        guard let newText = textField.text else { return }
        switch textField.tag {
        case 0:
            existingPassword = newText
        case 1:
            newPassword = newText
        case 2:
            confirmPassword = newText
        default:
            break
        }
    }
    
    // Max length UI text field: https://stackoverflow.com/questions/25223407/max-length-uitextfield
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return textField.shouldChangeCharactersGivenMaxLengthOf(30, range, string)
    }
}
