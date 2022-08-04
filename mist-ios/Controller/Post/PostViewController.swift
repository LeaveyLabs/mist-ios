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

class PostViewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    //MARK: - Properties
    
    //UI
    var activityIndicator = UIActivityIndicatorView(style: .medium)
    @IBOutlet var tableView: UITableView!
    
    //Comment
    let keyboardManager = KeyboardManager() //InputBarAccessoryView
    let inputBar = InputBarAccessoryView()
    let MAX_COMMENT_LENGTH = 499
    
    //TODO: below is not working. we have to adjust the insets within keyboardManager, maybe add an extra extension
//    var additionalBottomInset: CGFloat = 0 {
//        didSet {
//            tableView.contentInset.bottom += additionalBottomInset
//            tableView.verticalScrollIndicatorInsets.bottom += additionalBottomInset
//        }
    
    
//    }
//    @IBOutlet weak var commentProfileImage: UIImageView!
//    var commentPlaceholderLabel: UILabel!
    //    @IBOutlet weak var commentTextView: UITextView!
    //    @IBOutlet var commentAccessoryView: UIView!
        //    var wrappedAccessoryView: SafeAreaInputAccessoryViewWrapperView!
//    @IBOutlet weak var commentSubmitButton: UIButton!
    
    private let tagTextAttributes: [NSAttributedString.Key : Any] = [
//        .font: UIFont.preferredFont(forTextStyle: .body),
        .font: UIFont(name: Constants.Font.Heavy, size: 14)!,
        .foregroundColor: UIColor.systemBlue,
        .backgroundColor: UIColor.systemBlue.withAlphaComponent(0.1)
    ]
    
    /// The object that manages autocomplete
    open lazy var autocompleteManager: AutocompleteManager = { [unowned self] in
        let manager = AutocompleteManager(for: self.inputBar.inputTextView)
        manager.delegate = self
        manager.dataSource = self
        return manager
    }()
    
    //Flags
    var shouldStartWithRaisedKeyboard: Bool!
    
    //Autocomplete
    let contactStore = CNContactStore()
    var asyncCompletions: [AutocompleteCompletion] = []
    
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
        
        inputBar.inputTextView.resignFirstResponder() //better ui animation
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldStartWithRaisedKeyboard {
            DispatchQueue.main.async {
                self.inputBar.inputTextView.becomeFirstResponder()
            }
        }
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
        autocompleteManager.register(delimiterSet: .whitespacesAndNewlines)
        autocompleteManager.maxSpaceCountDuringCompletion = 1
        
        inputBar.inputPlugins = [autocompleteManager]
    }
    
//    func setupCommentView() {
//        commentProfileImage.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
//
//        commentTextView.delegate = self
//        commentTextView.becomeCommentView()
//        commentAccessoryView.borders(for: [UIRectEdge.top])
////        wrappedAccessoryView = SafeAreaInputAccessoryViewWrapperView(for: commentAccessoryView) //
//        commentTextView.inputAccessoryView = commentAccessoryView
//
//        commentTextView.textContainer.lineFragmentPadding = 0
//        commentTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
//        commentPlaceholderLabel = commentTextView.addAndReturnPlaceholderLabel(withText: COMMENT_PLACEHOLDER_TEXT)
//        commentSubmitButton.isEnabled = false
//    }
    
    func setupCommentInputBar() {
        inputBar.delegate = self
        inputBar.shouldAnimateTextDidChangeLayout = true
        inputBar.maxTextViewHeight = 144 //max of 6 lines with the given font
        inputBar.inputTextView.keyboardType = .twitter
        inputBar.inputTextView.placeholder = COMMENT_PLACEHOLDER_TEXT
        
        //Middle
        inputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 36)
        inputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 36)
        inputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        inputBar.inputTextView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.8).cgColor
        inputBar.inputTextView.backgroundColor = .lightGray.withAlphaComponent(0.1)
        inputBar.inputTextView.layer.borderWidth = 0.5
        inputBar.inputTextView.layer.cornerRadius = 16.0
        inputBar.inputTextView.layer.masksToBounds = true
        inputBar.setRightStackViewWidthConstant(to: 38, animated: false)
        inputBar.setStackViewItems([inputBar.sendButton, InputBarButtonItem.fixedSpace(2)], forStack: .right, animated: false)
        
        //Right
        inputBar.sendButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 4, right: 2)
        inputBar.sendButton.setSize(CGSize(width: 36, height: 36), animated: false)
        inputBar.sendButton.setImage(UIImage(named: "enabled-send-button"), for: .normal)
        inputBar.sendButton.title = nil
        inputBar.sendButton.becomeRound()
        inputBar.middleContentViewPadding.right = -38
        
        //TODO: raise the avatar by like 2px
        //Left
        let avatar = InputBarButtonItem()
        avatar.setSize(CGSize(width: 36, height: 36), animated: false)
//        avatar.setImage(UserService.singleton.getProfilePic(), for: .normal)
        avatar.imageView?.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
        inputBar.setLeftStackViewWidthConstant(to: 41, animated: false)
        inputBar.setStackViewItems([avatar, InputBarButtonItem.fixedSpace(5)], forStack: .left, animated: false)
    }
    
    func setupKeyboardManagerForBottomInputBar() {
        view.addSubview(inputBar)
        keyboardManager.shouldApplyAdditionBottomSpaceToInteractiveDismissal = true
        keyboardManager.bind(inputAccessoryView: inputBar)
        keyboardManager.bind(to: tableView) // Binding to the tableView will enabled interactive dismissal
        keyboardManager.on(event: .didHide) { [weak self] keyboardNotification in
            self?.setAutocompleteManager(active: false)
        }
    }
}

extension PostViewController: InputBarAccessoryViewDelegate {
    
    // MARK: - InputBarAccessoryViewDelegate
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        let trimmedCommentText = inputBar.inputTextView.text.trimmingCharacters(in: .whitespaces)

        // Here we can parse for which substrings were autocompleted
        let attributedText = inputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (attributes, range, stop) in
            
            let substring = attributedText.attributedSubstring(from: range)
            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
            print("Autocompleted: `", substring, "` with context: ", context ?? [])
        }

        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
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
        print(size)
        tableView.contentInset.bottom = size.height + 300 // keyboard size estimate
    }
    
    @objc func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        processAutocomplete(text)
    }
    
}

extension PostViewController {
    
    //MARK: - User Interaction
    
    //Disabling for now ujntil we find an alternative way to attach the input bar to the bottom besides using the view controller's first responder property
    //1 of 2
//    self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    //(2 of 2) for enabling swipe left to go back with a bar button item
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true
//    }
        
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

//MARK: - TextViewDelegate

extension PostViewController: UITextViewDelegate {
        
    func textViewDidChange(_ textView: UITextView) {
        inputBar.inputTextView.placeholderLabel.isHidden = !inputBar.inputTextView.text.isEmpty
        validateAllFields()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Don't allow " " as first character
        if text == " " && textView.text.count == 0 {
            return false
        }
        // Only return true if the length of text is within the limit
        return textView.shouldChangeTextGivenMaxLengthOf(MAX_COMMENT_LENGTH + TEXT_LENGTH_BEYOND_MAX_PERMITTED, range, text)
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
            setAutocompleteManager(active: false)
            inputBar.inputTextView.resignFirstResponder()
        }
    }
    
    func handleDeletePost(postId: Int) {
        navigationController?.popViewController(animated: true)
    }
    
}
