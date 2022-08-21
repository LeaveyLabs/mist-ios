//
//  EnterBiosViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/8/22.
//

import Foundation
import UIKit

class EnterBiosViewController: KUIViewController, UITextFieldDelegate {
    
    //MARK: - Properties
    
//    private lazy var datePicker: UIDatePicker = {
//        let datePicker = UIDatePicker(frame: .zero)
//        datePicker.datePickerMode = .date
//        datePicker.locale = Locale(identifier: "en_US")
//        if #available(iOS 14, *) {
//            datePicker.preferredDatePickerStyle = .wheels
//        }
//
//        var dateComponents = DateComponents()
//        dateComponents.year = 2000
//        dateComponents.month = 1
//        dateComponents.day = 1
//        let startingDate = Calendar.current.date(from: dateComponents)!
//        let minimumAge = Calendar.current.date(byAdding: .year, value: -18, to: Date())!
//
//        datePicker.date = startingDate
//        datePicker.maximumDate = minimumAge
//        return datePicker
//    }()
    
    let RATHER_NOT_SAY = "Rather not say"
//    var dobData = ""
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
    
    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        validateInput()
        shouldNotAnimateKUIAccessoryInputView = true
        setupTextFields()
        setupContinueButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disableInteractivePopGesture()
        validateInput()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dobTextField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        enableInteractivePopGesture()
    }

    //MARK: - Setup

    func setupTextFields() {
        sexTextField.delegate = self
        sexTextField.layer.cornerRadius = 5
        sexTextField.setLeftAndRightPadding(10)
        sexTextField.inputView = sexPicker
        sexOptions = ["", "Male", "Female", "Other", RATHER_NOT_SAY]

        dobTextField.delegate = self
        dobTextField.layer.cornerRadius = 5
        dobTextField.setLeftAndRightPadding(10)
//        dobTextField.inputView = datePicker
//        datePicker.addTarget(self, action: #selector(handleDatePicker(sender:)), for: .valueChanged)
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
    
//    @objc func handleDatePicker(sender: UIDatePicker) {
//        let dateFormatter = DateFormatter()
//        dateFormatter.locale = Locale(identifier: "en_US")
//        dateFormatter.dateFormat = "MMMM d, yyyy"
//        dobTextField.text = dateFormatter.string(from: sender.date)
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        dobData = dateFormatter.string(from: sender.date)
//        validateInput()
//     }

//    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
//        navigationController?.popViewController(animated: true)
//    }

    @IBAction func didPressedContinueButton(_ sender: UIButton) {
        tryToContinue()
    }

    @IBAction func whyWeAskDidTapped(_ sender: UIButton) {
        CustomSwiftMessages.showInfoCentered("Why we ask about age", "In order to follow legal guidelines for platforms with user-generated content, we must ensure all account holders are above their country's minimum age requirement.", emoji: "")
    }
    
    //MARK: - TextField Delegate

    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        validateInput()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == dobTextField {
            //Handle dobTextField formatting
            if dobTextField.text?.count == 2 || dobTextField.text?.count == 5 {
                //Handle backspace being pressed
                if !(string == "") {
                    // append the text
                    dobTextField.text = dobTextField.text! + "/"
                }
            }
            // check the condition not exceed 9 chars
            return !(textField.text!.count > 9 && (string.count ) > range.length)
        } else {
            return true
        }
    }

    //MARK: - Helpers

    func tryToContinue() {
        guard
            let sex = sexTextField.text,
            let dobComponents = dobTextField.text?.components(separatedBy: "/"),
            dobComponents.count == 3,
            let month = Int(dobComponents[0]),
            let day = Int(dobComponents[1]),
            let year = Int(dobComponents[2]),
            month >= 1 && month <= 12,
            day >= 1 && day <= 31
        else {
            CustomSwiftMessages.displayError("Something doesn't seem right", "Please try again")
            return
        }
        guard year <= 2004 else {
            CustomSwiftMessages.displayError("You must be 18 to use Mist", "")
            return
        }
//            AuthContext.dob = dobData
        AuthContext.dob = dobComponents[2] + "-" + dobComponents[0] + "-" + dobComponents[1]
        print(AuthContext.dob)
        AuthContext.sex = sex == RATHER_NOT_SAY ? nil : sex == "Male" ? "m" : sex == "Female" ? "f" : "o"
        let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ChooseUsername)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func validateInput() {
        isValidInput = dobTextField.text!.count == 10 && sexTextField.text!.count > 0
    }
}

extension EnterBiosViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        5
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sexOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        sexTextField.text = sexOptions[pickerView.selectedRow(inComponent: component)]
        validateInput()
    }
    
}
