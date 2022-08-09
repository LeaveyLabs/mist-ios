//
//  PostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit
import Contacts
import InputBarAccessoryView //dependency of MessageKit. If we remove MessageKit, we should install this package independently

let COMMENT_PLACEHOLDER_TEXT = "Comment & tag friends"
typealias UpdatedPostCompletionHandler = ((Post) -> Void)
var hasPromptedUserForContactsAccess = false


extension AutocompleteManagerDelegate {
    func autocompleteDidScroll() {
        fatalError("Override this within the class")
    }
}

class TopWindow: UIWindow {

    override var windowLevel: UIWindow.Level {
        get  { UIWindow.Level(rawValue: 20000000.000) }
        set { self.windowLevel = newValue }
    }
}

class PostViewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    //MARK: - Properties
    
    //TableView
    var activityIndicator = UIActivityIndicatorView(style: .medium)
    @IBOutlet var tableView: UITableView!
    
    //CommentInput
    let keyboardManager = KeyboardManager() //InputBarAccessoryView
    let inputBar = InputBarAccessoryView()
    let MAX_COMMENT_LENGTH = 499
        
    //Keyboard
    var shouldStartWithRaisedKeyboard: Bool!
    var keyboardHeight: Double = 0
    
    //Autocomplete
    let contactStore = CNContactStore()
    var asyncCompletions: [AutocompleteCompletion] = []
    var autocompleteTask: Task<Void, Never>?

    open lazy var autocompleteManager: CommentAutocompleteManager = { [unowned self] in
        let manager = CommentAutocompleteManager(for: self.inputBar.inputTextView)
        inputBar.inputTextView.delegate = self //re-claim delegate status after AutocompleteManager became it
        manager.delegate = self
        manager.dataSource = self
        manager.filterBlock = { session, completion in
            if let id = completion.context?[AutocompleteContext.id.rawValue] as? Int, id == UserService.singleton.getId() {
                return false //dont display yourself in the suggestions
            }
            return true
        }
        return manager
    }()
    var mostRecentAutocompleteQuery = ""
    var autocompletionCache = [String: [AutocompleteCompletion]]()
    var autocompletionTasks = [String: Task<Void, Never>]()
    
    //Data
    var post: Post!
    var comments = [Comment]()
    var commentAuthors = [Int: FrontendReadOnlyUser]() //[authorId: author]
    
    //PostDelegate
    var loadAuthorProfilePicTasks: [Int: Task<FrontendReadOnlyUser?, Never>] = [:]
    var loadTaggedProfileTasks: [Int : Task<FrontendReadOnlyUser?, Error>] = [:] //Error, not Never, because we're doing 2 layers of DoTry calls

    //Abandoned
//    var prepareForDismiss: UpdatedPostCompletionHandler? //no longer needed

    //MARK: - Initialization
    
    class func createPostVC(with post: Post, shouldStartWithRaisedKeyboard: Bool, completionHandler: UpdatedPostCompletionHandler?) -> PostViewController {
        let postVC =
        UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Post) as! PostViewController
        postVC.post = post
        postVC.shouldStartWithRaisedKeyboard = shouldStartWithRaisedKeyboard
