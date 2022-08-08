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
            cell.selectionStyle = .none
            cell.textLabel?.text = completion.text
            return cell
        }
        cell.textLabel?.text = context[AutocompleteContext.queryName.rawValue] as? String
        
        let isMistUser = context[AutocompleteContext.id.rawValue] != nil
        if isMistUser {
            cell.detailTextLabel?.text = "@" +  completion.text
            cell.imageView?.image = context[AutocompleteContext.pic.rawValue] as? UIImage
        } else {
            cell.isContact = true
            cell.detailTextLabel?.text = context[AutocompleteContext.number.rawValue] as? String
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
        autocompleteManager.updateTableViewSubviews()
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
        mostRecentAutocompleteQuery = .init(first: "", second: "") //prevent any finished load from appearing on autocorrect
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
            asyncCompletions = []
        }
        inputBar.invalidateIntrinsicContentSize()
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
        
        if fixedRange.upperBound > fullInputText.count { return } //TODO: Fix this hack later. for some reason, without this line of code, the session.range does not get updated properly and is out of bounds
        
        let currentSessionText = fullInputText.substring(with: fixedRange.lowerBound..<fixedRange.upperBound)
        
        let containsNewlines = currentSessionText.rangeOfCharacter(from: .newlines) != nil
        guard !containsNewlines else {
            autocompleteManager.invalidate()
            return
        }
        
//        let allowedCharacters = CharacterSet.alphanumerics
//        allowedCharacters.insert(charactersIn: "&$#")
        //TODO: like above, ensure the text does not contain other weird characters...
        
        let containsAtMostTwoWords = currentSessionText.components(separatedBy: .whitespaces).count <= 2
        guard containsAtMostTwoWords else {
            autocompleteManager.invalidate()
            return
        }
        
        //If not the very first character, ensure the "@" is preceded by a whitespace
        if fixedRange.lowerBound > 0 {
            guard fullInputText.substring(with: fixedRange.lowerBound-1 ..< fixedRange.lowerBound).rangeOfCharacter(from: .whitespacesAndNewlines) != nil else {
                autocompleteManager.invalidate()
                return
            }
        }

        let sessionWords = currentSessionText.substring(from: 1).components(separatedBy: .whitespaces) //skip the "@"
        guard let first = sessionWords.first, let last = sessionWords.last else { return }
        loadAutocompleteData(firstWord: first, secondWord: first == last ? "" : last)
    }
    
    func loadAutocompleteData(firstWord: String, secondWord: String) {
        mostRecentAutocompleteQuery = AutocompleteQuery(first: firstWord, second: secondWord)
        let currentQuery = mostRecentAutocompleteQuery
                
        if !hasPromptedUserForContactsAccess && !areContactsAuthorized() {
           requestContactsAccessIfNecessary { _ in
               self.loadAutocompleteData(firstWord: firstWord, secondWord: secondWord)
           }
           return
       }
        
        //Check if beginning of tag
        if currentQuery.first.isEmpty && currentQuery.second.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.asyncCompletions = [(.init(text: "Tag your contacts or friends"))]
                self?.autocompleteManager.reloadData()
                self?.autocompleteManager.tableView.flashScrollIndicators()
                self?.autocompleteManager.activityIndicator.stopAnimating()
            }
            return
        }
        
        //Check if the search was already cached
        if let cachedAutocompletions = autocompletionCache[currentQuery] {
            DispatchQueue.main.async { [weak self] in
                self?.asyncCompletions = cachedAutocompletions
                self?.autocompleteManager.reloadData()
                self?.autocompleteManager.tableView.flashScrollIndicators()
                self?.autocompleteManager.activityIndicator.stopAnimating()
            }
            return
        }
        
        //Check if search is in progress
        if let inProgressTask = autocompletionTasks[currentQuery] {
            if !inProgressTask.isCancelled {
                //the autocompletion is currently loading: wait for it to finish
                autocompleteManager.activityIndicator.startAnimating()
                return
            }
        }
    
        autocompletionTasks[currentQuery] = Task {
            autocompleteManager.activityIndicator.startAnimating()
            do {
                var suggestedContacts = [CNContact]()
                if CNContactStore.authorizationStatus(for: .contacts) == .authorized  {
                    suggestedContacts = fetchSuggestedContacts(partialString: currentQuery.first + " " + currentQuery.second)
                    suggestedContacts = Array(suggestedContacts.prefix(20))
                }
                
                let suggestedUsers = try await UserAPI.fetchUsersByWords(words: [currentQuery.first, currentQuery.second])
                let trimmedUsers = Array(suggestedUsers.prefix(15))
                let frontendSuggestedUsers = try await Array(UserAPI.batchTurnUsersIntoFrontendUsers(trimmedUsers).values)
                
                let newResults = turnResultsIntoAutocompletions(frontendSuggestedUsers, suggestedContacts)
                autocompletionCache[currentQuery] = newResults
                
                if currentQuery == mostRecentAutocompleteQuery {
                    DispatchQueue.main.async { [weak self] in
                        self?.asyncCompletions = newResults
                        self?.autocompleteManager.reloadData()
                        self?.autocompleteManager.tableView.flashScrollIndicators()
                        self?.autocompleteManager.activityIndicator.stopAnimating()
                    }
                }
            } catch {
                autocompletionTasks[currentQuery]?.cancel()
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
            
            guard let bestNumber = bestPhoneNumberFrom(contact.phoneNumbers) else { continue }
            context[AutocompleteContext.number.rawValue] = bestNumber
            context[AutocompleteContext.queryName.rawValue] = fullName
            
            if !suggestedUsersDict.contains(fullName) {
                newAsyncCompletions.append(AutocompleteCompletion(text: contact.generatedUsername,
                                                               context: context))
            }
        }
        
        if newAsyncCompletions.count == 0 {
            return [.init(text: "No results found")]
        }
        
        //Sort alphabetically
        return newAsyncCompletions.sorted(by: { $0.text.lowercased() < $1.text.lowercased() })

    }
    
}


