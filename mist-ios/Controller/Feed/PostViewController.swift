//
//  PostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit

let COMMENT_PLACEHOLDER_TEXT = "wait this is so..."

class PostViewController: KUIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIViewControllerTransitioningDelegate {
    
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var commentProfileImage: UIImageView!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var commentButton: UIButton!
    var commentPlaceholderLabel : UILabel!

    @IBOutlet weak var postTableView: UITableView!
    var post: Post?
    var comments: [Comment]?
    var pvc: UIViewController?
    
    
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
        
        disableCommentButton()
        commentTextView.layer.borderWidth = 1
        commentTextView.layer.borderColor = UIColor.lightGray.cgColor
        commentTextView.layer.cornerRadius = 15
        commentTextView.textContainer.lineFragmentPadding = 0
        commentTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        let postNib = UINib(nibName: "PostCell", bundle: nil);
        postTableView.register(postNib, forCellReuseIdentifier: "PostCell");
        let commentNib = UINib(nibName: "CommentCell", bundle: nil);
        postTableView.register(commentNib, forCellReuseIdentifier: "CommentCell");
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        print("tap2")
//        commentTextView.resignFirstResponder()
        pvc?.dismiss(animated: true)
    }
    
    @IBAction func sortButtonDidPressed(_ sender: UIButton) {
        //customize sheet size before presenting
        //https://developer.apple.com/videos/play/wwdc2021/10063/
        let sortByVC = self.storyboard!.instantiateViewController(withIdentifier: "sortByVC") as! SortByViewController

        if let sheet = sortByVC.sheetPresentationController {
            sheet.detents = [.medium()]

            sheet.prefersScrollingExpandsWhenScrolledToEdge = false

            //below line allows you to scroll behind the vc
//            sheet.largestUndimmedDetentIdentifier = .medium
            
//            sortByVC.containingView.layer.cornerRadius = 24
            sheet.preferredCornerRadius = 40
        
//        WAIT isntead of doing below, just set background view to be clear, then add a view on top of it
            //allows you to customize width
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
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
                comments = try await CommentAPI.fetchComments(postID: post!.id)
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
                let cell = postTableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
                cell.parentViewController = self
                cell.timestampLabel.text = getFormattedTimeString(postTimestamp: post.timestamp)
                cell.locationLabel.text = post.location
                cell.messageLabel.text = post.text
                cell.titleLabel.text = post.title
                return cell
            }
        } else if (indexPath.row == 1) {
            let cell = postTableView.dequeueReusableCell(withIdentifier: "sortButton", for: indexPath)
            return cell;
        }
        
        //else the cell is a comment
        let cell = postTableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
        let comment = comments![indexPath.row-2]
        cell.timestampLabel.text = getFormattedTimeString(postTimestamp: comment.timestamp)
        cell.authorLabel.text = comment.author
        cell.commentLabel.text = comment.text
        cell.authorProfileImageView.image = UIImage(named: "pic4")
        return cell
    }
    
    @IBAction func submitButtonDidPressed(_ sender: UIButton) {
        print("submti!")
        Task {
            do {
                let newComment = Comment(id: String(NSUUID().uuidString.prefix(10)), text: commentTextView!.text, timestamp: currentTimeMillis(), post: post!.id, author: "kevinsun")
                try await CommentAPI.postComment(comment: newComment)
                comments?.append(newComment)
                commentTextView!.text = ""
                
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
