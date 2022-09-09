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

extension PostViewController: AutocompleteManagerDelegate, AutocompleteManagerDataSource {
    
    // MARK: - AutocompleteManagerDataSource
    
    func autocompleteManager(_ manager: AutocompleteManager, autocompleteSourceFor prefix: String) -> [AutocompleteCompletion] {
        return prefix == "@" ? asyncCompletions : []
    }
    
    //Oh interesting
    //Even though i artifically set asyncCompletions to 5 default users, this function below doesnt run at all when the session text does not actually match any of those default users
    //Therefore, the "No results found" cell never gets displayed
    func autocompleteManager(_ manager: AutocompleteManager, tableView: UITableView, cellForRowAt indexPath: IndexPath, for session: AutocompleteSession) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TagAutocompleteCell.reuseIdentifier, for: indexPath) as? TagAutocompleteCell else {
            fatalError("Oops, some unknown error occurred")
        }

//        let completion = asyncCompletions[indexPath.row] //this is wrong
        guard let completion = session.completion else {
            fatalError("Oops, some unknown error occurred")
        }
        
        guard let context = completion.context else {
            fatalError("Trying to display an autocomplete cell without a context")
        }
        cell.textLabel?.text = context[AutocompleteContext.queryName.rawValue] as? String
        
        let isMistUser = context[AutocompleteContext.id.rawValue] != nil
        if isMistUser {
            cell.detailTextLabel?.text = "@" +  completion.text
            cell.imageView?.image = context[AutocompleteContext.pic.rawValue] as? UIImage
        } else {
            cell.isContact = true
            cell.detailTextLabel?.text = context[AutocompleteContext.numberPretty.rawValue] as? String
            if let contactPic = context[AutocompleteContext.pic.rawValue] as? UIImage {
                cell.imageView?.image = contactPic
            } else {
                cell.imageView?.image = TagAutocompleteCell.contactImage
            }
        }
        return cell
    }
    
    // MARK: - AutocompleteManagerDelegate
    
    func autocompleteManager(_ manager: AutocompleteManager, shouldBecomeVisible: Bool) {
        shouldBecomeVisible ? print("SHOULD BECOME VISIBLE") : print("SHOULD BECOME INVISIBLE")
        setAutocompleteManager(active: shouldBecomeVisible)
    }
    
    // Optional
    func autocompleteManager(_ manager: AutocompleteManager, shouldRegister prefix: String, at range: NSRange) -> Bool {
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
        mostRecentAutocompleteQuery = "" //prevent any finished load from appearing on autocorrect
        autocompleteManager.invalidate()
        return true
    }
            
    // MARK: - AutocompleteManagerDelegate Helper
    
    func setAutocompleteManager(active: Bool) {
        let topStackView = inputBar.topStackView
        if active && !topStackView.arrangedSubviews.contains(autocompleteManager.tableView) {
            topStackView.insertArrangedSubview(autocompleteManager.tableView, at: topStackView.arrangedSubviews.count)
            UIView.performWithoutAnimation { //prevent the placeholderText from disappearing to the bottom left corner
                topStackView.setNeedsLayout()
                topStackView.layoutIfNeeded()
            }
        } else if !active && topStackView.arrangedSubviews.contains(autocompleteManager.tableView) {
            topStackView.removeArrangedSubview(autocompleteManager.tableView)
            UIView.performWithoutAnimation { //prevent the placeholderText from disappearing to the bottom left corner
                topStackView.setNeedsLayout()
                topStackView.layoutIfNeeded()
            }
            asyncCompletions = []
        }
        inputBar.invalidateIntrinsicContentSize() //i don't think this is necessary, but we'll leave it
    }
    
    //MARK: - Helpers
    
    func processAutocompleteOnNextText(_ updatedText: String) {
    
        //updatedText doesn't include starting/ending whitespace, while fullInputText does
        guard let fullInputText = inputBar.inputTextView.text else { return }
        
        guard let session = autocompleteManager.currentSession, session.prefix == "@" else {
            //should i not validate here? The original code didnt include this
            autocompleteManager.invalidate()
            return
        }
        
        let fixedRange = NSRange(location: session.range.lowerBound, length: session.range.upperBound) //for some reason. upperBound is actually the length of the session's range? bc of that, we fix the range
        
        if fixedRange.upperBound > fullInputText.count {
            autocompleteManager.invalidate()
            return
        } //TODO: Fix this hack later. for some reason, without this line of code, the session.range does not get updated properly and is out of bounds.
//
        let currentSessionText = fullInputText.substring(with: fixedRange.lowerBound..<fixedRange.upperBound)
        mostRecentAutocompleteQuery = currentSessionText.substring(from: 1) //strip the "@"

        let containsNewlinesOrSpaces = mostRecentAutocompleteQuery.rangeOfCharacter(from: .whitespacesAndNewlines) != nil
        guard !containsNewlinesOrSpaces else {
            autocompleteManager.invalidate()
            return
        }
//        let allowedCharacters = CharacterSet.alphanumerics
//        allowedCharacters.insert(charactersIn: "&$#")
        //TODO: like above, ensure the text does not contain other weird characters...
        
        //If not the very first character, ensure the "@" is preceded by a whitespace
        if fixedRange.lowerBound > 0 {
            guard fullInputText.substring(with: fixedRange.lowerBound-1 ..< fixedRange.lowerBound).rangeOfCharacter(from: .whitespacesAndNewlines) != nil else {
                autocompleteManager.invalidate()
                return
            }
        }

        if !DeviceService.shared.hasBeenRequestedContactsBeforeTagging() {
            DeviceService.shared.requestContactsBeforeTagging()
            requestContactsAccess { [self] wasShownPermissionRequest in
                DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [weak self] in
                    guard let self = self else { return }
                    self.tableView.layoutIfNeeded()
                    self.scrollToBottom()
                    self.loadAutocompleteData(query: self.mostRecentAutocompleteQuery)
                })
            }
        } else {
            loadAutocompleteData(query: mostRecentAutocompleteQuery)
        }
    }
    
    func loadAutocompleteData(query: String) {
        //Check if beginning of tag
        if query.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.autocompleteManager.placeholderLabel.text = "Tag your contacts or friends"
                self?.asyncCompletions = []
                self?.autocompleteManager.reloadData()
                self?.autocompleteManager.tableView.flashScrollIndicators()
                self?.autocompleteManager.activityIndicator.stopAnimating()
            }
            return
        }
        
        //Check if the search was already cached
        if let cachedAutocompletions = autocompletionCache[query] {
            DispatchQueue.main.async { [weak self] in
                self?.asyncCompletions = cachedAutocompletions
                self?.autocompleteManager.reloadData()
                self?.autocompleteManager.tableView.flashScrollIndicators()
                self?.autocompleteManager.activityIndicator.stopAnimating()
            }
            return
        }
        
        //Check if search is in progress
        if let inProgressTask = autocompletionTasks[query] {
            if !inProgressTask.isCancelled {
                //the autocompletion is currently loading: wait for it to finish
                autocompleteManager.activityIndicator.startAnimating()
                return
            }
        }
    
        autocompletionTasks[query] = Task {
            autocompleteManager.activityIndicator.startAnimating()
            do {
                var suggestedContacts = [CNContact]()
                if CNContactStore.authorizationStatus(for: .contacts) == .authorized  {
                    suggestedContacts = fetchSuggestedContacts(partialString: query)
                    suggestedContacts = Array(suggestedContacts.prefix(20))
                }
                
                var usersInContacts = [ReadOnlyUser]()
                var contactsWithoutAnAccount = [CNContact]()
                for contact in suggestedContacts {
                    guard let number = contact.bestPhoneNumberE164 else { continue }
                    if let user = await UsersService.singleton.getUserAssociatedWithContact(phoneNumber: number) {
                        usersInContacts.append(user)
                    } else {
                        contactsWithoutAnAccount.append(contact)
                    }
                }
                
                let fetchedUsers = try await UserAPI.fetchUsersByWords(words: [query])
                let nonduplicatedUsers = Set(fetchedUsers).union(usersInContacts)
                let trimmedUsers = Array(nonduplicatedUsers.prefix(10))
                let frontendSuggestedUsers = try await Array(UsersService.singleton.loadAndCacheUsers(users: trimmedUsers).values)
                
                let newResults = turnResultsIntoAutocompletions(frontendSuggestedUsers, contactsWithoutAnAccount)
                autocompletionCache[query] = newResults
                
                if query == mostRecentAutocompleteQuery {
                    DispatchQueue.main.async { [weak self] in
                        if newResults.isEmpty {
                            self?.autocompleteManager.placeholderLabel.text = "No results found"
                        }
                        self?.asyncCompletions = newResults
                        self?.autocompleteManager.reloadData()
                        self?.autocompleteManager.tableView.flashScrollIndicators()
                        self?.autocompleteManager.activityIndicator.stopAnimating()
                    }
                }
            } catch {
                autocompletionTasks[query]?.cancel()
                autocompleteManager.activityIndicator.stopAnimating()
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
            context = [:]
            let fullName = $0.first_name + " " + $0.last_name
            
            context = [AutocompleteContext.id.rawValue: $0.id,
                       AutocompleteContext.pic.rawValue: $0.profilePic,
                       AutocompleteContext.queryName.rawValue: fullName]
            
            suggestedUsersDict.insert(fullName)
            return AutocompleteCompletion(text: $0.username,
                                          context: context)
        }

        for contact in suggestedContacts {
            context = [:]
            let fullName = contact.givenName + " " + contact.familyName
            guard !contact.givenName.isEmpty || !contact.familyName.isEmpty else { continue }

            if contact.imageDataAvailable, let data = contact.thumbnailImageData {
                context[AutocompleteContext.pic.rawValue] = UIImage(data: data)
            }
            
            guard let bestNumberPretty = contact.bestPhoneNumberPretty else { continue }
            guard let bestNumberE164 = contact.bestPhoneNumberE164 else { continue }
            context[AutocompleteContext.numberPretty.rawValue] = bestNumberPretty
            context[AutocompleteContext.numberE164.rawValue] = bestNumberE164
            context[AutocompleteContext.queryName.rawValue] = fullName
            
            //Turning off this check for now
//            if !suggestedUsersDict.contains(fullName) {
                newAsyncCompletions.append(AutocompleteCompletion(text: contact.generatedUsername,
                                                               context: context))
//            }
        }
        
        //Sort alphabetically
        return newAsyncCompletions.sorted(by: { $0.text.lowercased() < $1.text.lowercased() })

    }
    
}

