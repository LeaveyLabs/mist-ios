//
//  PostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit

let COMMENT_PLACEHOLDER_TEXT = "wait this is so..."

//https://stackoverflow.com/questions/29219688/present-modal-view-controller-in-half-size-parent-controller
class HalfSizePresentationController: UIPresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let bounds = containerView?.bounds else { return .zero }
        return CGRect(x: 0, y: bounds.height / 2, width: bounds.width, height: bounds.height / 2)
    }
}


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
        commentView.borders(for: [UIRectEdge.top])
        
        disableCommentButton()
        commentTextView.layer.borderWidth = 1
        commentTextView.layer.borderColor = UIColor.lightGray.cgColor
        commentTextView.layer.cornerRadius = 15
        commentTextView.textContainer.lineFragmentPadding = 0
        commentTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        let nib = UINib(nibName: "PostCell", bundle: nil);
        postTableView.register(nib, forCellReuseIdentifier: "PostCell");
        
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
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        print("tap2")
        pvc?.dismiss(animated: true)
    }
    
    @IBAction func sortButtonDidPressed(sender: AnyObject) {
        commentTextView.resignFirstResponder()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        pvc = storyboard.instantiateViewController(withIdentifier: "asdf")
        pvc!.modalPresentationStyle = .custom
        pvc!.transitioningDelegate = self
        pvc!.view.backgroundColor = .red
        present(pvc!, animated: true)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return HalfSizePresentationController(presentedViewController: presented, presenting: presentingViewController)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
    }
    
//    @IBAction func sortButtonDidPressed(_ sender: UIBarButtonItem) {
//        commentTextView.resignFirstResponder();
//        let vc = storyboard!.instantiateViewController(withIdentifier: "myVCID")
//        vc.modalPresentationStyle = UIModalPresentationStyle;
//        present(vc, animated: true)
//        }
//    }
    
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
        //good notes on managing Tasks:
        //https://www.swiftbysundell.com/articles/the-role-tasks-play-in-swift-concurrency/
//        Task {
//            do {
//                try await PostService.homePosts.newPosts();
//                self.tableView.reloadData();
//            } catch {
//                print(error)
//            }
//        }
    }

    // MARK: -TableView Data Source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return post.number
        return 2;
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
        
        //TODO: handle when there is not a post
        let cell = postTableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        return cell
    }
    
    // MARK: - TableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("post was tapped")
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let postViewController = segue.destination as! PostTableViewController
//        postViewController.post = PostService.homePosts.getPost(at: selectedPostIndex)
//        //postViewController.completionHandler = { Flashcard in self.quotesTableView.reloadData() }
//    }
    
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
