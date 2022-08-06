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
    case id, number, pic, username, name
}

class CommentAutocompleteManager: AutocompleteManager {
    
    let topLineView = UIView()
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    override init(for textView: UITextView) {
        super.init(for: textView)
        topLineView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 0.5)
        topLineView.backgroundColor = .systemGray2
        tableView.addSubview(topLineView)
        
        tableView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTableViewSubviews()
    }
    
    func updateTableViewSubviews() {
        let pixelsFromTop = CGFloat(0)
        let theHeight = tableView.contentOffset.y //+ self.tableView.frame.height
        topLineView.frame = CGRect(x: 0, y: theHeight + pixelsFromTop , width: tableView.frame.width, height: topLineView.frame.height)
        
        activityIndicator.frame.origin.x = tableView.frame.width - 35
        if tableView.frame.height == 0 {
            activityIndicator.frame.origin.y = tableView.contentOffset.y - 30
            tableView.clipsToBounds = false //so animator can appear above tableview
        } else {
            activityIndicator.frame.origin.y = tableView.contentOffset.y + 13
            tableView.clipsToBounds = true //restore to normal
        }
    }
}

class TagAutocompleteCell: AutocompleteCell {
    
    static let contactImage = UIImage(systemName: "phone")!
    
    override func setupSubviews() {
        super.setupSubviews()
        tagAutocompleteSetup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        tagAutocompleteSetup()
    }
    
    func tagAutocompleteSetup() {
        separatorLine.isHidden = true
        textLabel?.font = UIFont(name: Constants.Font.Medium, size: 15)
        detailTextLabel?.font = UIFont(name: Constants.Font.Medium, size: 12)
        detailTextLabel?.textColor = .gray
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        fixImageAndLabelLayout()
    }
    
