//
//  UsernameSettingViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/01.
//

import UIKit

class UpdateProfileSettingViewController: UITableViewController {

    //MARK: - Properties
    
    var saveButton: UIButton!
    @IBOutlet weak var profilePictureButton: UIButton!
    @IBOutlet weak var miniCameraButton: UIButton!
    @IBOutlet weak var verifiedButton: UIButton!
    
    var firstNameTextField: UITextField!
    var lastNameTextField: UITextField!
    var usernameTextField: UITextField!
    var imagePicker: ImagePicker!
    
    var firstName: String = UserService.singleton.getFirstName() {
        didSet { validateInput() }
    }
    var lastName: String = UserService.singleton.getLastName() {
        didSet { validateInput() }
    }
    var username: String = UserService.singleton.getUsername() {
        didSet { validateInput() }
    }
    var profilePic: UIImage = UserService.singleton.getProfilePic() {
        didSet {
            profilePictureButton.setImage(profilePic.withRenderingMode(.alwaysOriginal), for: .normal)
            validateInput()
        }
    }

    var isSaving: Bool = false {
        didSet {
            saveButton.setTitle(isSaving ? "" : "save", for: .normal)
            saveButton.loadingIndicator(isSaving)
            saveButton.isEnabled = !isSaving //this state change forces an update for UIButtonConfiguration
            view.isUserInteractionEnabled = !isSaving
        }
    }
    var rerenderProfileCallback: (() -> Void)!

    //MARK: - Lifecycle
    
