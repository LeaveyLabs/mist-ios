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
    var isKeyboardForEmojiReaction: Bool = false
    
    //Autocomplete
    let contactStore = CNContactStore()
    var asyncCompletions: [AutocompleteCompletion] = []
    var mostRecentAutocompleteQuery = ""
    var autocompletionCache = [String: [AutocompleteCompletion]]()
    var autocompletionTasks = [String: Task<Void, Never>]()
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
    
    //Data
    var post: Post!
    var comments = [Comment]()
    var commentAuthors = [Int: FrontendReadOnlyUser]() //[authorId: author]
    
    //PostDelegate
//    var loadAuthorProfilePicTasks: [Int: Task<FrontendReadOnlyUser?, Never>] = [:]
//    var loadTaggedProfileTasks: [Int : Task<FrontendReadOnlyUser?, Error>] = [:] //Error, not Never, because we're doing 2 layers of DoTry calls

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
        navigationController?.fullscreenInteractivePopGestureRecognizer(delegate: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Emoji keyboard autodismiss notification
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillDismiss(sender:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        inputBar.inputTextView.resignFirstResponder()
        inputBar.inputTextView.canBecomeFirstResponder = false //so it doesnt become first responder again if the swipe back gesture is cancelled halfway through
        //no longer using the postVC's willDismiss completion handler here: we could delete that
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disableInteractivePopGesture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldStartWithRaisedKeyboard {
          self.inputBar.inputTextView.becomeFirstResponder()
        }
        enableInteractivePopGesture()
        inputBar.inputTextView.canBecomeFirstResponder = true // to offset viewWillDisappear
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
        inputBar.configureForCommenting()
    }
    
    func setupKeyboardManagerForBottomInputBar() {
        addKeyboardObservers()
        
        keyboardManager.on(event: .didHide) { [weak self] keyboardNotification in
            self?.setAutocompleteManager(active: false)
        }
        
        keyboardManager.on(event: .didShow) { [self] keyboardNotification in
            keyboardHeight = keyboardNotification.endFrame.height
            updateMaxAutocompleteRows(keyboardHeight: keyboardHeight)
        }
    }
    
}

extension PostViewController: InputBarAccessoryViewDelegate {
    
    // MARK: - InputBarAccessoryViewDelegate
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let commentAutocompletions = extractAutocompletionsFromInputBarText()
        let tags = turnCommentAutocompletionsIntoTags(commentAutocompletions)
        requestPermissionToTextIfNecessary(autocompletions: commentAutocompletions, tags: tags) { [self] permission in
            guard permission else { return }
            Task {
                do {
                    let trimmedCommentText = inputBar.inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    inputBar.sendButton.isEnabled = false
//                    inputBar.inputTextView.isEditable = false
                    let newComment = try await CommentService.singleton.uploadComment(text: trimmedCommentText, postId: post.id, tags: tags)
                    handleSuccessfulCommentSubmission(newComment: newComment)
                } catch {
                    inputBar.sendButton.isEnabled = true
                    inputBar.inputTextView.isEditable = true
                    CustomSwiftMessages.displayError(error)
                }
            }
        }
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
    
    //MARK: - InputBar Helpers
    
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
    
    func requestPermissionToTextIfNecessary(autocompletions commentAutocompletions: [String: AnyObject], tags: [Tag], closure: @escaping (_ permission: Bool) -> Void) {
        let tagsFromContacts = tags.filter({ $0.tagged_phone_number != nil })
        guard tagsFromContacts.count > 0 else {
            closure(true)
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
            closure(false)
        }))
        alert.addAction(UIAlertAction(title: "OK",
                                      style: UIAlertAction.Style.default, handler: { alertAction in
            closure(true)
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
            } else if let numberE164 = context[AutocompleteContext.numberE164.rawValue] as? String {
                //Completion from contacts
                let contactTag = Tag(id: Int.random(in: 0..<Int.max), comment: 0, tagged_name: name, tagged_user: nil, tagged_phone_number: numberE164, tagging_user: UserService.singleton.getId(), timestamp: Date().timeIntervalSince1970)
                tags.append(contactTag)
            }
        }
        return tags
    }
    
    @MainActor
    func handleSuccessfulCommentSubmission(newComment: Comment) {
        inputBar.inputTextView.text = ""
        inputBar.invalidatePlugins()
        inputBar.inputTextView.isEditable = true
        inputBar.inputTextView.resignFirstResponder()
//        post.commentcount += 1
        comments.append(newComment)
        commentAuthors[newComment.author] = UserService.singleton.getUserAsFrontendReadOnlyUser()
        tableView.reloadData()
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                self.tableView.scrollToRow(at: IndexPath(row: self.comments.count, section: 0), at: .bottom, animated: true)
            }
        }
    }
        
}

//MARK: - UITextViewDelegate

