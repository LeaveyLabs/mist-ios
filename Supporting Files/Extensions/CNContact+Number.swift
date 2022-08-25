//
//  CNContact+Number.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/16/22.
//

import Foundation
import Contacts
import PhoneNumberKit

let phoneNumberKit = PhoneNumberKit()

extension CNContact {
    var generatedUsername: String {
        return (givenName + "_" + familyName + randomStringOfNumbers(length: 3)).lowercased()
    }
    
    var bestPhoneNumberPretty: String? {
        return bestPhoneNumber
    }
    
    var bestPhoneNumberE164: String? {
        guard let best = bestPhoneNumber else { return nil }
        do {
            let phoneNumber = try phoneNumberKit.parse(best)
            return phoneNumberKit.format(phoneNumber, toType: .e164) // +61236618300
        } catch {
            return nil
        }
    }
    
    private var bestPhoneNumber: String? {
        var best: String?
        
        guard phoneNumbers.count > 0 else { return nil } //dont autoComplete contacts without numbers
        if phoneNumbers.count == 1 {
            best = phoneNumbers[0].value.stringValue
        } else {
            for cnNumber in phoneNumbers {
                if cnNumber.label == CNLabelPhoneNumberMain ||
                    cnNumber.label == CNLabelPhoneNumberiPhone ||
                    cnNumber.label == CNLabelPhoneNumberMobile {
                    best = cnNumber.value.stringValue
                }
            }
        }
        guard best?.rangeOfCharacter(from: .letters) == nil else { return nil } //in case the person saved an email as a phone number
        return best
    }
}

extension String {
    
    var asE164PhoneNumber: String? {
        do {
            let phoneNumber = try phoneNumberKit.parse(self)
            return phoneNumberKit.format(phoneNumber, toType: .e164) // +61236618300
        } catch {
            return nil
        }
    }
    
    var asNationalPhoneNumber: String? {
        do {
            let phoneNumber = try phoneNumberKit.parse(self)
            return phoneNumberKit.format(phoneNumber, toType: .national)
        } catch {
            return nil
        }
    }
    
}
