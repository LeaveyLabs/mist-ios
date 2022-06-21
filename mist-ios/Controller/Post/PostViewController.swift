//
//  PostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit

let COMMENT_PLACEHOLDER_TEXT = "@ibrahimmm this you?"
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
        get { return wrappedAccessoryView }
    }
    
    //Flags
    var shouldStartWithRaisedKeyboard: Bool!
    
    //Data
    var post: Post! // PostVC should never be created without a post
    var comments = [Comment]()
    var commentProfilePics = [Int: UIImage]()
    
    //PostDelegate
    var voteTasks: [Task<Void, Never>] = []
    var favoriteTasks: [Task<Void, Never>] = []
    
    //Misc
    var prepareForDismiss: UpdatedPostCompletionHandler?
    
    //MARK: - Initialization
    
    class func createPostVC(with post: Post) -> PostViewController {
        let postVC =
        UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Post) as! PostViewController
        postVC.post = post
        return postVC
    }
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        setupTableView()
        setupCommentView()
        loadComments()
        
        view.keyboardLayoutGuide.topAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
        let tableViewTap = UITapGestureRecognizer.init(target: self, action: #selector(dismissKeyboard))
        tableView.addGestureRecognizer(tableViewTap)
                
        //User Interaction
        //(1 of 2) for enabling swipe left to go back with a bar button item
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
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
//            commentTextView.becomeFirstResponder() //not working right nowvcdc  
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
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
        tableView.separatorStyle = .none
        
        tableView.register(PostCell.self, forCellReuseIdentifier: Constants.SBID.Cell.Post)
        let commentNib = UINib(nibName: Constants.SBID.Cell.Comment, bundle: nil)
        tableView.register(commentNib, forCellReuseIdentifier: Constants.SBID.Cell.Comment)
        
        
        tableView.tableFooterView = activityIndicator
        activityIndicator.startAnimating()
        
        //we are choosing to leave out this functionality for now
        tableView.keyboardDismissMode = .interactive
    }
    
    func oldBecomeCommentCode() { //Deprecated
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
    
    //(2 of 2) for enabling swipe left to go back with a bar button item
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func submitCommentButtonDidPressed(_ sender: UIButton) {
        guard !commentTextView.text.isEmpty else { return }
        Task {
            do {
                commentSubmitButton.isEnabled = false
                let newComment = try await UserService.singleton.uploadComment(text: commentTextView.text,
                                                                               postId: post.id)
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
                comments = try await CommentAPI.fetchCommentsByPostID(post: post.id)
                commentProfilePics = try await loadCommentThumbnails(for: comments)
                tableView.reloadData()
            } catch {
                CustomSwiftMessages.displayError(error)
            }
            activityIndicator.stopAnimating()
        }
    }
    
    func loadCommentThumbnails(for comments: [Comment]) async throws -> [Int: UIImage] {
      var thumbnails: [Int: UIImage] = [:]
      try await withThrowingTaskGroup(of: (Int, UIImage).self) { group in
        for comment in comments {
          group.addTask {
              return (comment.id, try await UserAPI.UIImageFromURLString(url: comment.read_only_author.picture))
          }
        }
        for try await (id, thumbnail) in group {
          thumbnails[id] = thumbnail
        }
      }
      return thumbnails
    }
    
}

//MARK: - TextViewDelegate

extension PostViewController: UITextViewDelegate {
        
    func textViewDidChange(_ textView: UITextView) {
        commentPlaceholderLabel.isHidden = !commentTextView.text.isEmpty
        validateAllFields()
    }
    
    //dismiss keyboard when user presses "return"
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
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
            cell.configurePostCell(post: post, nestedPostViewDelegate: self, bubbleTrianglePosition: .left)
            return cell
        }
        //else the cell is a comment
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Comment, for: indexPath) as! CommentCell
        let comment = comments[indexPath.row-1]
        let commentAuthor = FrontendReadOnlyUser(readOnlyUser: comment.read_only_author,
                                                 profilePic: commentProfilePics[comment.id]!)
        cell.configureCommentCell(comment: comment, delegate: self, author: commentAuthor)
        return cell
    }
}

//MARK: - CommentDelegate

extension PostViewController: CommentDelegate {
    
    func handleCommentProfilePicTap(commentAuthor: FrontendReadOnlyUser) {
        let profileVC = ProfileViewController.createProfileVC(with: commentAuthor)
        navigationController!.present(profileVC, animated: true)
    }
        
}

// MARK: - Helpers

extension PostViewController {
    
    func handleSuccessfulCommentSubmission(newComment: Comment) {
        clearAllFields()
        commentTextView.resignFirstResponder()
        tableView.scrollToRow(at: IndexPath(row: comments.count, section: 0), at: .bottom, animated: true)
        post.commentcount += 1
        comments.append(newComment)
        commentProfilePics[newComment.id] = UserService.singleton.getProfilePic()
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
    
    func handleBackgroundTap(post: Post) {
        commentTextView.resignFirstResponder()
    }
    
    func handleCommentButtonTap(post: Post) {
        commentTextView.becomeFirstResponder()
    }
    
}
