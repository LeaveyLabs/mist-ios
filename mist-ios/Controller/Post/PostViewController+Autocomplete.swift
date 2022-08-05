//
//  PostViewController+Autocomplete.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/3/22.
//

import Foundation
import UIKit
import Contacts
import InputBarAccessoryView //dependency of MessageKit. If we remove MessageKit, we should install this package independently

enum AutocompleteContext: String {
    case id, number, pic
}

extension PostViewController: AutocompleteManagerDelegate, AutocompleteManagerDataSource {
    
    // MARK: - AutocompleteManagerDataSource
    
    func autocompleteManager(_ manager: AutocompleteManager, autocompleteSourceFor prefix: String) -> [AutocompleteCompletion] {
        return prefix == "@" ? asyncCompletions : []
    }
    
    func autocompleteManager(_ manager: AutocompleteManager, tableView: UITableView, cellForRowAt indexPath: IndexPath, for session: AutocompleteSession) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AutocompleteCell.reuseIdentifier, for: indexPath) as? AutocompleteCell else {
            fatalError("Oops, some unknown error occurred")
        }
        let completion = asyncCompletions[indexPath.row]
        
        //what is session / manager?????
        
//        let users = SampleData.shared.users
//        let name = session.completion?.text ?? ""
//        let user = users.filter { return $0.name == name }.first
        
        cell.imageView?.image = completion.context?[AutocompleteContext.pic.rawValue] as? UIImage ?? UIImage(systemName: "phone")!
        cell.textLabel?.attributedText = manager.attributedText(matching: session, fontSize: 16)
//        cell.detailTextLabel?.text = "From contacts"
//        cell.detailTextLabel?.font = UIFont(name: Constants.Font.Medium, size: 10)
        cell.layoutSubviews()
        return cell
    }
    
    // MARK: - AutocompleteManagerDelegate
    
    func autocompleteManager(_ manager: AutocompleteManager, shouldBecomeVisible: Bool) {
        setAutocompleteManager(active: shouldBecomeVisible)
    }
    
    // Optional
    func autocompleteManager(_ manager: AutocompleteManager, shouldRegister prefix: String, at range: NSRange) -> Bool {
        autocompleteManager.updateTopLineViewY()
        print("SHOUDL REGISTER")
        return true
    }
    
    // Optional
    func autocompleteManager(_ manager: AutocompleteManager, shouldUnregister prefix: String) -> Bool {
        print("SHOULD UNREGISTER")

        return true
    }
        
    // Optional
    func autocompleteManager(_ manager: AutocompleteManager, shouldComplete prefix: String, with text: String) -> Bool {
        print("SHOULD COMPLETE")
        autocompleteManager.invalidate()
        return true
    }
        
    // MARK: - AutocompleteManagerDelegate Helper
    
    func setAutocompleteManager(active: Bool) {
        let topStackView = inputBar.topStackView
        if active && !topStackView.arrangedSubviews.contains(autocompleteManager.tableView) {
            topStackView.insertArrangedSubview(autocompleteManager.tableView, at: topStackView.arrangedSubviews.count)
            topStackView.layoutIfNeeded()
        } else if !active && topStackView.arrangedSubviews.contains(autocompleteManager.tableView) {
            topStackView.removeArrangedSubview(autocompleteManager.tableView)
            topStackView.layoutIfNeeded()
//            asyncCompletions = []
        }
        inputBar.invalidateIntrinsicContentSize()
    }
    
    //MARK: - Helpers
    
    func processAutocomplete(_ updatedText: String) {
        guard let lastWord = updatedText.components(separatedBy: [" ", "\n"]).last else { return }
        let isPrefixValid = lastWord.first == "@"
        if !isPrefixValid {
            autocompleteManager.invalidate() //this also causes the tableview to fall down
        }
        
        guard autocompleteManager.currentSession != nil, autocompleteManager.currentSession?.prefix == "@" else { return }
        loadAutocompleteData(firstWord: lastWord, secondWord: nil) //PostViewController+Autocomplete
    }
    
    func loadAutocompleteData(firstWord: String, secondWord: String?) {
        Task {
            do {
                var suggestedContacts = [CNContact]()
                if CNContactStore.authorizationStatus(for: .contacts) == .authorized  {
                    suggestedContacts = fetchSuggestedContacts(partialString: firstWord)
                } else if !hasPromptedUserForContactsAccess {
                    hasPromptedUserForContactsAccess = true
                    requestContactsAccessIfNecessary { authorized in
                        suggestedContacts = self.fetchSuggestedContacts(partialString: firstWord)
                    }
                }
                
                let suggestedUsers = try await UserAPI.fetchUsersByText(containing: firstWord)
                print(" SUGGESTED USERS:", suggestedUsers)
                let frontendSuggestedUsers = try await Array(UserAPI.batchTurnUsersIntoFrontendUsers(suggestedUsers).values)

                asyncCompletions = turnResultsIntoAutocompletions(frontendSuggestedUsers,
                                                                  suggestedContacts)
                asyncCompletions.append(.init(text: "temp"))

                DispatchQueue.main.async { [weak self] in
                    self?.autocompleteManager.reloadData()
                }
            } catch {
                CustomSwiftMessages.displayError(error)
            }
        }
    }
    
    //Turns data into [AutocompleteCompletion] and does set union on it
    func turnResultsIntoAutocompletions(_ suggestedUsers: [FrontendReadOnlyUser],
                                        _ suggestedContacts: [CNContact]) -> [AutocompleteCompletion] {
        var suggestedUsersDict = Set<String>()
        var context = [String: Any]()

        var newAsyncCompletions: [AutocompleteCompletion] = suggestedUsers.map {
            let fullName = $0.first_name + " " + $0.last_name
            
            context = [AutocompleteContext.id.rawValue: $0.id,
                       AutocompleteContext.pic.rawValue: $0.profilePic]
            
            suggestedUsersDict.insert(fullName)
            return AutocompleteCompletion(text: fullName,
                                          context: context)
        }

        for contact in suggestedContacts {
            let fullName = contact.givenName + " " + contact.familyName

            if contact.imageDataAvailable, let data = contact.thumbnailImageData {
                context[AutocompleteContext.pic.rawValue] = UIImage(data: data)
            }
            
            guard let bestNumber = bestPhoneNumberFrom(contact.phoneNumbers) else { continue }
            context[AutocompleteContext.number.rawValue] = bestNumber
            
            if !suggestedUsersDict.contains(fullName) {
                newAsyncCompletions.append(AutocompleteCompletion(text: fullName,
                                                               context: context))
            }
        }
        
        return newAsyncCompletions
    }
    
}



