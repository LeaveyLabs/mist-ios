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
    
    enum Sex: String, CaseIterable {
        case blank, female, male, other, ratherNotSay
        
        var displayName: String {
            switch self {
            case .blank:
                return ""
            case .female:
                return "female"
            case .male:
                return "male"
            case .other:
                return "other"
            case .ratherNotSay:
                return "rather not say"
            }
        }
        
        var databaseName: String? {
            switch self {
            case .blank:
                return "" //should never be accessed.. throw?
            case .female:
                return "f"
            case .male:
                return "m"
            case .ratherNotSay:
                return nil
            case .other:
                return "o"
            }
        }
    }
    
//    var dobData = ""
    var sexOptions = [Sex]()
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
        sexOptions = [.blank, .female, .male, .other, .ratherNotSay]

        dobTextField.delegate = self
        dobTextField.layer.cornerRadius = 5
        dobTextField.setLeftAndRightPadding(10)
//        dobTextField.inputView = datePicker
//        datePicker.addTarget(self, action: #selector(handleDatePicker(sender:)), for: .valueChanged)
        dobTextField.becomeFirstResponder()
    }
    
    func setupContinueButton() {
        continueButton.roundCornersViaCornerRadius(radius: 10)
        continueButton.clipsToBounds = true
        continueButton.isEnabled = false
        continueButton.setBackgroundImage(UIImage.imageFromColor(color: Constants.Color.mistLilac), for: .normal)
        continueButton.setBackgroundImage(UIImage.imageFromColor(color: Constants.Color.mistLilac.withAlphaComponent(0.2)), for: .disabled)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.setTitleColor(Constants.Color.mistLilac, for: .disabled)
        continueButton.setTitle("continue", for: .normal)
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
        CustomSwiftMessages.showInfoCentered("why we ask about age", "in order to follow legal guidelines for platforms with user-generated content, we must ensure all account holders are above their country's minimum age requirement.", emoji: "")
    }
    
    //MARK: - TextField Delegate

    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        if sender == dobTextField, sender.text?.count == 10 {
            sexTextField.becomeFirstResponder()
        }
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
            let sexText = sexTextField.text,
            let sex: Sex = sexText == Sex.ratherNotSay.displayName ? .ratherNotSay : Sex(rawValue: sexText),
            sex != .blank
        else {
            CustomSwiftMessages.displayError("no sex option selected", "please try again")
            return
        }
        guard
            let dobComponents = dobTextField.text?.components(separatedBy: "/"),
            dobComponents.count == 3,
            let month = Int(dobComponents[0]),
            let day = Int(dobComponents[1]),
            let year = Int(dobComponents[2]),
            month >= 1 && month <= 12,
            day >= 1 && day <= 31
        else {
            CustomSwiftMessages.displayError("improper birthday formatting", "try again with (mm/dd/yyyy)")
            return
        }
        guard year >= 1940 else {
            CustomSwiftMessages.displayError("there's no way you're that old", "")
            return
        }
        guard year <= 2004 else {
            CustomSwiftMessages.displayError("you must be 18 to use mist", "")
            return
        }
        AuthContext.dob = dobComponents[2] + "-" + dobComponents[0] + "-" + dobComponents[1]
        AuthContext.sex = sex.databaseName
        let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.WelcomeTutorial)
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
        return sexOptions[row].displayName
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        sexTextField.text = sexOptions[pickerView.selectedRow(inComponent: component)].displayName
        validateInput()
    }
    
}