//        postVC.prepareForDismiss = completionHandler no longer used
        return postVC
    }
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupCommentInputBar()
        setupKeyboardManagerForBottomInputBar()
        loadComments()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //no longer using the postVC's willDismiss completion handler here: we could delete that
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disableInteractivePopGesture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Im guessing there's a considerable number of people who will click "comment" to see comments but don't want the keyboard to pull up
        if shouldStartWithRaisedKeyboard {
            // For that reason, we wont raise keyboard, for now
          self.inputBar.inputTextView.becomeFirstResponder()
        }
        enableInteractivePopGesture()
    }
    
    //MARK: - Setup
    
    func setupTableView() {
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.sectionFooterHeight = 50

        tableView.register(PostCell.self, forCellReuseIdentifier: Constants.SBID.Cell.Post)
        let commentNib = UINib(nibName: Constants.SBID.Cell.Comment, bundle: nil)
        tableView.register(commentNib, forCellReuseIdentifier: Constants.SBID.Cell.Comment)
        
        let tableViewTap = UITapGestureRecognizer.init(target: self, action: #selector(dismissAllKeyboards))
        tableView.addGestureRecognizer(tableViewTap)
    }
    
    func setupCommentInputBar() {
        inputBar.delegate = self
        inputBar.inputTextView.delegate = self
        inputBar.shouldAnimateTextDidChangeLayout = true
        inputBar.maxTextViewHeight = 110 //max of 3 lines with the given font
        inputBar.inputTextView.keyboardType = .twitter
        inputBar.inputTextView.placeholder = COMMENT_PLACEHOLDER_TEXT
        inputBar.inputTextView.font = UIFont(name: Constants.Font.Medium, size: 16) //from 17
        inputBar.inputTextView.placeholderLabel.font = UIFont(name: Constants.Font.Medium, size: 16) //from 17
        inputBar.inputTextView.placeholderTextColor = .systemGray
//        inputBar.backgroundView.backgroundColor = UIColor(hex: "F8F8F8")
//        inputBar.shouldForceTextViewMaxHeight
        inputBar.separatorLine.height = 0.5
        
        //Middle
        inputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 45)
        inputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 45)
        inputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        inputBar.inputTextView.layer.borderColor = UIColor.systemGray2.cgColor
        inputBar.inputTextView.tintColor = mistUIColor()
        inputBar.inputTextView.backgroundColor = .systemGray6
        inputBar.inputTextView.layer.borderWidth = 0.5
        inputBar.inputTextView.layer.cornerRadius = 16.0
        inputBar.inputTextView.layer.masksToBounds = true
        inputBar.middleContentViewPadding.right = -45 //extends the inputbar to the right
        
        //Right
        inputBar.sendButton.title = "Post"
        inputBar.sendButton.setTitleColor(.clear, for: .disabled)
        inputBar.sendButton.setTitleColor(mistUIColor(), for: .normal)
        inputBar.sendButton.setSize(CGSize(width: 45, height: 40), animated: false) //to increase height
        inputBar.setRightStackViewWidthConstant(to: 45, animated: false)
        inputBar.setStackViewItems([inputBar.sendButton, InputBarButtonItem.fixedSpace(10)], forStack: .right, animated: false)

        //Left
        let inputAvatar = InputAvatar(frame: CGRect(x: 0, y: 0, width: 40, height: 40), profilePic: UserService.singleton.getProfilePic())
        inputBar.setLeftStackViewWidthConstant(to: 48, animated: false)
        inputBar.setStackViewItems([inputAvatar, InputBarButtonItem.fixedSpace(8)], forStack: .left, animated: false)
    }
    
    func setupKeyboardManagerForBottomInputBar() {
        view.addSubview(inputBar)
        keyboardManager.shouldApplyAdditionBottomSpaceToInteractiveDismissal = true
        keyboardManager.bind(inputAccessoryView: inputBar)
        keyboardManager.bind(to: tableView) // Binding to the tableView will enabled interactive dismissal
        keyboardManager.on(event: .didHide) { [weak self] keyboardNotification in
            self?.setAutocompleteManager(active: false)
            self?.tableView.contentInset.bottom = 0 //EXPERIMENTAL: Not sure if this 100% works
        }
        keyboardManager.on(event: .didShow) { [self] keyboardNotification in
            keyboardHeight = keyboardNotification.endFrame.height
            updateMaxAutocompleteRows(keyboardHeight: keyboardHeight)
        }
    
        //As is, this is causing a bad animation with the autocomplete results
        //Ideal: on .didShow, *if the comment keyboard was previously dismissed*, and *if there is an active autocomplete session*, setAutoManager to true
//        keyboardManager.on(event: .didShow) { [weak self] keyboardNotification in
//            self?.setAutocompleteManager(active: true)
//        }
    }
    
}

extension PostViewController: InputBarAccessoryViewDelegate {
    
