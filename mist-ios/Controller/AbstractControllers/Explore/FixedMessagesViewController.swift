//
//  FixedMessagesViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/13/22.
//

import UIKit
import MessageKit
import InputBarAccessoryView

class FixedMessagesViewController: MessagesViewController {
    
    //MARK: - Propreties
    
    //We are using the subview rather than the first responder approach
    override var canBecomeFirstResponder: Bool { return false }
    
    override var inputAccessoryView: UIView?{
        return nil //this should be "messageInputBar" according to the docs, but then i was dealing with other problems. Instead, i just increased the bottom tableview inset by 43 points. The problem: when dismissing the chat view, the bottom message scrolls behind the keyboard. That's a downside im willing to take right now
    }
    let keyboardManager = KeyboardManager()
    
    let INPUTBAR_PLACEHOLDER = "Message"
    let MAX_MESSAGE_LENGTH = 999
    
    private(set) lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        return refreshControl
    }()
    
    //UI
    @IBOutlet weak var senderProfilePicButton: UIButton!
    @IBOutlet weak var senderProfileNameButton: UIButton!
    @IBOutlet weak var receiverProfilePicButton: UIButton!
    @IBOutlet weak var receiverProfileNameButton: UIButton!
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var customNavigationBar: UIView!
    
    //Data
    var conversation: Conversation!

    //Flags
    var isPresentedFromPost: Bool = false
        
    var isAuthedUserProfileHidden: Bool! {
        didSet {
            senderProfileNameButton.setTitle("You", for: .normal)
            if isAuthedUserProfileHidden {
                senderProfilePicButton.imageView?.becomeProfilePicImageView(with: UserService.singleton.getBlurredPic())
            } else {
                senderProfilePicButton.imageView?.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
            }
        }
    }
    var isSangdaebangProfileHidden: Bool! {
        didSet {
            if isSangdaebangProfileHidden {
                receiverProfilePicButton.imageView?.becomeProfilePicImageView(with: conversation.sangdaebang.blurredPic)
                receiverProfileNameButton.setTitle("???", for: .normal)
            } else {
                receiverProfilePicButton.imageView?.becomeProfilePicImageView(with: conversation.sangdaebang.profilePic)
                receiverProfileNameButton.setTitle(conversation.sangdaebang.first_name, for: .normal)
            }
        }
    }
    
    //MARK: - Initialization
    
    class func createFromPost(postId: Int, postAuthor: FrontendReadOnlyUser, postTitle: String) -> ChatViewController {
        let chatVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Chat) as! ChatViewController
        chatVC.conversation = ConversationService.singleton.getConversationWith(userId: postAuthor.id) ?? ConversationService.singleton.openConversationWith(user: postAuthor)
        chatVC.conversation.openConversationFromPost(postId: postId, postTitle: postTitle)
        chatVC.isPresentedFromPost = true
        return chatVC
    }
    
    class func create(conversation: Conversation) -> ChatViewController {
        let chatVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Chat) as! ChatViewController
        chatVC.conversation = conversation
        chatVC.conversation.openConversation()
        return chatVC
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: CustomMessagesFlowLayout()) //for registering custom MessageSizeCalculator for MessageKitMatch
        super.viewDidLoad()
        setupMessagesCollectionView()
        setupCustomNavigationBar()
        setupHiddenProfiles() //must come after setting up the data
        if isAuthedUserProfileHidden {
            setupMessageInputBarForChatPrompt()
        } else {
            setupMessageInputBarForChatting()
        }
        if isPresentedFromPost {
            setupWhenPresentedFromPost()
        }
        
