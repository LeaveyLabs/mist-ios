//
//  PostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit

let COMMENT_PLACEHOLDER_TEXT = "Comment or tag"
typealias UpdatedPostCompletionHandler = ((Post) -> Void)

class PostViewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    //MARK: - Properties
    
    //UI
    @IBOutlet weak var tableView: UITableView!
    var activityIndicator = UIActivityIndicatorView(style: .medium)

    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet var commentAccessoryView: UIView!
    var wrappedAccessoryView: SafeAreaInputAccessoryViewWrapperView!
    
    @IBOutlet weak var commentProfileImage: UIImageView!
    @IBOutlet weak var commentSubmitButton: UIButton!
    var commentPlaceholderLabel: UILabel!
    override var canBecomeFirstResponder: Bool {
        get { return true } //means that the inputAccessoryView will always be enabled
    }
    override var inputAccessoryView: UIView {
        get {
            return (commentTextView.isFirstResponder || self.isFirstResponder ) ? wrappedAccessoryView : UIView(frame: .zero)
        }
    }
    
    //Flags
    var shouldStartWithRaisedKeyboard: Bool!
    var keyboardHeight: CGFloat = 0 //emoji keyboard autodismiss flag
    var isKeyboardForEmojiReaction: Bool = false
    
    //Data
    var post: Post!
    var comments = [Comment]()
    var commentAuthors = [Int: FrontendReadOnlyUser]() //[authorId: author]
    
    //PostDelegate
    var loadAuthorProfilePicTasks: [Int: Task<FrontendReadOnlyUser?, Never>] = [:]
    
    //Misc
    var prepareForDismiss: UpdatedPostCompletionHandler?
    let MAX_COMMENT_LENGTH = 499

    //MARK: - Initialization
    
    class func createPostVC(with post: Post, shouldStartWithRaisedKeyboard: Bool, completionHandler: UpdatedPostCompletionHandler?) -> PostViewController {
        let postVC =
        UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Post) as! PostViewController
        postVC.post = post
        postVC.shouldStartWithRaisedKeyboard = shouldStartWithRaisedKeyboard
        postVC.prepareForDismiss = completionHandler
        return postVC
    }
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        commentTextView.becomeFirstResponder()
        
        setupTableView()
        setupCommentView()
        loadComments()
        
        self.view.keyboardLayoutGuide.topAnchor.constraint(equalTo: self.tableView.bottomAnchor).isActive = true
        let tableViewTap = UITapGestureRecognizer.init(target: self, action: #selector(dismissKeyboard))
        tableView.addGestureRecognizer(tableViewTap)
        
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
    
    @objc func dismissKeyboard() {
        commentTextView.resignFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldStartWithRaisedKeyboard {
//            commentTextView.becomeFirstResponder() //not working right nowv
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isAboutToClose {
            commentTextView.text = ""
            if let completionHandler = prepareForDismiss{
                completionHandler(post)
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
    }
    
    @available(*, deprecated, message: "Because !")
    func oldBecomeCommentCode() {
        commentTextView.layer.borderWidth = 1
        commentTextView.layer.borderColor = UIColor.lightGray.cgColor
        commentTextView.layer.cornerRadius = 15
        commentTextView.textContainer.lineFragmentPadding = 0
        commentTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        commentAccessoryView.borders(for: [UIRectEdge.top])
    }
    
    func setupCommentView() {
        commentProfileImage.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
        
        commentTextView.delegate = self
        commentTextView.becomeCommentView()
        commentAccessoryView.borders(for: [UIRectEdge.top])
        wrappedAccessoryView = SafeAreaInputAccessoryViewWrapperView(for: commentAccessoryView)
        commentTextView.inputAccessoryView = wrappedAccessoryView

        commentTextView.textContainer.lineFragmentPadding = 0
        commentTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        commentPlaceholderLabel = commentTextView.addAndReturnPlaceholderLabel(withText: COMMENT_PLACEHOLDER_TEXT)
        
        commentSubmitButton.isEnabled = false
    }
    
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
    
    @IBAction func submitCommentButtonDidPressed(_ sender: UIButton) {
        guard let trimmedCommentText = commentTextView?.text.trimmingCharacters(in: .whitespaces) else { return }
        Task {
            do {
                commentSubmitButton.isEnabled = false
                let newComment = try await CommentService.singleton.uploadComment(text: trimmedCommentText, postId: post.id)
                handleSuccessfulCommentSubmission(newComment: newComment)
            } catch {
                commentSubmitButton.isEnabled = true
                CustomSwiftMessages.displayError(error)
            }
        }
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
                tableView.reloadData()
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
        commentPlaceholderLabel.isHidden = !commentTextView.text.isEmpty
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
        commentTextView.resignFirstResponder()
        tableView.scrollToRow(at: IndexPath(row: comments.count, section: 0), at: .bottom, animated: true)
//        post.commentcount += 1
        comments.append(newComment)
        commentAuthors[newComment.author] = UserService.singleton.getUserAsFrontendReadOnlyUser()
        tableView.reloadData()
    }
        
    func validateAllFields() {
        commentSubmitButton.isEnabled = commentTextView.text != ""
    }
    
    func clearAllFields() {
        commentTextView.text! = ""
        validateAllFields()
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
        commentTextView.resignFirstResponder()
    }
    
    func handleCommentButtonTap(postId: Int) {
        commentTextView.becomeFirstResponder()
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
                
        if keyboardHeight < previousK {
            if commentTextView.isFirstResponder { return } //this should only run for emoji keyboard, not comment keyboard
            view.endEditing(true)
        }
        
        if keyboardHeight > previousK && isKeyboardForEmojiReaction { //keyboard is appearing for the first time && we don't want to scroll the feed when the search controller keyboard is presented
            isKeyboardForEmojiReaction = false
            scrollFeedToPostRightAboveKeyboard()
        }
    }
        
    @objc func keyboardWillDismiss(sender: NSNotification) {
        keyboardHeight = 0
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
