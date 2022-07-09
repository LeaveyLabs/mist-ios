//
//  EnterBiosViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/8/22.
//

import Foundation
import UIKit

class EnterBiosViewController: KUIViewController, UITextFieldDelegate {
    
    
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker(frame: .zero)
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "en_US")
        if #available(iOS 14, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        
        var dateComponents = DateComponents()
        dateComponents.year = 2000
        dateComponents.month = 1
        dateComponents.day = 1
        let startingDate = Calendar.current.date(from: dateComponents)!
        let minimumAge = Calendar.current.date(byAdding: .year, value: -13, to: Date())!
        
        datePicker.date = startingDate
        datePicker.maximumDate = minimumAge
        return datePicker
    }()
    
    let RATHER_NOT_SAY = "Rather not say"
    var dobData = ""
    var sexOptions = [String]()
    private lazy var sexPicker: UIPickerView = {
        let sexPicker = UIPickerView(frame: .zero)
        sexPicker.delegate = self
        sexPicker.dataSource = self
        return sexPicker
    }()

    @IBOutlet weak var sexTextField: UITextField!
    @IBOutlet weak var dobTextField: UITextField!

    @IBOutlet weak var continueButton: UIButton!
    var isValidInput: Bool! {
        didSet {
            continueButton.isEnabled = isValidInput
            continueButton.setNeedsUpdateConfiguration()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        validateInput()
        shouldNotAnimateKUIAccessoryInputView = true
        setupTextFields()
        setupContinueButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enableInteractivePopGesture()
        validateInput()
    }

    //MARK: - Setup

    func setupTextFields() {
        sexTextField.delegate = self
        sexTextField.layer.cornerRadius = 5
        sexTextField.setLeftAndRightPadding(10)
        sexTextField.inputView = sexPicker
        sexOptions = ["", "Male", "Female", RATHER_NOT_SAY]

        dobTextField.delegate = self
        dobTextField.layer.cornerRadius = 5
        dobTextField.setLeftAndRightPadding(10)
        dobTextField.inputView = datePicker
        datePicker.addTarget(self, action: #selector(handleDatePicker(sender:)), for: .valueChanged)
        dobTextField.becomeFirstResponder()
    }

    func setupContinueButton() {
        continueButton.configurationUpdateHandler = { button in
            if button.isEnabled {
                button.configuration = ButtonConfigs.enabledConfig(title: "Continue")
            }
            else {
                button.configuration = ButtonConfigs.disabledConfig(title: "Continue")
            }
        }
    }

    //MARK: - User Interaction
    
    @objc func handleDatePicker(sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        dateFormatter.locale = Locale(identifier: "en_US")
        dobTextField.text = dateFormatter.string(from: sender.date)
        dateFormatter.dateFormat = "dd MMM yyyy"
        dobData = dateFormatter.string(from: sender.date)
        validateInput()
     }

    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func didPressedContinueButton(_ sender: UIButton) {
        tryToContinue()
    }

    @IBAction func whyWeAskDidTapped(_ sender: UIButton) {
        CustomSwiftMessages.showInfoCentered("We make sure that", "In order to make sure that everyone who uses Mist comply with our minimum age requirement", emoji: "🫡")
    }
    
    //MARK: - TextField Delegate

    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        validateInput()
    }

    //MARK: - Helpers

    func tryToContinue() {
        if let _ = dobTextField.text, let sex = sexTextField.text {
            AuthContext.dob = dobData
            AuthContext.sex = sex == RATHER_NOT_SAY ? nil : sex
            let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.UploadProfilePicture)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func validateInput() {
        isValidInput = dobTextField.text!.count > 0 && sexTextField.text!.count > 0
    }
}

extension EnterBiosViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        4
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sexOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        sexTextField.text = sexOptions[pickerView.selectedRow(inComponent: component)]
        validateInput()
    }
    
}