//        messagesCollectionView.directionalPressGestureRecognizer.allowedPressTypes
        
        //Keyboard manager from InputBarAccessoryView
        view.addSubview(messageInputBar)
        keyboardManager.shouldApplyAdditionBottomSpaceToInteractiveDismissal = true
        keyboardManager.bind(inputAccessoryView: messageInputBar) //properly positions inputAccessoryView
        keyboardManager.bind(to: messagesCollectionView) //enables interactive dismissal
        
        DispatchQueue.main.async { //scroll on the next cycle so that collectionView's data is loaded in beforehand
            self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController!.setNavigationBarHidden(true, animated: animated)
        print("CHAT VIEW WILL APPEAR")
        messagesCollectionView.reloadDataAndKeepOffset()
    }
    
    var viewHasAppeared = false
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewHasAppeared = true
        enableInteractivePopGesture()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //if is pushing a view controller
        if !self.isAboutToClose {
            navigationController?.setNavigationBarHidden(false, animated: animated)
            navigationController?.navigationBar.tintColor = .black //otherwise it's blue... idk why
        }
        
        messageInputBar.inputTextView.resignFirstResponder() //better ui animation
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewHasAppeared = false
        disableInteractivePopGesture()
    }
    
    //    //(2 of 2) Enable swipe left to go back with a bar button item
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    
    //MARK: - Setup
    
    func setupMessagesCollectionView() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.delegate = self
        messageInputBar.delegate = self
                
        let matchNib = UINib(nibName: String(describing: MatchCollectionCell.self), bundle: nil)
        messagesCollectionView.register(matchNib, forCellWithReuseIdentifier: String(describing: MatchCollectionCell.self))
        let infoNib = UINib(nibName: String(describing: InformationCollectionCell.self), bundle: nil)
        messagesCollectionView.register(infoNib, forCellWithReuseIdentifier: String(describing: InformationCollectionCell.self))
        
        messagesCollectionView.refreshControl = refreshControl
        if conversation.hasRenderedAllChatObjects() { refreshControl.removeFromSuperview() }
        
        scrollsToLastItemOnKeyboardBeginsEditing = true // default false