    // MARK: - InputBarAccessoryViewDelegate
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let commentAutocompletions = extractAutocompletionsFromInputBarText()
        requestPermissionToTextIfNecessary(autocompletions: commentAutocompletions) { [self] authorizedTags in
            guard !authorizedTags.isEmpty else { return }
            Task {
                do {
                    let trimmedCommentText = inputBar.inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    inputBar.inputTextView.text = String() //now we can reset the input bar text
                    inputBar.invalidatePlugins()
                    inputBar.sendButton.isEnabled = false
                    let newComment = try await CommentService.singleton.uploadComment(text: trimmedCommentText, postId: post.id, tags: authorizedTags)
                    print(newComment)
                    handleSuccessfulCommentSubmission(newComment: newComment)
                } catch {
                    inputBar.sendButton.isEnabled = true
                    CustomSwiftMessages.displayError(error)
                }
            }
        }
    }
    
    func extractAutocompletionsFromInputBarText() -> [String: AnyObject] {
        // Here we can parse for which substrings were autocompleted
        let attributedText = inputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        var commentAutocompletions = [String: AnyObject]()
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (attributes, range, stop) in
            let substring = attributedText.attributedSubstring(from: range)
            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
            commentAutocompletions[substring.string] = context as AnyObject?
        }
        return commentAutocompletions
    }
    
    func requestPermissionToTextIfNecessary(autocompletions commentAutocompletions: [String: AnyObject], closure: @escaping (_ authorizedTags: [Tag]) -> Void) {
        let candidateTags = turnCommentAutocompletionsIntoTags(commentAutocompletions)
        let candidateTagsFromUsers = candidateTags.filter({ $0.tagged_user != nil })
        let candidateTagsFromContacts = candidateTags.filter({ $0.tagged_phone_number != nil })
        
        if candidateTagsFromContacts.count == 0 {
            closure(candidateTags)
            return
        }
        
        let firstNamesToText: [String] = commentAutocompletions.compactMap { name, context in
            return (context[AutocompleteContext.queryName.rawValue] as? String)?.components(separatedBy: .whitespaces).first
        }
        var namesAsString: String = ""
        firstNamesToText.forEach( { namesAsString.append($0 + " ") })
        
        let alertTitle: String = namesAsString + (firstNamesToText.count == 1 ? "isn't on Mist yet!" : "aren't on Mist yet!")
        let alert = UIAlertController(title: alertTitle,
                                      message: "We'll send a text to let them know you mentioned them.",
                                      preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel",
                                      style: UIAlertAction.Style.default, handler: { alertAction in
            closure(candidateTagsFromUsers)
        }))
        alert.addAction(UIAlertAction(title: "OK",
                                      style: UIAlertAction.Style.default, handler: { alertAction in
            closure(candidateTags)
        }))
        self.present(alert, animated: true)
    }
    
    func turnCommentAutocompletionsIntoTags(_ commentAutocompletions: [String: AnyObject]) -> [Tag] {
        var tags = [Tag]()
        for (name, context) in commentAutocompletions {
            if let taggedUserId = context[AutocompleteContext.id.rawValue] as? Int {
                //Completion from users
                let userTag = Tag(id: Int.random(in: 0..<Int.max), comment: 0, tagged_name: name, tagged_user: taggedUserId, tagged_phone_number: nil, tagging_user: UserService.singleton.getId(), timestamp: Date().timeIntervalSince1970)
                tags.append(userTag)
            } else if let number = context[AutocompleteContext.number.rawValue] as? String {
                //Completion from contacts
                let contactTag = Tag(id: Int.random(in: 0..<Int.max), comment: 0, tagged_name: name, tagged_user: nil, tagged_phone_number: number.formatAsDjangoPhoneNumber(), tagging_user: UserService.singleton.getId(), timestamp: Date().timeIntervalSince1970)
                tags.append(contactTag)
            }
        }
        return tags
    }

    
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        // Adjust content insets
        print("didchangeinputbarintrinsicsizeto:", size)
        tableView.contentInset.bottom = size.height + keyboardHeight
        updateMaxAutocompleteRows(keyboardHeight: keyboardHeight)
        tableView.keyboardDismissMode = asyncCompletions.isEmpty ? .interactive : .none
    }
    
    func updateMaxAutocompleteRows(keyboardHeight: Double) {
        let inputHeight = inputBar.inputTextView.frame.height + 10
        autocompleteManager.tableView.maxVisibleRows = Int((tableView.frame.height - keyboardHeight - inputHeight) / autocompleteManager.tableView.rowHeight)
    }

    @objc func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        inputBar.inputTextView.placeholderLabel.isHidden = !inputBar.inputTextView.text.isEmpty
        inputBar.sendButton.isEnabled = inputBar.inputTextView.text != ""
        processAutocompleteOnNextText(text)
    }
        
}

//MARK: - UITextViewDelegate

//NOTE: We are snatching the UITextViewDelegate from the autocompleteManager, so 

extension PostViewController: UITextViewDelegate {
        
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        // Don't allow whitespace as first character
        if (text == " " || text == "\n") && textView.text.count == 0 {
            textView.text = ""
            return false
        }
        
        guard textView.shouldChangeTextGivenMaxLengthOf(MAX_COMMENT_LENGTH, range, text) else { return false }
        
        return autocompleteManager.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        autocompleteManager.textViewDidChange(textView)
    }
    
    
}

extension PostViewController {
    
    //MARK: - User Interaction
        
    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func dismissAllKeyboards() {
        view.endEditing(true)
    }
    
}

//MARK: - Db Calls

extension PostViewController {
        
    func loadComments() {
        Task {
            do {
                activityIndicator.startAnimating()
                comments = try await CommentAPI.fetchCommentsByPostID(post: post.id)
                commentAuthors = try await UserAPI.batchTurnUsersIntoFrontendUsers(comments.map { $0.read_only_author })
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                }
            } catch {
                CustomSwiftMessages.displayError(error)
            }
            activityIndicator.stopAnimating()
            tableView.sectionFooterHeight = 0
        }
    }
    
}

// MARK: - TableViewDataSource