//MARK: - Contacts

extension PostViewController {
    
    //MARK: - Permission
    
    func requestContactsAccessIfNecessary(closure: @escaping (_ authorized: Bool) -> Void) {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .notDetermined:
            CustomSwiftMessages.showPermissionRequest(permissionType: .contacts, onApprove: { [self] in
                contactStore.requestAccess(for: .contacts) { approved, _ in closure(approved) }
            })
        case .restricted:
            break
        case .denied:
            CustomSwiftMessages.showSettingsAlertController(title: "Turn on contact sharing for Mist in Settings.", message: "", on: self)
            closure(false)
        case .authorized:
            closure(true)
        @unknown default:
            break
        }
    }
    
    //MARK: - Fetch
    
    func fetchSuggestedContacts(partialString: String) -> [CNContact] {
        do {
            let predicate: NSPredicate = CNContact.predicateForContacts(matchingName: partialString)
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactThumbnailImageDataKey, CNContactImageDataAvailableKey] as [CNKeyDescriptor]
            let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            return contacts
        } catch {
            print("Failed to fetch contact, error: \(error)")
            return []
        }
    }
    
    //MARK: - Helpers
    
    func bestPhoneNumberFrom(_ phoneNumbers: [CNLabeledValue<CNPhoneNumber>]) -> String? {
        if phoneNumbers.count == 0 { return nil } //dont autoComplete contacts without numbers

        if phoneNumbers.count == 1 {
            return phoneNumbers[0].value.stringValue
        }
        
        //Otherwise, choose one number with one of the three most likely labels
        for cnNumber in phoneNumbers {
            if cnNumber.label == CNLabelPhoneNumberMain ||
                cnNumber.label == CNLabelPhoneNumberiPhone ||
                cnNumber.label == CNLabelPhoneNumberMobile {
                return cnNumber.value.stringValue
            }
        }
        
        return nil
    }
}