//        maintainPositionOnKeyboardFrameChanged = true // default false. this was causing a weird snap when scrolling the keyboard down
//        showMessageTimestampOnSwipeLeft = true // default false
//        additionalBottomInset = 8
        additionalBottomInset = 51
        print(keyboardManager.shouldApplyAdditionBottomSpaceToInteractiveDismissal)
        keyboardManager.shouldApplyAdditionBottomSpaceToInteractiveDismissal = true
    }
    
    func setupCustomNavigationBar() {
        navigationController?.isNavigationBarHidden = true
        customNavigationBar.applyLightBottomOnlyShadow()
        view.sendSubviewToBack(messagesCollectionView)
        
        //Remove top constraint which was set in super's super, MessagesViewController. Then, add a new one.
        view.constraints.first { $0.firstAnchor == messagesCollectionView.topAnchor }!.isActive = false
        messagesCollectionView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 5).isActive = true
    }
        
    func setupHiddenProfiles() {
        isSangdaebangProfileHidden = conversation.isSangdaebangHidden
        isAuthedUserProfileHidden = conversation.isAuthedUserHidden
    }
    
    func setupWhenPresentedFromPost() {
        xButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    func setupMessageInputBarForChatting() {
        //iMessage
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 36)
        messageInputBar.separatorLine.height = 0
        
        //Center
        messageInputBar.inputTextView.layer.borderWidth = 0.5
        messageInputBar.inputTextView.layer.borderColor = UIColor.systemGray4.cgColor
        messageInputBar.inputTextView.tintColor = mistUIColor()
        messageInputBar.inputTextView.backgroundColor = .lightGray.withAlphaComponent(0.1)
        messageInputBar.inputTextView.layer.cornerRadius = 16.0
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        messageInputBar.inputTextView.placeholder = INPUTBAR_PLACEHOLDER
        messageInputBar.shouldAnimateTextDidChangeLayout = true
        messageInputBar.maxTextViewHeight = 144 //max of 6 lines with the given font
        messageInputBar.setMiddleContentView(messageInputBar.inputTextView, animated: false)


        //Right
        messageInputBar.setRightStackViewWidthConstant(to: 38, animated: false)
        messageInputBar.sendButton.setSize(CGSize(width: 36, height: 36), animated: false)
        messageInputBar.setStackViewItems([messageInputBar.sendButton, InputBarButtonItem.fixedSpace(2)], forStack: .right, animated: false)
        messageInputBar.sendButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 4, right: 2)
        messageInputBar.sendButton.setImage(UIImage(named: "enabled-send-button"), for: .normal)
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.becomeRound()
    }
    
    func setupMessageInputBarForChatPrompt() {
        let joinChatView = WantToChatView()
        joinChatView.configure(firstName: conversation.sangdaebang.first_name, delegate: self)
        
        messageInputBar.layer.shadowColor = UIColor.black.cgColor
        messageInputBar.layer.shadowRadius = 4
        messageInputBar.layer.shadowOpacity = 0.3
        messageInputBar.layer.shadowOffset = CGSize(width: 0, height: 0)
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.setRightStackViewWidthConstant(to: 0, animated: false)
        
        messageInputBar.setMiddleContentView(joinChatView, animated: false)
    }
    
    //MARK: - User Interaction

    @IBAction func xButtonDidPressed(_ sender: UIButton) {
        customDismiss()
    }
    
    func customDismiss() {
        if isPresentedFromPost {
            messageInputBar.inputTextView.resignFirstResponder()
            self.resignFirstResponder() //to prevent the inputAccessory from staying on the screen after dismiss
            self.dismiss(animated: true)
            if conversation.messageThread.server_messages.isEmpty {
                ConversationService.singleton.closeConversationWith(userId: conversation.sangdaebang.id)
            }
            //if the placeholder matchrequest is still in place,
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func senderProfileDidTapped(_ sender: UIButton) {
        if isAuthedUserProfileHidden {
            //do nothing for now
        } else {
            let profileVC = ProfileViewController.create(for: UserService.singleton.getUserAsFrontendReadOnlyUser())
            navigationController!.present(profileVC, animated: true)
        }
    }
    
    @IBAction func receiverProfileDidTapped(_ sender: UIButton) {
        handleReceiverProfileDidTapped()
    }
    
    func handleReceiverProfileDidTapped() {
        if isSangdaebangProfileHidden {
            //somehow tell the user //hey! they're hidden right now!
        } else {
            let profileVC = ProfileViewController.create(for: conversation.sangdaebang)
            navigationController!.present(profileVC, animated: true)
        }
    }
    
    @IBAction func moreButtonDidTapped(_ sender: UIButton) {
        let moreVC = ChatMoreViewController.create(sangdaebangId: conversation.sangdaebang.id, delegate: self)
//        messageInputBar.inputTextView.resignFirstResponder() //we need a "resign first responder and keep offset" function
        present(moreVC, animated: true)
    }
    
    // MARK: - UICollectionViewDataSource
    
    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("Ouch. nil data source for messages")
        }

        // Very important to check this when overriding `cellForItemAt`
        // Super method will handle returning the typing indicator cell
        guard !isSectionReservedForTypingIndicator(indexPath.section) else {
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        }

        if let messageKitMatch = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as? MessageKitMatchRequest {
            let cell = messagesCollectionView.dequeueReusableCell(MatchCollectionCell.self, for: indexPath)
            cell.configure(with: messageKitMatch,
                           sangdaebang: conversation.sangdaebang,
                           delegate: self,
                           isSangdaebangHidden: isSangdaebangProfileHidden)
            return cell
        }
        if let messageKitInfo = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as? MessageKitInfo {
            let cell = messagesCollectionView.dequeueReusableCell(InformationCollectionCell.self, for: indexPath)
            cell.configure(with: messageKitInfo)
            return cell
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
}

//MARK: - MessagesDataSource

extension FixedMessagesViewController: MessagesDataSource {
    
    func currentSender() -> SenderType {
        return UserService.singleton.getUserAsFrontendReadOnlyUser()
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return conversation.getRenderedChatObjects().count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return conversation.getRenderedChatObjects()[indexPath.section]
    }

    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isLastMessageFromSender(message: message, at: indexPath) {
            return NSAttributedString(string: "Sent", attributes: [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 11)!, NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        }
        return nil
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isTimeLabelVisible(at: indexPath) {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 11)!, NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        }
        return nil
    }
}

// MARK: - InputBarDelegate

extension FixedMessagesViewController: InputBarAccessoryViewDelegate {
    
    func accessoryViewRemovedFromSuperview() {
        print("HI")
    }
    
    @objc
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        processInputBar(messageInputBar)
    }
    
    func processInputBar(_ inputBar: InputBarAccessoryView) {
        let messageString = inputBar.inputTextView.attributedText.string.trimmingCharacters(in: .whitespaces)
        inputBar.inputTextView.text = String()
        inputBar.sendButton.isEnabled = false
        messageInputBar.inputTextView.placeholder = INPUTBAR_PLACEHOLDER
        Task {
            do {
                try await conversation.sendMessage(messageText: messageString)
                DispatchQueue.main.async { [weak self] in
                    self?.handleNewMessage()
                }
            } catch {
                CustomSwiftMessages.displayError(error)
            }
        }
    }
    
    func handleNewMessage() {
        isAuthedUserProfileHidden = conversation.isAuthedUserHidden
        if isSangdaebangProfileHidden && !conversation.isSangdaebangHidden {
            //Don't insert a new section, simply reload the data. This is because even though we're handling a new message, we're also removing the last placeholder "info" message, so we shouldn't insert any sections
            messagesCollectionView.reloadData()
            isSangdaebangProfileHidden = conversation.isSangdaebangHidden
        } else {
            // Reload last section to update header/footer labels and insert a new one
            messagesCollectionView.performBatchUpdates({
                messagesCollectionView.insertSections([numberOfSections(in: messagesCollectionView) - 1])
                if numberOfSections(in: messagesCollectionView) >= 2 {
                    messagesCollectionView.reloadSections([numberOfSections(in: messagesCollectionView) - 2])
                }
            })
            
        }
        messagesCollectionView.scrollToLastItem(animated: true)
    }
    
}