extension PostViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return postAndCommentCellForRowAtIndexPath(indexPath)
    }
    
    func postAndCommentCellForRowAtIndexPath(_ indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
            cell.configurePostCell(post: post, nestedPostViewDelegate: self, bubbleTrianglePosition: .left, isWithinPostVC: true)
            return cell
        }
        //else the cell is a comment
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Comment, for: indexPath) as! CommentCell
        let comment = comments[indexPath.row-1]
        cell.configureCommentCell(comment: comment, delegate: self, author: commentAuthors[comment.author]!)
        return cell
    }
    
}

//MARK: - UITableViewDelegate

extension PostViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return activityIndicator
    }
    
}

//MARK: - CommentDelegate

extension PostViewController: CommentDelegate {
    
    func handleCommentProfilePicTap(commentAuthor: FrontendReadOnlyUser) {
        let profileVC = ProfileViewController.create(for: commentAuthor)
        navigationController?.present(profileVC, animated: true)
    }
    
    //TODO: is URL a phone number or a userId??
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print("SHOULD INTERACT W URL")
        guard let userId = Int(URL.absoluteString) else { return false }
        handleTagTap(taggedUserId: userId, taggedNumber: nil)
        return false //could return "true" here if we're using real deep links, but we're just having LINK = the profile's username
    }
    
    func handleTagTap(taggedUserId: Int?, taggedNumber: String?) {
        Task {
            do {
                if let taggedUserId = taggedUserId {
                    guard let taggedUser = try await loadTaggedProfileTasks[taggedUserId]?.value else { return }
                    DispatchQueue.main.async { [weak self] in
                        let profileVC = ProfileViewController.create(for: taggedUser)
                        self?.navigationController?.present(profileVC, animated: true)
                    }
                } else {
                    //handle taggedNumber
                }
            } catch {
                print("COULD NOT LOAD TAG PROFILE PART 2")
            }
        }
    }
    
    //TODO: Fetch by tagged number
    func beginLoadingTaggedProfile(taggedUserId: Int?, taggedNumber: String?) {
        let _ : Task<FrontendReadOnlyUser?, Error> = Task {
            do {
                if let taggedUserId = taggedUserId {
                    let user = try await UserAPI.fetchUsersByUserId(userId: taggedUserId)
                    if let profile = loadTaggedProfileTasks[user.id] {
                        return try await profile.value
                    }
                    loadTaggedProfileTasks[user.id] = Task {
                        return try await UserAPI.turnUserIntoFrontendUser(user)
                    }
                } else {
                    //handle taggedNumber
//                    let user = try await UserAPI.fetchUsersByUserId(userId: taggedUserId)
//                    if loadTaggedProfileTasks[user.id] != nil { return } //Task was already started
//                    loadTaggedProfileTasks[user.id] = Task {
//                        return try await UserAPI.turnUserIntoFrontendUser(user)
//                    }
                    return nil
                }
            } catch {
                print("COULD NOT LOAD TAGGED PROFILE PIC")
                return nil
            }
            return nil
        }
    }

}

// MARK: - Helpers

extension PostViewController {
    
    func handleSuccessfulCommentSubmission(newComment: Comment) {
        clearAllFields()
        inputBar.inputTextView.resignFirstResponder()
        tableView.scrollToRow(at: IndexPath(row: comments.count, section: 0), at: .bottom, animated: true)
        post.commentcount += 1
        comments.append(newComment)
        commentAuthors[newComment.author] = UserService.singleton.getUserAsFrontendReadOnlyUser()
        tableView.reloadData()
    }
    
    func clearAllFields() {
        inputBar.inputTextView.text = ""
    }
    
}

//MARK: - PostDelegate

extension PostViewController: PostDelegate {
    
    func handleVote(postId: Int, isAdding: Bool) {
        // viewController update
        let originalVoteCount = post.votecount
        post.votecount += isAdding ? 1 : -1
        
        // Singleton & remote update
        do {
            try VoteService.singleton.handleVoteUpdate(postId: postId, isAdding)
        } catch {
            post.votecount = originalVoteCount //undo viewController data change
            (tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! PostCell).postView.reconfigurePost(updatedPost: post) //reload data
            CustomSwiftMessages.displayError(error)
        }
    }
    
    func handleBackgroundTap(postId: Int) {
        view.endEditing(true)
    }
    
    func handleCommentButtonTap(postId: Int) {
        if !inputBar.inputTextView.isFirstResponder {
            inputBar.inputTextView.becomeFirstResponder()
        } else {
            inputBar.inputTextView.resignFirstResponder()
        }
    }
    
    func handleDeletePost(postId: Int) {
        navigationController?.popViewController(animated: true)
    }
    
}
