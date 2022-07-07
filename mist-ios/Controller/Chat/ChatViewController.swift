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
    
    let INPUTBAR_PLACEHOLDER = "Message"
    let MAX_MESSAGE_LENGTH = 999
    
    private(set) lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        return refreshControl
    }()
    
//    private lazy var textMessageSizeCalculator: CustomTextLayoutSizeCalculator = CustomTextLayoutSizeCalculator(layout: self.messagesCollectionView.messagesCollectionViewFlowLayout)

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
            messagesCollectionView.reloadData()
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
            messagesCollectionView.reloadData()
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
        
        DispatchQueue.main.async { //scroll on the next cycle so that collectionView's data is loaded in beforehand
            self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController!.setNavigationBarHidden(true, animated: animated)
        self.messagesCollectionView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //if is pushing a view controller
        if !self.isAboutToClose {
            navigationController?.setNavigationBarHidden(false, animated: animated)
            navigationController?.navigationBar.tintColor = .black //otherwise it's blue... idk why
        }
    }
    
    var viewHasAppeared = false
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewHasAppeared = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewHasAppeared = false
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
//        self.messagesCollectionView.register(CustomTextMessageContentCell.self)
        
        messagesCollectionView.refreshControl = refreshControl
        if conversation.hasRenderedAllChatObjects() { refreshControl.removeFromSuperview() }
        
        scrollsToLastItemOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        showMessageTimestampOnSwipeLeft = true // default false
        additionalBottomInset = 8
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
        
        //We want to start with the messageInputBar's textView as first responder
        //But for some reason, without this delay, self (the VC) remains the first responder
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.messageInputBar.inputTextView.becomeFirstResponder()
        }
    }
    
    func setupMessageInputBarForChatting() {
        messageInputBar.separatorLine.isHidden = false
        messageInputBar.layer.shadowOpacity = 0

        messageInputBar.inputTextView.tintColor = mistUIColor()
        messageInputBar.inputTextView.placeholder = INPUTBAR_PLACEHOLDER
        messageInputBar.sendButton.setTitleColor(mistUIColor(), for: .normal)
        messageInputBar.inputTextView.delegate = self
        messageInputBar.inputTextView.font = UIFont(name: Constants.Font.Medium, size: 18)
        
        messageInputBar.setMiddleContentView(messageInputBar.inputTextView, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 52, animated: false)
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
                           isSangdaebangHidden: isSangdaebangProfileHidden,
                           isEnabled: messageKitMatch.matchRequest.read_only_post != nil)
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
        return NSAttributedString(string: "Sent", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isTimeLabelVisible(at: indexPath) {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        }
        return nil
    }
    
//    func textCell(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell? {
//        let cell = messagesCollectionView.dequeueReusableCell(CustomTextMessageContentCell.self, for: indexPath)
//        cell.configure(with: message,
//                       at: indexPath,
//                       in: messagesCollectionView,
//                       dataSource: self,
//                       and: self.textMessageSizeCalculator)
//        return cell
//    }
}

// MARK: - InputBarDelegate

extension ChatViewController: InputBarAccessoryViewDelegate {

    @objc
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        processInputBar(messageInputBar)
    }
    
    func processInputBar(_ inputBar: InputBarAccessoryView) {
        let messageString = inputBar.inputTextView.attributedText.string.trimmingCharacters(in: .whitespaces)
        inputBar.inputTextView.text = String()
        inputBar.sendButton.startAnimating()
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
    
    //TODO: will this properly handle the case when we get, say, three messages in the thread all at once? or when they send a matchrequest and a message at the same time?
    func handleNewMessage() {
        messageInputBar.sendButton.stopAnimating()

        // Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([numberOfSections(in: messagesCollectionView) - 1])
            if numberOfSections(in: messagesCollectionView) >= 2 {
                messagesCollectionView.reloadSections([numberOfSections(in: messagesCollectionView) - 2])
            }
        })
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
        guard let post = PostService.singleton.getConversationPost(withPostId: postId) else { return }
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
                    self?.messagesCollectionView.scrollToLastItem(animated: false)
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
        return isFromCurrentSender(message: message) ? .bubbleOutline(.lightGray.withAlphaComponent(0.5)) : .bubble
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
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isTimeLabelVisible(at: indexPath) ? 50 : 0
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isFromCurrentSender(message: message) && isLastMessage(at: indexPath) ? 16 : 0
    }
        
//    func textCellSizeCalculator(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CellSizeCalculator? {
//        return self.textMessageSizeCalculator
//    }
    
}

//MARK: - ScrollViewDelegate

extension ChatViewController {
    
    override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        print("Why is this not being called?")
    }
    
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
    
}

// MARK: - MessageLabelDelegate

extension ChatViewController: MessageLabelDelegate {
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
}

// MARK: - Helpers

extension ChatViewController {
    
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


private func nextIndexPath(for currentIndexPath: IndexPath, in tableView: UICollectionView) -> IndexPath? {
    var nextRow = 0
    var nextSection = 0
    var iteration = 0
    var startRow = currentIndexPath.row
    for section in currentIndexPath.section ..< tableView.numberOfSections {
        nextSection = section
        for row in startRow ..< tableView.numberOfItems(inSection: section) {
            nextRow = row
            iteration += 1
            if iteration == 2 {
                let nextIndexPath = IndexPath(row: nextRow, section: nextSection)
                return nextIndexPath
            }
        }
        startRow = 0
    }

    return nil
}