//MARK: - ChatMoreDelegate

extension FixedMessagesViewController: ChatMoreDelegate {
    
    func handleSuccessfulBlock() {
        customDismiss()
    }
    
}

//MARK: - MatchRequestCellDelegate

extension FixedMessagesViewController: MatchRequestCellDelegate {
    
    func matchRequestCellDidTapped(postId: Int) {
        guard let post = PostService.singleton.getPost(withPostId: postId) else { return }
        let postVC = PostViewController.createPostVC(with: post, shouldStartWithRaisedKeyboard: false, completionHandler: nil)
        navigationController!.pushViewController(postVC, animated: true)
    }
    
}

//MARK: - WantToChatDelegate

extension FixedMessagesViewController: WantToChatDelegate {
    
    func handleAccept(_ acceptButton: UIButton) {
        Task {
            do {
                acceptButton.configuration?.showsActivityIndicator = true
                try await conversation.sendAcceptingMatchRequest()
                DispatchQueue.main.async { [weak self] in
                    self?.setupMessageInputBarForChatting()
                    self?.isAuthedUserProfileHidden = false
                    DispatchQueue.main.async { [weak self] in
                        //should happen on the next frame, after the input bar is changed
                        self?.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
                    }
                }
            } catch {
                CustomSwiftMessages.displayError(error)
            }
            acceptButton.configuration?.showsActivityIndicator = false
        }
    }
    
    func handleIgnore() {
        customDismiss()
    }
    
    func handleBlock(_ blockButton: UIButton) {
        CustomSwiftMessages.showBlockPrompt { [self] didBlock in
            if didBlock {
                Task {
                    do {
                        blockButton.configuration?.showsActivityIndicator = true
                        try await BlockService.singleton.blockUser(conversation.sangdaebang.id)
                        blockButton.configuration?.showsActivityIndicator = false
                        DispatchQueue.main.async {
                            self.customDismiss()
                        }
                    } catch {
                        CustomSwiftMessages.displayError(error)
                    }
                }
            }
        }
    }
    
}

//MARK: - UITextViewDelegate

extension FixedMessagesViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return textView.shouldChangeTextGivenMaxLengthOf(MAX_MESSAGE_LENGTH, range, text)
    }
}


// MARK: - MessagesDisplayDelegate

extension FixedMessagesViewController: MessagesDisplayDelegate {
        
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        return MessageLabel.defaultAttributes
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date]
    }
        
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .lightGray.withAlphaComponent(0.25)
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        //The default message content view has uneven padding which can't be set by the open interface 😒
        //Fix it here
        
        ///if the message is not positioned correctly, then make the following edits
        ///options:
        ///only do this on the very first load of the VC
        ///only do this on the very first render of the view ooooh i like this
        /// if the view's cornerRadius is not 16.1
        
//        print("MESSAGE STYLE FUNCTION")
        
        return .custom { view in
            guard let messageLabel = view.subviews[0] as? MessageLabel else { return }
            if self.isFromCurrentSender(message: message) {
                view.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
                view.layer.borderWidth = 1
                messageLabel.center = CGPoint(x: messageLabel.center.x, y: messageLabel.center.y)
            } else {
                view.layer.borderColor = UIColor.clear.cgColor
                view.layer.borderWidth = 0
                messageLabel.center = CGPoint(x: messageLabel.center.x - 3, y: messageLabel.center.y)
            }
            
            //Only perform these positioning updates again if they were not already performed once
//            if view.layer.cornerRadius == 16.1 {
                view.layer.cornerCurve = .continuous
                view.layer.cornerRadius = 16.1
                view.frame.size.width -= 4
//            }
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let nextIndexPath = IndexPath(item: 0, section: indexPath.section+1)
        avatarView.isHidden = isNextMessageSameSender(at: indexPath) && !isTimeLabelVisible(at: nextIndexPath)
        let theirPic = isSangdaebangProfileHidden ? conversation.sangdaebang.blurredPic : conversation.sangdaebang.profilePic
        avatarView.set(avatar: Avatar(image: theirPic, initials: ""))
    }

}