    // i can't figure out how to use these insets properly... there's too much customization provided by default by the autocomplete cell. i just override it below
    // imageViewEdgeInsets = .init(top: 5, left: -10, bottom: 0, right: 0)
    func fixImageAndLabelLayout() {
        if let imageView = imageView, let image = imageView.image {
            textLabel?.font = UIFont(name: Constants.Font.Heavy, size: 15)
            textLabel?.frame.origin.y += 4
            detailTextLabel?.frame.origin.y -= 1
            
            if image != TagAutocompleteCell.contactImage {
                imageView.frame.origin.x -= 8
                imageView.frame.origin.y += 7
                
                let initialImageViewWidth = imageView.frame.size.width
                imageView.contentMode = .scaleAspectFill
                imageView.frame.size = .init(width: 38, height: 38)
                imageView.layer.cornerRadius = imageView.frame.size.height / 2
                imageView.layer.cornerCurve = .continuous
                imageView.clipsToBounds = true
                
                let widthToShiftOver = initialImageViewWidth - 40
                textLabel?.frame.origin.x -= widthToShiftOver + 15
                detailTextLabel?.frame.origin.x -= widthToShiftOver + 15
            } else {
                imageView.layer.cornerRadius = 0
            }
        }
    }
    
}

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
        
        cell.textLabel?.text = completion.text
        //cell.textLabel?.attributedText = manager.attributedText(matching: session, fontSize: 16, keepPrefix: true) //We're choosing not to bold the matching text
        
        guard let context = completion.context else {
            print("RENDERING CELL W NO COMPLETION CONTEXT")
            return cell
        }
        
        let isMistUser = context[AutocompleteContext.username.rawValue] != nil
        if isMistUser {
            cell.detailTextLabel?.text = "@" +  (context[AutocompleteContext.username.rawValue] as! String)
            cell.imageView?.image = context[AutocompleteContext.pic.rawValue] as? UIImage
        } else {
            cell.detailTextLabel?.text = "From contacts"
            cell.imageView?.image = TagAutocompleteCell.contactImage
        }
        return cell
    }
    
    // MARK: - AutocompleteManagerDelegate
    
    func autocompleteManager(_ manager: AutocompleteManager, shouldBecomeVisible: Bool) {
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
    
    func processAutocomplete(_ updatedText: String) {
        //updatedText doesn't include starting/ending whitespace, while fullInputText does
        guard let fullInputText = inputBar.inputTextView.text else { return }
        
        guard let session = autocompleteManager.currentSession, session.prefix == "@" else {
            //should i not validate here? The original code didnt include this
            autocompleteManager.invalidate()
            return
        }
        
        let fixedRange = NSRange(location: session.range.lowerBound, length: session.range.upperBound) //for some reason. upperBound is actually the length of the session's range? bc of that, we fix the range
        
        let currentSessionText = fullInputText.substring(with: fixedRange.lowerBound..<fixedRange.upperBound)
        let containsWhitespace = currentSessionText.rangeOfCharacter(from: .whitespacesAndNewlines) != nil
        guard !containsWhitespace else {
            autocompleteManager.invalidate()
            return
        }

        let sessionWord = currentSessionText.substring(from: 1) //skip the "@"
        loadAutocompleteData(firstWord: sessionWord, secondWord: nil)
    }
    
    func loadAutocompleteData(firstWord: String, secondWord: String?) {
        if firstWord.isEmpty && secondWord == nil {
            asyncCompletions = [(.init(text: "Tag your contacts or friends"))]
            DispatchQueue.main.async { [weak self] in
                self?.autocompleteManager.reloadData()
                self?.autocompleteManager.tableView.flashScrollIndicators()
            }
            return
        }
        
        //note: we should probably cache these previousTasks
        let previousTask = autocompleteTask
        previousTask?.cancel()
        autocompleteManager.tableView.showLoading()
        autocompleteTask = Task {
            autocompleteManager.activityIndicator.startAnimating()
            do {
                var suggestedContacts = [CNContact]()
                if CNContactStore.authorizationStatus(for: .contacts) == .authorized  {
                    suggestedContacts = fetchSuggestedContacts(partialString: firstWord)
                } else if !hasPromptedUserForContactsAccess {
                    requestContactsAccessIfNecessary { authorized in }
                }
                
                let suggestedUsers = try await UserAPI.fetchUsersByText(containing: firstWord)
                let trimmedUsers = Array(suggestedUsers.prefix(10))
                let frontendSuggestedUsers = try await Array(UserAPI.batchTurnUsersIntoFrontendUsers(trimmedUsers).values)
                
                asyncCompletions = turnResultsIntoAutocompletions(frontendSuggestedUsers, suggestedContacts)

                print("ALL COMPLETIONS:", asyncCompletions.count)
                if asyncCompletions.count == 0 {
                    asyncCompletions = [.init(text: "No results found")]
                }

                DispatchQueue.main.async { [weak self] in
                    self?.autocompleteManager.reloadData()
                    self?.autocompleteManager.tableView.flashScrollIndicators()
                }
            } catch {
                if let previousTask = previousTask, !previousTask.isCancelled {
                    CustomSwiftMessages.displayError(error)
                }
            }
            autocompleteManager.activityIndicator.stopAnimating()
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
                       AutocompleteContext.username.rawValue: $0.username,
                       AutocompleteContext.name.rawValue: fullName]
            
            suggestedUsersDict.insert(fullName)
            return AutocompleteCompletion(text: fullName,
                                          context: context)
        }

        for contact in suggestedContacts {
            context = [:]
            let fullName = contact.givenName + " " + contact.familyName

            if contact.imageDataAvailable, let data = contact.thumbnailImageData {
                context[AutocompleteContext.pic.rawValue] = UIImage(data: data)
            }
            
            guard let bestNumber = bestPhoneNumberFrom(contact.phoneNumbers) else { continue }
            context[AutocompleteContext.number.rawValue] = bestNumber
            context[AutocompleteContext.name.rawValue] = fullName
            
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
        hasPromptedUserForContactsAccess = true
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
