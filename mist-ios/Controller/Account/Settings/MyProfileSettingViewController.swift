//
//  UsernameSettingViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/01.
//

import UIKit

class MyProfileSettingViewController: UITableViewController {

    var saveButton: UIButton!
    @IBOutlet weak var profilePictureButton: UIButton!
    @IBOutlet weak var miniCameraButton: UIButton!
    
    var imagePicker: ImagePicker!
    
    var firstName: String = UserService.singleton.getFirstName()
    var lastName: String = UserService.singleton.getLastName()
    var username: String = UserService.singleton.getUsername() {
        didSet {
            validateInput()
        }
    }
    var profilePic: UIImage = UserService.singleton.getProfilePic() {
        didSet {
            profilePictureButton.setImage(profilePic.withRenderingMode(.alwaysOriginal), for: .normal)
            validateInput()
        }
    }
    
    var originalUsername: String = UserService.singleton.getUsername()
    var originalProfilePic: UIImage = UserService.singleton.getProfilePic()

    var isSaving: Bool = false {
        didSet {
            saveButton.isEnabled = !isSaving //this state change forces an update for UIButtonConfiguration
            view.isUserInteractionEnabled = !isSaving
        }
    }
    var rerenderProfileCallback: (() -> Void)!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        registerNibs()
        setupButtons()
        setupImagePicker()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        rerenderProfileCallback()
    }
    
    func setupTableView() {
        tableView.keyboardDismissMode = .interactive
        tableView.sectionHeaderTopPadding = 30
        tableView.sectionFooterHeight = 30
    }
    
    func registerNibs() {
        let inputCellNib = UINib(nibName: Constants.SBID.Cell.SimpleInput, bundle: nil)
        tableView.register(inputCellNib, forCellReuseIdentifier: Constants.SBID.Cell.SimpleInput)
    }
    
    func setupButtons() {
        setupSaveButton()
        miniCameraButton.becomeRound()
        profilePictureButton.imageView?.becomeProfilePicImageView(with: profilePic)
    }
    
    func setupSaveButton() {
        saveButton = UIButton(configuration: .plain())
        saveButton.addTarget(self, action: #selector(tryToUpdateProfile), for: .touchUpInside)
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
    
    func setupImagePicker() {
        imagePicker = ImagePicker(presentationController: self, delegate: self)
    }
    
    //MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "NAME"
        } else {
            return "USERNAME"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Your name can't be changed after signing up."
        } else {
            return ""
        }
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.SimpleInput, for: indexPath) as! SimpleInputCell
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textField.text = firstName
            } else {
                cell.textField.text = lastName
            }
            cell.textField.isEnabled = false
        } else {
            cell.textField.autocorrectionType = .no
            cell.textField.autocapitalizationType = .none
            cell.textField.text = username
            cell.textField.delegate = self
            cell.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    //MARK: - User Interaction

    @IBAction func didPressedChoosePhotoButton(_ sender: UIButton) {
        imagePicker.present(from: sender)
    }
    
    @IBAction func cancelButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func tryToUpdateProfile() {
        Task {
            isSaving = true
            do {
                try await UserService.singleton.updateUsername(to: username)
                try await UserService.singleton.updateProfilePic(to: profilePic)
                isSaving = false
                handleSuccessfulUpdate()
            } catch {
                isSaving = false
                CustomSwiftMessages.displayError(error)
            }
        }
    }
    
    //MARK: - Helpers
    
    func validateInput() {
        let isValid = username.count > 3 && !(username == originalUsername && profilePic == originalProfilePic)
        saveButton.isEnabled = isValid
    }
    
    func handleSuccessfulUpdate() {
        CustomSwiftMessages.showSuccess("Successfully updated", "It's the little wins that count.")
        originalUsername = username
        originalProfilePic = profilePic
        validateInput()
    }
    
}

// UITextField Target

extension MyProfileSettingViewController: UITextFieldDelegate {
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        guard let newUsername = textField.text else { return }
        username = newUsername
    }
    
    // Max length UI text field: https://stackoverflow.com/questions/25223407/max-length-uitextfield
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return textField.shouldChangeCharactersGivenMaxLengthOf(20, range, string)
    }
}

extension MyProfileSettingViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        guard let newImage = image else { return }
        profilePic = newImage
    }
    
}