// MARK: - MessagesLayoutDelegate

extension FixedMessagesViewController: MessagesLayoutDelegate {
    
    //TODO: Can we delete these now that we have customcalculator?
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isTimeLabelVisible(at: indexPath) ? 50 : 0
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isLastMessageFromSender(message: message, at: indexPath) ? 16 : 0
    }
    
}

//MARK: - ScrollViewDelegate

extension FixedMessagesViewController {
    
    override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        print("Why is this not being called?")
    }
    
    //Refreshes new messages when you reach the top
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 && !refreshControl.isRefreshing && !conversation.hasRenderedAllChatObjects() && viewHasAppeared && refreshControl.isEnabled {
            refreshControl.beginRefreshing()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                conversation.userWantsToSeeMoreMessages()
                messagesCollectionView.reloadDataAndKeepOffset()
                refreshControl.endRefreshing()
                if conversation.hasRenderedAllChatObjects() { refreshControl.removeFromSuperview() }
                refreshControl.isEnabled = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
                    refreshControl.isEnabled = true //prevent another immediate reload
                }
            }
        }
    }
    
}


// MARK: - MessageCellDelegate

extension FixedMessagesViewController: MessageCellDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        handleReceiverProfileDidTapped()
    }
    
}

// MARK: - MessageLabelDelegate

extension FixedMessagesViewController: MessageLabelDelegate {
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
}

// MARK: - Helpers

extension FixedMessagesViewController {
    
    func isLastMessageFromSender(message: MessageType, at indexPath: IndexPath) -> Bool {
        let startingIndex = indexPath.section
        if startingIndex > conversation.chatObjects.count { return false }
        if startingIndex == conversation.chatObjects.count {
            return isFromCurrentSender(message: message)
        }
        if !isFromCurrentSender(message: message) { return false } //make sure this message if from current sender
        //make sure all later messages are NOT from the current sender
        for index in startingIndex+1..<conversation.chatObjects.count {
            if let message = conversation.chatObjects[index] as? MessageKitMessage {
                if isFromCurrentSender(message: message) {
                    return false
                }
            }
        }
        return true
    }
    
    func isLastMessage(at indexPath: IndexPath) -> Bool {
        let isInfoCellVisible = conversation.isSangdaebangHidden
        if isInfoCellVisible {
            return indexPath.section == numberOfSections(in: messagesCollectionView) - 2
        } else {
            return indexPath.section == numberOfSections(in: messagesCollectionView) - 1
        }
    }
        
    func isLastSectionVisible() -> Bool {
        guard numberOfSections(in: messagesCollectionView) != 0 else { return false }
        let lastIndexPath = IndexPath(item: 0, section: numberOfSections(in: messagesCollectionView) - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        guard indexPath.section > 0 else {
            return conversation.hasRenderedAllChatObjects()
        }
        let previousIndexPath = IndexPath(item: 0, section: indexPath.section-1)
        let previousItem = messageForItem(at: previousIndexPath, in: messagesCollectionView)
        let thisItem = messageForItem(at: indexPath, in: messagesCollectionView)
        let elapsedTimeSincePreviousMessage =  thisItem.sentDate.timeIntervalSince1970.getElapsedTime(since: previousItem.sentDate.timeIntervalSince1970)
        if elapsedTimeSincePreviousMessage.hours > 0 {
            return true
        }
        return false
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section > 0 else { return false }
        let previousIndexPath = IndexPath(item: 0, section: indexPath.section-1)
        let previousItem = messageForItem(at: previousIndexPath, in: messagesCollectionView)
        let thisItem = messageForItem(at: indexPath, in: messagesCollectionView)
        return thisItem.sender.senderId == previousItem.sender.senderId
    }

    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < numberOfSections(in: messagesCollectionView) else { return false }
        let nextIndexPath = IndexPath(item: 0, section: indexPath.section+1)
        let nextItem = messageForItem(at: nextIndexPath, in: messagesCollectionView)
        let thisItem = messageForItem(at: indexPath, in: messagesCollectionView)
        return thisItem.sender.senderId == nextItem.sender.senderId
    }
}