extension PostViewController {
    
    //MARK: - Permission
    
    //not in use
    func areContactsAuthorized() -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .notDetermined:
            return false
        case .restricted:
            return false
        case .denied:
            return false
        case .authorized:
            return true
        @unknown default:
            return false
        }
    }
    
    //bool: wasShownPermissionsRequest
    func requestContactsAccess(closure: @escaping (_ wasShownPermissionRequest: Bool) -> Void) {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .notDetermined, .denied:
            CustomSwiftMessages.showPermissionRequest(permissionType: .contacts) { approved in
                if approved {
                    if status == .denied {
                        CustomSwiftMessages.showSettingsAlertController(title: "share your contacts with mist in settings", message: "", on: self)
                        closure(false)
                    }
                    self.contactStore.requestAccess(for: .contacts) { approved, _ in
                        if approved {
                            Task {
                                await UsersService.singleton.loadUsersAssociatedWithContacts()
                                closure(true)
                            }
                        }
                    }
                } else {
                    closure(true)
                }
            }
        case .restricted, .authorized:
            closure(false)
        @unknown default:
            closure(false)
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
    
    //No longer needed because of the fetchUsersByNumbers api kevin made
    //Returns an array of completions from either the user corresponding to the contact's phone number, if one exists, or the contact
//    func checkIfContactsHaveExistingAccount(_ contacts: [CNContact]) async throws -> [AutocompleteCompletion] {
//        var autocompletions = [AutocompleteCompletion]()
//        try await withThrowingTaskGroup(of: AutocompleteCompletion?.self) { group in
//            for contact in contacts {
//                group.addTask { [weak self] in
//                    guard let bestNumber = await self?.bestPhoneNumberFrom(contact.phoneNumbers) else { return nil } //would be more ideal to check every phone number, not just the "best" one
//                    let usersWithThatNumber = try await UserAPI.fetchUsersByWords(words: [bestNumber]) //TODO: CHANGE THIS TO BY PHONE NUMBER
//                    if let user = usersWithThatNumber.first {
//                        let frontendUser = try await UsersService.singleton.loadAndCacheUser(user: user)
//                        let context: [String: Any] = [AutocompleteContext.id.rawValue: frontendUser.id,
//                                   AutocompleteContext.pic.rawValue: frontendUser.profilePic,
//                                   AutocompleteContext.queryName.rawValue: frontendUser.full_name]
//                        return AutocompleteCompletion(text: frontendUser.username,
//                                                      context: context)
//                    }
//                    let fullName = contact.givenName + " " + contact.familyName
//                    guard !contact.givenName.isEmpty || !contact.familyName.isEmpty else { return nil }
//                    let context = [AutocompleteContext.number.rawValue: bestNumber,
//                                   AutocompleteContext.queryName.rawValue: fullName]
//                    return AutocompleteCompletion(text: contact.generatedUsername, context: context)
//                }
//            }
//            for try await autocompletion in group {
//                if let autocompletion = autocompletion {
//                    autocompletions.append(autocompletion)
//                }
//            }
//        }
//        return autocompletions
//    }

}

//old process autocomplete text:

//        guard fullInputText
//
//        guard fixedRange.upperBound <= updatedText.count else {
//            print("2")
//            autocompleteManager.invalidate()
//            return
//        }
//        guard let selectedRange = inputBar.inputTextView.selectedTextRange else { return }
//        let cursorPosition = inputBar.inputTextView.offset(from: inputBar.inputTextView.beginningOfDocument, to: selectedRange.start)
//        print(fixedRange.upperBound, cursorPosition)
//        guard fixedRange.upperBound <= cursorPosition else {
//            print("2")
//            autocompleteManager.invalidate()
//            return
//        }

