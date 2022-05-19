//
//  PostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit

let COMMENT_PLACEHOLDER_TEXT = "wait this is so..."
typealias UpdatedPostCompletionHandler = ((Post) -> Void)

//TODO: set KUIViewController to bottom of safe area, rather than bottom of the view
//TODO: add tapgesturerecognizer to postView so that the keyboard dismisses

class PostViewController: KUIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var commentProfileImage: UIImageView!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var commentButton: UIButton!
    var commentPlaceholderLabel: UILabel!
    var indicator = UIActivityIndicatorView()
    
    @IBOutlet weak var postTableView: UITableView!
    var completionHandler: UpdatedPostCompletionHandler?
    
    //postVC should never be created without a post
    var post: Post!
    var comments: [Comment] = []
    var shouldStartWithRaisedKeyboard: Bool!
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        setupTableView()
        setupCommentView()
        commentPlaceholderLabel = commentTextView.addAndReturnPlaceholderLabel(withText: COMMENT_PLACEHOLDER_TEXT)
        loadComments();
        disableCommentButton()

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
        postTableView.estimatedRowHeight = 100;
        postTableView.rowHeight = UITableView.automaticDimension; // is this necessary?
        postTableView.delegate = self;
        postTableView.dataSource = self;
        
        let postNib = UINib(nibName: Constants.SBID.Cell.Post, bundle: nil);
        postTableView.register(postNib, forCellReuseIdentifier: Constants.SBID.Cell.Post);
        let commentNib = UINib(nibName: Constants.SBID.Cell.Comment, bundle: nil);
        postTableView.register(commentNib, forCellReuseIdentifier: Constants.SBID.Cell.Comment);
        
        //we are choosing to leave out this functionality for now
        //postTableView.keyboardDismissMode = .onDrag
    }
    
    func setupCommentView() {
        //below code is not needed with KUIViewController
        //commentTextView.inputAccessoryView = commentView

        commentProfileImage.layer.cornerRadius = commentProfileImage.frame.size.height / 2
        commentProfileImage.layer.cornerCurve = .continuous
        
        commentView.borders(for: [UIRectEdge.top])
        
        commentTextView.delegate = self;
        commentTextView.layer.borderWidth = 1
        commentTextView.layer.borderColor = UIColor.lightGray.cgColor
        commentTextView.layer.cornerRadius = 15
        commentTextView.textContainer.lineFragmentPadding = 0
        commentTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    //MARK: - Navigation
    
    //TODO: do we need to implement this in all VCs throughout the app?
    //(2 of 2) for enabling swipe left to go back with a bar button item
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    //MARK: - User Interaction
    
    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        //this function is currently not used nor needed since KUIViewController handles taps for us
        commentTextView.resignFirstResponder()
    }
    
    @IBAction func submitButtonDidPressed(_ sender: UIButton) {
        if (commentTextView.text.isEmpty) { return }
        Task {
            do {
                disableCommentButton()
                let syncedComment = try await UserService.singleton.uploadComment(
                    id: String(NSUUID().uuidString.prefix(10)),
                    text: commentTextView.text,
                    timestamp: currentTimeMillis(),
                    postId: post.id,
                    author: UserService.singleton.getId())
                //If successful
                commentTextView.text = ""
                postTableView.scrollToRow(at: IndexPath(row: comments.count, section: 0), at: .bottom, animated: true)
                commentTextView.resignFirstResponder()
                
                //this should be handled in postservice
                comments.append(syncedComment)
                post.commentcount += 1
                
                postTableView.reloadData()
                print(comments)
                //postTableView.setContentOffset(CGPoint(x: 0, y: CGFloat.greatestFiniteMagnitude), animated: false)
            }
            catch {
                //If failure
                print("\(error)")
            }
            //Whether successful or failure
            enableCommentButton() //i think this executes whether successful or not... need to check by creating a failed comment upload though
        }
    }
    
    //MARK: - Db Calls
    
    func loadComments() {
        Task {
            do {
                comments = try await CommentAPI.fetchComments(postID: post.id)
                print(comments)
                print("loaded comments")
                postTableView.reloadData();
            } catch {
                print(error)
            }
        }
    }
    
    //MARK: - TextView delegate
    
    func textViewDidChange(_ textView: UITextView) {
        commentPlaceholderLabel.isHidden = !commentTextView.text.isEmpty
        if validateAllFields() {
            enableCommentButton()
        } else {
            disableCommentButton()
        }
    }
    
    //dismiss keyboard when user presses "return"
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

    // MARK: - TableView Data Source

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
                cell.configurePostCell(post: post, parent: self, bubbleArrowPosition: .left)
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
    
    
    // MARK: - TableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("post was tapped")
    }
    
    //MARK: - Helpers
    
    func validateAllFields() -> Bool {
        if (commentTextView.text! == "" ) {
            return false
        } else {
            return true;
        }
    }
    
    func clearAllFields() {
        commentTextView.text! = ""
    }
    
    func enableCommentButton() {
        commentButton.isEnabled = true;
        commentButton.alpha = 1;
    }
    
    func disableCommentButton() {
        commentButton.isEnabled = false;
        commentButton.alpha = 0.99;
    }
}
