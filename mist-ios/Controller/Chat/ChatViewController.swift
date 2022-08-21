/*
 MIT License
 
 Copyright (c) 2017-2019 MessageKit
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit
import MessageKit
import InputBarAccessoryView

class ChatViewController: MessagesViewController {
    
    //MARK: - Propreties
    
    //We are using the subview rather than the first responder approach
    override var canBecomeFirstResponder: Bool { return false }
    
    override var inputAccessoryView: UIView?{
        return nil //this should be "messageInputBar" according to the docs, but then i was dealing with other problems. Instead, i just increased the bottom tableview inset by 43 points. The problem: when dismissing the chat view, the bottom message scrolls behind the keyboard. That's a downside im willing to take right now
    }
    let inputBar = InputBarAccessoryView()
    let keyboardManager = KeyboardManager()
    
    var viewHasAppeared = false

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
        
        //Keyboard manager from InputBarAccessoryView
        addKeyboardObservers()
//        view.addSubview(messageInputBar)
//        keyboardManager.shouldApplyAdditionBottomSpaceToInteractiveDismissal = true
//        keyboardManager.bind(inputAccessoryView: messageInputBar) //properly positions inputAccessoryView
//        keyboardManager.bind(to: messagesCollectionView) //enables interactive dismissal
////        messagesCollectionView.insetsLayoutMarginsFromSafeArea
//        messagesCollectionView.contentInset.bottom = 80
//        keyboardManager.on(event: .willShow) { [self] notification in
//        }
//        keyboardManager.on(event: .willHide) { [self] notification in
//            messagesCollectionView.insets = 55 + (window?.safeAreaInsets.bottom ?? 0)
//        }
        
        DispatchQueue.main.async { //scroll on the next cycle so that collectionView's data is loaded in beforehand
            self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: false)
        }
        
        navigationController?.fullscreenInteractivePopGestureRecognizer(delegate: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController!.setNavigationBarHidden(true, animated: animated)
        print("CHAT VIEW WILL APPEAR")
        messagesCollectionView.reloadDataAndKeepOffset()
        if !inputBar.inputTextView.canBecomeFirstResponder {
            inputBar.inputTextView.canBecomeFirstResponder = true //bc we set to false in viewdiddisappear
        }
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewHasAppeared = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        inputBar.inputTextView.resignFirstResponder()
        inputBar.inputTextView.canBecomeFirstResponder = false //so it doesnt become first responder again if the swipe back gesture is cancelled halfway through
//        UIView.animate(withDuration: 0.3, delay: 0) { [self] in
//            messagesCollectionView.contentInset = .init(top: 0, left: 0, bottom: additionalBottomInset, right: 0)
//        }

        //if is pushing a view controller
        if !self.isAboutToClose {
            navigationController?.setNavigationBarHidden(false, animated: animated)
            navigationController?.navigationBar.tintColor = .black //otherwise it's blue... idk why
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewHasAppeared = false
        disableInteractivePopGesture()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isPresentedFromPost {
            inputBar.inputTextView.becomeFirstResponder()
        }
    }
    
    //(2 of 2) Enable swipe left to go back with a bar button item
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
                
        let matchNib = UINib(nibName: String(describing: MatchCollectionCell.self), bundle: nil)
        messagesCollectionView.register(matchNib, forCellWithReuseIdentifier: String(describing: MatchCollectionCell.self))
        let infoNib = UINib(nibName: String(describing: InformationCollectionCell.self), bundle: nil)
        messagesCollectionView.register(infoNib, forCellWithReuseIdentifier: String(describing: InformationCollectionCell.self))
        
        messagesCollectionView.refreshControl = refreshControl
        if conversation.hasRenderedAllChatObjects() { refreshControl.removeFromSuperview() }
        
        scrollsToLastItemOnKeyboardBeginsEditing = true // default false
        showMessageTimestampOnSwipeLeft = true // default false
//        additionalBottomInset = 55 + (window?.safeAreaInsets.bottom ?? 0)
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
    }
    
    func setupMessageInputBarForChatting() {
        inputBar.inputTextView.placeholder = INPUTBAR_PLACEHOLDER
        inputBar.configureForChatting()
        inputBar.delegate = self
        inputBar.inputTextView.delegate = self //does this cause issues? i'm not entirely sure
    }
    
    func setupMessageInputBarForChatPrompt() {
        let joinChatView = WantToChatView()
        joinChatView.configure(firstName: conversation.sangdaebang.first_name, delegate: self)
        inputBar.configureForChatPrompt(chatView: joinChatView)
    }
    
    //MARK: - User Interaction

    @IBAction func xButtonDidPressed(_ sender: UIButton) {
        customDismiss()
    }
    
    func customDismiss() {
        if isPresentedFromPost {
            inputBar.inputTextView.resignFirstResponder()
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
//        inputBar.inputTextView.resignFirstResponder() //we need a "resign first responder and keep offset" function
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

extension ChatViewController: MessagesDataSource {
    
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

extension InputBarAccessoryViewDelegate {
    func accessoryViewRemovedFromSuperview() {
        fatalError("Requries subclass implementation")
    }
}

// MARK: - InputBarDelegate

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func accessoryViewRemovedFromSuperview() {
        print("HI")
    }
    
    @objc
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        processInputBar(inputBar)
    }
    
    func processInputBar(_ inputBar: InputBarAccessoryView) {
        let messageString = inputBar.inputTextView.attributedText.string.trimmingCharacters(in: .whitespaces)
        inputBar.inputTextView.text = String()
        inputBar.sendButton.isEnabled = false
        inputBar.inputTextView.placeholder = INPUTBAR_PLACEHOLDER
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

extension ChatViewController: ChatMoreDelegate {
    
    func handleSuccessfulBlock() {
        customDismiss()
    }
    
}

//MARK: - MatchRequestCellDelegate

extension ChatViewController: MatchRequestCellDelegate {
    
    func matchRequestCellDidTapped(postId: Int) {
        guard let post = PostService.singleton.getPost(withPostId: postId) else { return }
        let postVC = PostViewController.createPostVC(with: post, shouldStartWithRaisedKeyboard: false, completionHandler: nil)
        navigationController!.pushViewController(postVC, animated: true)
    }
    
}

//MARK: - WantToChatDelegate

extension ChatViewController: WantToChatDelegate {
    
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

extension ChatViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return textView.shouldChangeTextGivenMaxLengthOf(MAX_MESSAGE_LENGTH, range, text)
    }
}


// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {
        
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

extension ChatViewController: MessagesLayoutDelegate {
    
    //TODO: Can we delete these now that we have customcalculator?
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isTimeLabelVisible(at: indexPath) ? 50 : 0
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isLastMessageFromSender(message: message, at: indexPath) ? 16 : 0
    }
    
}

//MARK: - ScrollViewDelegate

extension ChatViewController {
    
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

extension ChatViewController: MessageCellDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        handleReceiverProfileDidTapped()
    }
    
    func didTapBackground(in cell: MessageCollectionViewCell) {
        inputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        inputBar.inputTextView.resignFirstResponder()
    }
    
}

// MARK: - MessageLabelDelegate

extension ChatViewController: MessageLabelDelegate {
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
}

// MARK: - Helpers

extension ChatViewController {
    
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
