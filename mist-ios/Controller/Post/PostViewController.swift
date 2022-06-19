//
//  PostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit

let COMMENT_PLACEHOLDER_TEXT = "wait this is so..."
typealias UpdatedPostCompletionHandler = ((Post) -> Void)

class PostViewController: KUIViewController, UIViewControllerTransitioningDelegate {
    
    //MARK: - Properties
    
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var commentProfileImage: UIImageView!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var commentButton: UIButton!
    var commentPlaceholderLabel: UILabel!
    var shouldStartWithRaisedKeyboard: Bool!
    
    //MARK: - Comments
    var post: Post! // PostVC should never be created without a post
    var comments: [Comment] = []
    @IBOutlet weak var postTableView: UITableView!
    var indicator = UIActivityIndicatorView()
    var completionHandler: UpdatedPostCompletionHandler?
    
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        setupTableView()
        setupCommentView()
        commentPlaceholderLabel = commentTextView.addAndReturnPlaceholderLabel(withText: COMMENT_PLACEHOLDER_TEXT)
        loadComments()
        shouldKUIViewKeyboardDismissOnBackgroundTouch = true
        
        //User Interaction
        //(1 of 2) for enabling swipe left to go back with a bar button item
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self;

        //Misc
        if shouldStartWithRaisedKeyboard {
            commentTextView.becomeFirstResponder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            commentTextView.text = ""
            if let completionHandler = completionHandler{
                completionHandler(post)
            }
        }
    }
    
    //MARK: - Initialization
    
    //create a postVC for a given post. postVC should never exist without a post
    class func createPostVCForPost(_ post: Post) -> PostViewController {
        let postVC =
        UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Post) as! PostViewController
        postVC.post = post
        return postVC
    }
    
    //MARK: - Setup
    
    func setupTableView() {
        postTableView.estimatedRowHeight = 100
        postTableView.rowHeight = UITableView.automaticDimension
        postTableView.dataSource = self
        
        let postNib = UINib(nibName: Constants.SBID.Cell.Post, bundle: nil);
        postTableView.register(postNib, forCellReuseIdentifier: Constants.SBID.Cell.Post);
        let commentNib = UINib(nibName: Constants.SBID.Cell.Comment, bundle: nil);
        postTableView.register(commentNib, forCellReuseIdentifier: Constants.SBID.Cell.Comment);
        
        //we are choosing to leave out this functionality for now
        //postTableView.keyboardDismissMode = .onDrag
    }
    
    func setupCommentView() {
//        commentTextView.inputAccessoryView = commentView
//        postTableView.keyboardDismissMode = .interactive

        commentProfileImage.layer.cornerRadius = commentProfileImage.frame.size.height / 2
        commentProfileImage.layer.cornerCurve = .continuous
        
        commentView.borders(for: [UIRectEdge.top])
        
        commentTextView.delegate = self
        commentTextView.layer.borderWidth = 1
        commentTextView.layer.borderColor = UIColor.lightGray.cgColor
        commentTextView.layer.cornerRadius = 15
        commentTextView.textContainer.lineFragmentPadding = 0
        commentTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        commentButton.isEnabled = false
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
                commentButton.isEnabled = false
                let newCommentAndUpdatedPost = try await UserService.singleton.uploadComment(
                    text: commentTextView.text,
                    postId: post.id,
                    author: UserService.singleton.getId())
                handleSuccessfulCommentSubmission(newComment: newCommentAndUpdatedPost.0, updatedPost: newCommentAndUpdatedPost.1)
            } catch {
                CustomSwiftMessages.displayError(error)
            }
            commentButton.isEnabled = true
        }
    }
    
}

//MARK: - Db Calls

extension PostViewController {
        
    func loadComments() {
        Task {
            do {
                comments = try await CommentAPI.fetchCommentsByPostID(post: post.id)
                postTableView.reloadData()
            } catch {
                CustomSwiftMessages.displayError(error)
            }
        }
    }
}

//MARK: - TextViewDelegate

extension PostViewController: UITextViewDelegate {
        
    func textViewDidChange(_ textView: UITextView) {
        commentPlaceholderLabel.isHidden = !commentTextView.text.isEmpty
        commentButton.isEnabled = validateAllFields()
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row == 0) {
            if let post = post {
                let cell = postTableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
                cell.configurePostCell(post: post, bubbleTrianglePosition: .left)
                cell.postDelegate = self
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                return cell
            }
        }
        //else the cell is a comment
        let cell = postTableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Comment, for: indexPath) as! CommentCell
        cell.configureCommentCell(comment: comments[indexPath.row-1], parent: self)
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        return cell
    }
}

// MARK: - Helpers

extension PostViewController {
    
    func handleSuccessfulCommentSubmission(newComment: Comment, updatedPost: Post) {
        clearAllFields()
        commentTextView.resignFirstResponder()
        postTableView.scrollToRow(at: IndexPath(row: comments.count, section: 0), at: .bottom, animated: true)
        comments.append(newComment)
        post = updatedPost
        postTableView.reloadData()
    }
        
    func validateAllFields() -> Bool {
        return commentTextView.text != ""
    }
    
    func clearAllFields() {
        commentTextView.text! = ""
    }
    
}

//MARK: - PostDelegate

extension PostViewController: PostDelegate {
    
    func backgroundDidTapped(post: Post) {
        commentTextView.resignFirstResponder()
    }
    
    func commentDidTapped(post: Post) {
        commentTextView.becomeFirstResponder()
    }
    
}