//MARK: - Contacts

extension CNContact {
    var generatedUsername: String {
        return (givenName + familyName + randomStringOfNumbers(length: 3)).lowercased()
    }
}

extension String {
    func formatAsDjangoPhoneNumber() -> String {
        let filtered = self.filter("+0123456789".contains)
        return filtered.first(where: { $0 == "+"}) == nil ? "+1" + filtered : filtered
    }
}

extension PostViewController {
    
    //MARK: - Permission
    
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
    
    func requestContactsAccessIfNecessary(closure: @escaping (_ authorized: Bool) -> Void) {
        hasPromptedUserForContactsAccess = true
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .notDetermined:
            CustomSwiftMessages.showPermissionRequest(permissionType: .contacts, onApprove: { [self] in
                contactStore.requestAccess(for: .contacts) { approved, _ in
                    closure(approved)
                }
            })
        case .restricted:
            closure(false)
        case .denied:
            CustomSwiftMessages.showSettingsAlertController(title: "Turn on contact sharing for Mist in Settings.", message: "", on: self)
            closure(false)
        case .authorized:
            closure(true)
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
    
    //Returns an array of completions from either the user corresponding to the contact's phone number, if one exists, or the contact
    func checkIfContactsHaveExistingAccount(_ contacts: [CNContact]) async throws -> [AutocompleteCompletion] {
        var autocompletions = [AutocompleteCompletion]()
        try await withThrowingTaskGroup(of: AutocompleteCompletion?.self) { group in
            for contact in contacts {
                group.addTask { [weak self] in
                    guard let bestNumber = await self?.bestPhoneNumberFrom(contact.phoneNumbers) else { return nil } //would be more ideal to check every phone number, not just the "best" one
                    let usersWithThatNumber = try await UserAPI.fetchUsersByWords(words: [bestNumber]) //TODO: CHANGE THIS TO BY PHONE NUMBER
                    if let user = usersWithThatNumber.first {
                        let frontendUser = try await UserAPI.turnUserIntoFrontendUser(user)
                        let context: [String: Any] = [AutocompleteContext.id.rawValue: frontendUser.id,
                                   AutocompleteContext.pic.rawValue: frontendUser.profilePic,
                                   AutocompleteContext.queryName.rawValue: frontendUser.full_name]
                        return AutocompleteCompletion(text: frontendUser.username,
                                                      context: context)
                    }
                    let fullName = contact.givenName + " " + contact.familyName
                    guard !contact.givenName.isEmpty || !contact.familyName.isEmpty else { return nil }
                    let context = [AutocompleteContext.number.rawValue: bestNumber,
                                   AutocompleteContext.queryName.rawValue: fullName]
                    return AutocompleteCompletion(text: contact.generatedUsername, context: context)
                }
            }
            for try await autocompletion in group {
                if let autocompletion = autocompletion {
                    autocompletions.append(autocompletion)
                }
            }
        }
        return autocompletions
    }
    
    //MARK: - Helpers
    
    func bestPhoneNumberFrom(_ phoneNumbers: [CNLabeledValue<CNPhoneNumber>]) -> String? {
        var best: String?
        
        if phoneNumbers.count == 0 { return nil } //dont autoComplete contacts without numbers
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
        //DJANGO CHECK: PHONE IS AT LEAST 10 AND NO LESS THAN 16 (15 digits and one +)
        guard let formattedBest = best?.formatAsDjangoPhoneNumber() else { return nil }
        let isProperlyFormatted = formattedBest.count >= 10 && formattedBest.count <= 16
        return isProperlyFormatted ? best : nil
    }
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
