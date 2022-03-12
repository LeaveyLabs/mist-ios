//
//  PostViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit

class PostViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var commentProfileImage: UIImageView!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var postTableView: UITableView!
    var post: Post?
    var comments: [Comment]?
    
    override func viewDidLoad() {
        super.viewDidLoad();
        postTableView.estimatedRowHeight = 100;
        postTableView.rowHeight = UITableView.automaticDimension; // is this necessary?
        commentTextView.inputAccessoryView = commentView
        postTableView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag

        
        postTableView.delegate = self;
        postTableView.dataSource = self;
        commentProfileImage.layer.cornerRadius = commentProfileImage.frame.size.width / 2
        commentView.borders(for: [UIRectEdge.top])

        let nib = UINib(nibName: "PostCell", bundle: nil);
        postTableView.register(nib, forCellReuseIdentifier: "PostCell");
        print(post!)
        loadPost();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
    }
    
    func loadPost() {
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
        return 1;
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
}