    override func loadView() { //you should load programmatically created views here
        super.loadView()
        setupSaveButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        registerNibs()
        setupButtons()
        validateInput()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)), style: .plain, target: self, action: #selector(cancelButtonDidPressed(_:)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupIsVerifiedButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupImagePicker()
        enableInteractivePopGesture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        rerenderProfileCallback()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disableInteractivePopGesture()
    }
    
    //MARK: - Setup
    
    func setupTableView() {
        tableView.keyboardDismissMode = .interactive
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 10
        } else {
            // Fallback on earlier versions
        }
        tableView.sectionFooterHeight = 10
    }
    
    func registerNibs() {
        let inputCellNib = UINib(nibName: Constants.SBID.Cell.SimpleInput, bundle: nil)
        tableView.register(inputCellNib, forCellReuseIdentifier: Constants.SBID.Cell.SimpleInput)
        let badgeCellNib = UINib(nibName: Constants.SBID.Cell.BadgesCell, bundle: nil)
        tableView.register(badgeCellNib, forCellReuseIdentifier: Constants.SBID.Cell.BadgesCell)
    }
    
    func setupIsVerifiedButton() {
        let isVerified = UserService.singleton.isVerified()
        verifiedButton.roundCorners(corners: .allCorners, radius: 8)
        verifiedButton.backgroundColor = isVerified ? .clear : .white
        verifiedButton.applyMediumShadow()
        verifiedButton.layer.shadowOpacity = isVerified ? 0 : 1
        verifiedButton.setImage(isVerified ? UIImage(systemName: "checkmark.seal.fill") : UIImage(systemName: "exclamationmark.circle.fill"), for: .normal)
        verifiedButton.tintColor = isVerified ? Constants.Color.mistLilac : .systemRed
        verifiedButton.setTitle(isVerified ? "verified" : "get verified", for: .normal)
        verifiedButton.isEnabled = !isVerified
        
        //shadow not working?????
//        verifiedButton.applyMediumShadow()
//        applyShadowOnView(verifiedButton)
//        verifiedButton.titleLabel.font = UIFont(name: Constants.Font.Medium, size: 18)
    }
    
    func setupButtons() {
        miniCameraButton.becomeRound()
        profilePictureButton.imageView?.becomeProfilePicImageView(with: profilePic)
        setupIsVerifiedButton()
    }
    
    func setupSaveButton() {
        saveButton = UIButton()
        saveButton.roundCornersViaCornerRadius(radius: 10)
        saveButton.addTarget(self, action: #selector(tryToUpdateProfile), for: .touchUpInside)
        saveButton.clipsToBounds = true
        saveButton.isEnabled = false
        saveButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        saveButton.setTitleColor(Constants.Color.mistBlack, for: .normal)
        saveButton.setTitleColor(.lightGray, for: .disabled)
        saveButton.setTitle("save", for: .normal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
    }
    
    func setupImagePicker() {
        imagePicker = ImagePicker(presentationController: self, delegate: self, pickerSources: [.camera, .photoLibrary])
    }
    
    //MARK: - Table View
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else if section == 1 {
            return 1
        } else {
            return 1 //badges
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "name"
        } else if section == 1 {
            return "username"
        } else {
            return "badges"
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard
            let header:UITableViewHeaderFooterView = view as? UITableViewHeaderFooterView,
            let textLabel = header.textLabel
        else { return }
        textLabel.font = UIFont(name: Constants.Font.Roman, size: 15)
        textLabel.text = textLabel.text?.lowercased()
    }
    
//    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
//        if section == 0 {
//            return "your real name can't be changed."
//        } else {
//            return "letters, numbers, underscores and periods"
//        }
//    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.SimpleInput, for: indexPath) as! SimpleInputCell
        cell.textField.delegate = self
        cell.selectionStyle = .none
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textField.text = firstName
                firstNameTextField = cell.textField
                firstNameTextField.autocapitalizationType = .words
                cell.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            } else {
                cell.textField.text = lastName
                lastNameTextField = cell.textField
                lastNameTextField.autocapitalizationType = .words
                cell.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            }
        } else if indexPath.section == 1 {
            usernameTextField = cell.textField
            cell.textField.autocorrectionType = .no
            cell.textField.autocapitalizationType = .none
            cell.textField.text = username
            cell.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        } else {
            let badgesCell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.BadgesCell, for: indexPath) as! BadgesCell
            badgesCell.configureWith(username: UserService.singleton.getUsername(), badges: UserService.singleton.getBadges())
            badgesCell.selectionStyle = .none
            return badgesCell
        }
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
        view.endEditing(true)
        isSaving = true
        Task {
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    if firstName != UserService.singleton.getFirstName() {
                        group.addTask {
                            try await UserService.singleton.updateFirstName(to: self.firstName)
                        }
                    }
                    if lastName != UserService.singleton.getLastName() {
                        group.addTask {
                            try await UserService.singleton.updateLastName(to: self.lastName)
                        }
                    }
                    if username != UserService.singleton.getUsername() {
                        group.addTask {
                            try await UserService.singleton.updateUsername(to: self.username.lowercased())
                        }
                    }
                    if profilePic != UserService.singleton.getProfilePic() {
                        group.addTask {
                            try await UserService.singleton.updateProfilePic(to: self.profilePic)
                        }
                    }
                    try await group.waitForAll()
                }
                handleSuccessfulUpdate()
            } catch {
                CustomSwiftMessages.displayError(error)
            }
            isSaving = false
        }
    }
    
    //MARK: - Helpers
    
    func validateInput() {
        let isNewName = firstName.count > 0 && lastName.count > 0 && (firstName != UserService.singleton.getFirstName() || lastName != UserService.singleton.getLastName())
        let isNewUsername = Validate.validateUsername(username) && username != UserService.singleton.getUsername()
        let isNewPic = profilePic != UserService.singleton.getProfilePic()
        let isValid = isNewPic || isNewName || isNewUsername
        saveButton.isEnabled = isValid
    }
    
    func handleSuccessfulUpdate() {
        CustomSwiftMessages.showSuccess("successfully updated", "your profile is really popping off")
        DispatchQueue.main.async {
            self.validateInput()
            self.saveButton.isEnabled = false
        }
    }
    
}

// UITextField Target

extension UpdateProfileSettingViewController: UITextFieldDelegate {
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        guard let newText = textField.text else { return }
        if textField == firstNameTextField {
            firstName = newText
        } else if textField == lastNameTextField {
            lastName = newText
        } else if textField == usernameTextField {
            username = newText
        }
    }
    
    // Max length UI text field: https://stackoverflow.com/questions/25223407/max-length-uitextfield
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return textField.shouldChangeCharactersGivenMaxLengthOf(20, range, string)
    }
}

extension UpdateProfileSettingViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        guard let newImage = image else { return }
        profilePic = newImage
    }
    
}