//NOTE: We are snatching the UITextViewDelegate from the autocompleteManager, so  make sure to call autocompleteManager.textView(...) at the end

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
                commentAuthors = try await UsersService.singleton.loadAndCacheUsers(users: comments.map { $0.read_only_author } )
//                loadFakeProfilesWhenAWSIsDown()
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                    self?.updateMessageCollectionViewBottomInset()
                }
            } catch {
                CustomSwiftMessages.displayError(error)
            }
            activityIndicator.stopAnimating()
            tableView.sectionFooterHeight = 0
        }
    }
    
    func loadFakeProfilesWhenAWSIsDown() {
        commentAuthors = comments.reduce(into: [Int: FrontendReadOnlyUser](), { partialResult, comment in
            partialResult[comment.author] = UserService.singleton.getUserAsFrontendReadOnlyUser()
        })
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
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print("SHOULD INTERACT W URL")
        
        guard let tagLink = TagLink.decodeTag(linkString: URL.absoluteString) else { return false }
        switch tagLink.tagType {
        case .id:
            guard let userId = Int(tagLink.tagValue) else { return false }
            handleTagTap(taggedUserId: userId, taggedNumber: nil, taggedHandle: tagLink.tagText)
        case .phone:
            handleTagTap(taggedUserId: nil, taggedNumber: tagLink.tagValue, taggedHandle: tagLink.tagText)
        }
        
        return false //could return "true" here if we're using real deep links, but we're just having LINK = the profile's username
    }
    
    func handleTagTap(taggedUserId: Int?, taggedNumber: String?, taggedHandle: String) {
        let profileVC = ProfileViewController.createAndLoadData(userId: taggedUserId, userNumber: taggedNumber, handle: taggedHandle)
        navigationController?.present(profileVC, animated: true)
    }
    
    func beginLoadingTaggedProfile(taggedUserId: Int?, taggedNumber: String?) {
        Task {
            do {
                if let taggedUserId = taggedUserId {
                    let _ = try await UsersService.singleton.loadAndCacheUser(userId: taggedUserId)
                } else if let taggedNumber = taggedNumber {
                    let _ = try await UsersService.singleton.loadAndCacheUser(phoneNumber: taggedNumber)
                }
            } catch {
                print("background profile loading task failed")
            }
        }
    }

}

//MARK: - PostDelegate

extension PostViewController: PostDelegate {
    
    func handleVote(postId: Int, emoji: String, action: VoteAction) {
        // viewController update
        //Below is no longer needed
//        let originalVoteCount = post.votecount
        
        // Singleton & remote update
        do {
            try VoteService.singleton.handleVoteUpdate(postId: postId, emoji: emoji, action)
        } catch {
//            post.votecount = originalVoteCount //undo viewController data change
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
    
    //MARK: - React interaction
    
    func handleReactTap(postId: Int) {
        isKeyboardForEmojiReaction = true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        view.endEditing(true)
        guard let postView = textField.superview as? PostView else { return false }
        if !string.isSingleEmoji { return false }
        postView.handleEmojiVote(emojiString: string)
        return false
    }
    
    @objc func keyboardWillChangeFrame(sender: NSNotification) {
        let i = sender.userInfo!
        let previousK = keyboardHeight
        keyboardHeight = (i[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        
        ///don't dismiss the keyboard when toggling to emoji search, which hardly (~1px) lowers the keyboard
        /// and which does lower the keyboard at all (0px) on largest phones
        ///do dismiss it when toggling to normal keyboard, which more significantly (~49px) lowers the keyboard
        if keyboardHeight < previousK - 5 {
            if !inputBar.inputTextView.isFirstResponder { //only for emoji, not comment, keyboard
                view.endEditing(true)
            }
        }
        
        if keyboardHeight > previousK && isKeyboardForEmojiReaction { //keyboard is appearing for the first time
            isKeyboardForEmojiReaction = false
            scrollFeedToPostRightAboveKeyboard()
            inputBar.isHidden = true
        }
        
        if keyboardHeight > 0 && inputBar.inputTextView.isFirstResponder {
            inputBar.isHidden = false
        }
    }
        
    @objc func keyboardWillDismiss(sender: NSNotification) {
        keyboardHeight = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.inputBar.isHidden = false
        }
    }
    
}

extension PostViewController {
    
    //also not quite working
    func scrollFeedToPostRightAboveKeyboard() {
        let postIndex = 0 //because postVC
        let postBottomYWithinFeed = tableView.rectForRow(at: IndexPath(row: postIndex, section: 0))
        let postBottomY = tableView.convert(postBottomYWithinFeed, to: view).maxY
        let keyboardTopY = view.bounds.height - keyboardHeight
        let desiredOffset = postBottomY - keyboardTopY
        if desiredOffset < 0 { return } //dont scroll up for the post
        tableView.setContentOffset(tableView.contentOffset.applying(.init(translationX: 0, y: desiredOffset)), animated: true)
    }
    
}
