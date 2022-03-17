//
//  PostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit

let COMMENT_PLACEHOLDER_TEXT = "wait this is so..."
typealias UpdatedPostCompletionHandler = ((Post) -> Void)

class PostViewController: KUIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var commentProfileImage: UIImageView!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var commentButton: UIButton!
    var commentPlaceholderLabel: UILabel!

    @IBOutlet weak var postTableView: UITableView!
    var completionHandler: UpdatedPostCompletionHandler?
    
    //postVC should never be created without a post
    var post: Post!
    var comments: [Comment]?
    
    override func viewDidLoad() {
        super.viewDidLoad();
        postTableView.estimatedRowHeight = 100;
        postTableView.rowHeight = UITableView.automaticDimension; // is this necessary?
        
        //we are choosing to leave out this functionality for now
        //postTableView.keyboardDismissMode = .onDrag
        
        //below code is not needed with KUIViewController
        //commentTextView.inputAccessoryView = commentView

        postTableView.delegate = self;
        postTableView.dataSource = self;
        commentTextView.delegate = self;
        commentProfileImage.layer.cornerRadius = commentProfileImage.frame.size.height / 2
        commentProfileImage.layer.cornerCurve = .continuous
        commentView.borders(for: [UIRectEdge.top])
        
        //(1 of 2) for enabling swipe left to go back with a bar button item
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self;
        
        disableCommentButton()
        commentTextView.layer.borderWidth = 1
        commentTextView.layer.borderColor = UIColor.lightGray.cgColor
        commentTextView.layer.cornerRadius = 15
        commentTextView.textContainer.lineFragmentPadding = 0
        commentTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        let postNib = UINib(nibName: Constants.SBID.Cell.Post, bundle: nil);
        postTableView.register(postNib, forCellReuseIdentifier: Constants.SBID.Cell.Post);
        let commentNib = UINib(nibName: Constants.SBID.Cell.Comment, bundle: nil);
        postTableView.register(commentNib, forCellReuseIdentifier: Constants.SBID.Cell.Comment);
        
        //add placeholder text to messageTextView
        commentPlaceholderLabel = UILabel()
        commentPlaceholderLabel.text = COMMENT_PLACEHOLDER_TEXT
        commentPlaceholderLabel.font = commentTextView.font
        commentPlaceholderLabel.sizeToFit()
        commentTextView.addSubview(commentPlaceholderLabel)
        commentPlaceholderLabel.frame.origin = CGPoint(x: 10, y: 10)
        commentPlaceholderLabel.textColor = UIColor.placeholderText
        commentPlaceholderLabel.isHidden = !commentTextView.text.isEmpty
        
        
        loadComments();
        
        let labelTap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        view.addGestureRecognizer(labelTap)
    }
    
    //create a postVC for a given post. postVC should never exist without a post
    class func createPostVCForPost(_ post: Post) -> PostViewController {
        let postVC =
        UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Post) as! PostViewController
        postVC.post = post
        return postVC
    }
    
    //(2 of 2) for enabling swipe left to go back with a bar button item
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
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
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        commentTextView.resignFirstResponder()
    }
    
    @IBAction func sortButtonDidPressed(_ sender: UIButton) {
        //customize sheet size before presenting
        //https://developer.apple.com/videos/play/wwdc2021/10063/
        let sortByVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.SortBy) as! SortByViewController
        if let sheet = sortByVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        present(sortByVC, animated: true, completion: nil)
    }
    
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
    
    func loadComments() {
        Task {
            do {
                comments = try await CommentAPI.fetchComments(postID: post.id)
                print("loaded comments")
                postTableView.reloadData();
            } catch {
                print(error)
            }
        }
    }

    // MARK: -TableView Data Source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let comments = comments {
            return comments.count + 2
        }
        else {
            return 2;
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row == 0) {
            if let post = post {
                let cell = postTableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
                cell.configurePostCell(post: post, parent: self)
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                return cell
            }
        } else if (indexPath.row == 1) {
            let cell = postTableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Sort, for: indexPath)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell;
        }
        //else the cell is a comment
        let cell = postTableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Comment, for: indexPath) as! CommentCell
        cell.configureCommentCell(comment: comments![indexPath.row-2], parent: self)
        return cell
    }
    
    @IBAction func submitButtonDidPressed(_ sender: UIButton) {
        print("submti!")
        Task {
            do {
                let newComment = Comment(id: String(NSUUID().uuidString.prefix(10)), text: commentTextView!.text, timestamp: currentTimeMillis(), post: post.id, author: "kevinsun")
                try await CommentAPI.postComment(comment: newComment)
                comments?.append(newComment)
                commentTextView!.text = ""
                post.commentcount += 1
                postTableView.reloadData()
            } catch {
                print(error)
            }
        }
    }
    
    
    // MARK: - TableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("post was tapped")
    }
    
    //MARK: -Helpers
    
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
