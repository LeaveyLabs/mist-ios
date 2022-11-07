//
//  MyActivityViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/10/12.
//

import Foundation
import UIKit

enum SelectedActivityFeed: Int, CaseIterable {
    case mentions, submissions, favorites
    
    var displayName: String {
        switch self {
        case .mentions:
            return "mentions"
        case .submissions:
            return "submissions"
        case .favorites:
            return "favorites"
        }
    }

}

class MyActivityViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navBar: UIView!
    
    var favorites: [Post] {
        PostService.singleton.getFavorites()
    }
    var submissions: [Post] {
        PostService.singleton.getSubmissions()
    }
    var mentions: [Post] {
        PostService.singleton.getMentions()
    }
    
    //Flags
    var isFetchingMorePosts: Bool = false
    
    //PostDelegate
    var keyboardHeight: CGFloat = 0 //emoji keyboard autodismiss flag
    var isKeyboardForEmojiReaction: Bool = false
    var reactingPostIndex: Int? //for scrolling to the right index on the feed when react keyboard raises

    var selectedActivityFeed: SelectedActivityFeed = .mentions
    var rerenderProfileCallback: (() -> Void)?
    var navTitle: String {
        UserService.singleton.getUsername()
    }
        
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNibs()
        setupTableView()
        navigationItem.title = navTitle
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)), style: .plain, target: self, action: #selector(cancelButtonDidPressed(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)), style: .plain, target: self, action: #selector(ellipsisButtonDidPressed(_:)))
        navBar.applyLightBottomOnlyShadow()
        
        //TODO: display the number of mentions to the right of "mentions" on the posts and on the top bar
        DeviceService.shared.didViewMentions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadAllData()
        registerKeyboardObservers()
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func registerKeyboardObservers() {
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func reloadAllData() {
        tableView.reloadData()
        navigationItem.title = navTitle
    }
    
    //MARK: - Setup
    
    func setupTableView() {
        //old
//        tableView.setupTableViewSectionShadows(behindView: view, withBGColor: Constants.Color.offWhite)
//
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.estimatedRowHeight = 50
//        tableView.estimatedSectionFooterHeight = 0
//        tableView.estimatedSectionHeaderHeight = 0
//        if #available(iOS 15.0, *) {
//            tableView.sectionHeaderTopPadding = 0
//            tableView.sectionHeaderHeight = 5
//        }
//        tableView.separatorStyle = .none
//        tableView.rowHeight = UITableView.automaticDimension //necessary when using constraints within cells
        
        //new
        if #available(iOS 15.0, *) {
            tableView.estimatedSectionFooterHeight = 15
            tableView.estimatedSectionHeaderHeight = 110
            tableView.sectionHeaderTopPadding = 20
            tableView.sectionHeaderHeight = 15
        }
        
        tableView.backgroundColor = Constants.Color.offWhite
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 300
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.register(PostCell.self, forCellReuseIdentifier: Constants.SBID.Cell.Post)
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl!.addTarget(self, action: #selector(pullToRefreshFeed), for: .valueChanged)
    }
    
    @objc func pullToRefreshFeed() {
        guard !isFetchingMorePosts else { return }
        isFetchingMorePosts = true

        Task {
            do {
                try await PostService.singleton.loadSubmissions()
                try await PostService.singleton.loadMentions()
            } catch {
                CustomSwiftMessages.displayError(error)
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadData()
                self.tableView.refreshControl?.endRefreshing()
                self.isFetchingMorePosts = false
            }
        }
    }
    
    func registerNibs() {
        let myProfileNib = UINib(nibName: String(describing: ProfileCell.self), bundle: nil)
        tableView.register(myProfileNib, forCellReuseIdentifier: String(describing: ProfileCell.self))
    }
    
    //MARK: - User Interaction
     
    @IBAction func cancelButtonDidPressed(_ sender: UIBarButtonItem) {
        rerenderProfileCallback?()
        dismiss(animated: true)
    }
    
    @IBAction func ellipsisButtonDidPressed(_ sender: UIBarButtonItem) {
        let myAccountVC = storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.MyAccount) as! MyAccountViewController
        navigationController?.pushViewController(myAccountVC, animated: true)
    }

}

//MARK: - Table View DataSource

extension MyActivityViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 2 }
        switch selectedActivityFeed {
        case .mentions:
            return mentions.count
        case .submissions:
            return submissions.count
        case .favorites:
            return favorites.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let profileCell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileCell.self), for: indexPath) as! ProfileCell
                profileCell.configure(profileType: ProfileCell.ProfileType.init(rawValue: indexPath.row)!)
                return profileCell
            } else {
                //create a feed toggle view
                let basicCell = UITableViewCell()
                basicCell.contentView.isUserInteractionEnabled = true
                basicCell.selectionStyle = .none
                let feedToggleView = FeedToggleView(frame: basicCell.bounds)
                basicCell.addSubview(feedToggleView)
                feedToggleView.center.x = view.center.x
//                feedToggleView.center = basicCell.center
                feedToggleView.configure(labelNames: SelectedActivityFeed.allCases.map { $0.displayName }, startingSelectedIndex: selectedActivityFeed.rawValue, delegate: self)
                return basicCell
            }
        } else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
            let post: Post
            switch selectedActivityFeed {
            case .submissions:
                post = submissions[indexPath.row]
            case .favorites:
                post = favorites[indexPath.row]
            case .mentions:
                post = mentions[indexPath.row]
            }
            let _ = cell.configurePostCell(post: post,
                                           nestedPostViewDelegate: self,
                                           bubbleTrianglePosition: .left,
                                           isWithinPostVC: false, canBeSeenOnMap: false)
            cell.contentView.backgroundColor = Constants.Color.offWhite
            return cell
        }
    }
    
    //MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let updateprofileVC = UpdateProfileSettingViewController.create()
                navigationController?.pushViewController(updateprofileVC, animated: true)
            }
        }
    }
    
}

//MARK: - FeedToggleViewDelegate

extension MyActivityViewController: FeedToggleViewDelegate {
    
    func labelDidTapped(index: Int) {
        print("LABEL DID TAPPED")
        selectedActivityFeed = SelectedActivityFeed(rawValue: index)!
        tableView.reloadData()
    }
    
}
