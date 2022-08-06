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
    
    //TODO: below is not working. we have to adjust the insets within keyboardManager, maybe add an extra extension
//    var additionalBottomInset: CGFloat = 0 {
//        didSet {
//            tableView.contentInset.bottom += additionalBottomInset
//            tableView.verticalScrollIndicatorInsets.bottom += additionalBottomInset
//        }
    
    private let tagTextAttributes: [NSAttributedString.Key : Any] = [
//        .font: UIFont.preferredFont(forTextStyle: .body),
        .font: UIFont(name: Constants.Font.Heavy, size: 17)!,
        .foregroundColor: UIColor.black,
//        .backgroundColor: UIColor.red.withAlphaComponent(0.1)
    ]
        
    //Flags
    var shouldStartWithRaisedKeyboard: Bool!
    
    //Autocomplete
    let contactStore = CNContactStore()
    var asyncCompletions: [AutocompleteCompletion] = []
    var autocompleteTask: Task<Void, Never>?
    open lazy var autocompleteManager: CommentAutocompleteManager = { [unowned self] in
        let manager = CommentAutocompleteManager(for: self.inputBar.inputTextView)
        manager.delegate = self
        manager.dataSource = self
        return manager
    }()
    
    //Data
    var post: Post!
    var comments = [Comment]()
    var commentAuthors = [Int: FrontendReadOnlyUser]() //[authorId: author]
    
    //PostDelegate
    var loadAuthorProfilePicTasks: [Int: Task<FrontendReadOnlyUser?, Never>] = [:]
    
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
        setupAutocomplete()
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
//        if shouldStartWithRaisedKeyboard {
            // For that reason, we wont raise keyboard, for now
//          self.inputBar.inputTextView.becomeFirstResponder()
//        }
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
    
    func setupAutocomplete() {
        autocompleteManager.register(prefix: "@", with: tagTextAttributes)

        autocompleteManager.appendSpaceOnCompletion = true
        autocompleteManager.keepPrefixOnCompletion = true
        autocompleteManager.deleteCompletionByParts = false
        
        //The following two aren't actually needed because of our own checks
//        autocompleteManager.register(delimiterSet: .whitespacesAndNewlines)
//        autocompleteManager.maxSpaceCountDuringCompletion = 1
        
        autocompleteManager.tableView.maxVisibleRows = view.frame.height < 600 ? 4 : 5
        autocompleteManager.tableView.rowHeight = 50
//        autocompleteManager.tableView.separatorColor = .clear //not doing anything..?
        
        autocompleteManager.tableView.register(TagAutocompleteCell.self, forCellReuseIdentifier: TagAutocompleteCell.reuseIdentifier)
        inputBar.inputPlugins = [autocompleteManager]
    }
    
    func setupCommentInputBar() {
        inputBar.delegate = self
        inputBar.inputTextView.delegate = self
        inputBar.shouldAnimateTextDidChangeLayout = true
        inputBar.maxTextViewHeight = 144 //max of 6 lines with the given font
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
        
        let trimmedCommentText = inputBar.inputTextView.text.trimmingCharacters(in: .whitespaces)

        // Here we can parse for which substrings were autocompleted
        let attributedText = inputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        let autocompletions = [AutocompleteContext]()
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (attributes, range, stop) in
            
            let substring = attributedText.attributedSubstring(from: range)
            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
            print("Autocompleted: `", substring, "` with context: ", context ?? [])
//            autocompletions.append(context)
        }

        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        
//        for autocompletion in autocompletions {
//            if autocompletions.context
//        }
        
        //adam: make sure that fucking with the tag before posting doesnt fuck up the tag collected above
        ///for each autocompletion:
        ///IF CONTACT
        /// load users by the contact's phone number. ensure that the phone number is not already associated with an account
        ///     this check wouldnt be necessary if we loaded in user's phone number in profile
        ///IF USER
        ///create a tag with
        ///
        ///post the comment and any necessary tags all at once
        ///QUESTION: does the relevant comment need to exist before the tags?
        ///
        ///
//        CommentService.singleton.uploadComment( ... tags: tags) should also handle tags
//        TagAPI.postTag(comment: <#T##Int#>, tagged_name: <#T##String#>, tagging_user: <#T##Int#>, tagged_user: <#T##Int?#>, tagged_phone_number: <#T##String?#>)
        
        Task {
            do {
                inputBar.sendButton.isEnabled = false
                let newComment = try await CommentService.singleton.uploadComment(text: trimmedCommentText, postId: post.id)
                handleSuccessfulCommentSubmission(newComment: newComment)
            } catch {
                inputBar.sendButton.isEnabled = true
                CustomSwiftMessages.displayError(error)
            }
        }
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        // Adjust content insets
        print("didchangeinputbarintrinsicsizeto:", size)
        tableView.contentInset.bottom = size.height + 300 // keyboard size estimate
    }
    
    @objc func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
//        inputBar.setRightStackViewWidthConstant(to: text.isEmpty ? 0 : 45, animated: true)
        inputBar.inputTextView.placeholderLabel.isHidden = !inputBar.inputTextView.text.isEmpty
        validateAllFields()
        processAutocomplete(text)
    }
}

//MARK: - UITextViewDelegate

extension PostViewController: UITextViewDelegate {
        
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        print("SHOUDL CHANGE TEXT IN")
        
        // Don't allow " " as first character
        if text == " " && textView.text.count == 0 {
            return false
        }
        // Only return true if the length of text is within the limit
        return textView.shouldChangeTextGivenMaxLengthOf(MAX_COMMENT_LENGTH + TEXT_LENGTH_BEYOND_MAX_PERMITTED, range, text)
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
//                comments = try await CommentAPI.fetchCommentsByPostID(post: post.id)
//                commentAuthors = try await UserAPI.batchTurnUsersIntoFrontendUsers(comments.map { $0.read_only_author })
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
        return 0
//        return comments.count + 1
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
        navigationController!.present(profileVC, animated: true)
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
        
    func validateAllFields() {
        inputBar.sendButton.isEnabled = inputBar.inputTextView.text != ""
    }
    
    func clearAllFields() {
        inputBar.inputTextView.text = ""
        validateAllFields()
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
