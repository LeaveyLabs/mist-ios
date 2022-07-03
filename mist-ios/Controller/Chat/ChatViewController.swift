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
    var chatObjects = [MessageType]()
    
    let LOAD_MESSAGES_INTERVAL = 50
    private lazy var lastLoadIndex: Int = conversation.messageThread.server_messages.count - 1
    private(set) lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addAction(.init(handler: { [self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                renderMoreMessagesAndMatchRequests()
                messagesCollectionView.reloadDataAndKeepOffset() //what does this do
                refreshControl.endRefreshing()
            }
        }), for: .valueChanged)
        return control
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
    var placeholderMessageKitMatchRequest: MessageKitMatch? = nil

    //Flags
    var isRespondingToPost: Bool = false
        
    var isSenderHidden: Bool! {
        didSet {
            senderProfileNameButton.setTitle("You", for: .normal)
            if isSenderHidden {
                senderProfilePicButton.imageView?.becomeProfilePicImageView(with: UserService.singleton.getBlurredPic())
            } else {
                senderProfilePicButton.imageView?.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
            }
            messagesCollectionView.reloadData()
        }
    }
    var isReceiverHidden: Bool! {
        didSet {
            if isReceiverHidden {
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
        chatVC.isRespondingToPost = true
        
        //Load in the conversation
        if let existingConversation = ConversationService.singleton.getConversationWith(userId: postAuthor.id) {
            chatVC.conversation = existingConversation
        } else {
            chatVC.conversation = ConversationService.singleton.openConversationWith(user: postAuthor)!
        }
        
        //Create a placeholderMatchRequest if neither user has sent a match request for this post yet
        if !chatVC.conversation.matchRequests.contains(where: { $0.post == postId }) {
            chatVC.createPlaceholderMatchRequest(with: postAuthor.id, postId: postId, postTitle: postTitle)
        }
        
        return chatVC
    }
    
    class func create(conversation: Conversation) -> ChatViewController {
        let chatVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Chat) as! ChatViewController
        chatVC.conversation = conversation
        return chatVC
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: CustomMessagesFlowLayout()) //for registering custom MessageSizeCalculator for MessageKitMatch
        
        super.viewDidLoad()
        setupMessagesCollectionView()
        
        if let matchRequest = placeholderMessageKitMatchRequest, chatObjects.count == 0 {
            chatObjects.insert(matchRequest, at: 0)
        }
        renderMoreMessagesAndMatchRequests()
        setupCustomNavigationBar()
        setupHiddenProfiles() //must come after setting up the data
        if isSenderHidden {
            setupMessageInputBarForChatPrompt()
        } else {
            setupMessageInputBarForChatting()
        }
        if isRespondingToPost {
            setupWhenPresentedFromPost()
        }
        
        DispatchQueue.main.async { //scroll on the next cycle so that collectionView's data is loaded in beforehand
            self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController!.setNavigationBarHidden(true, animated: animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
            self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //if is pushing a view controller
        if !self.isAboutToClose {
            navigationController?.setNavigationBarHidden(false, animated: animated)
            navigationController?.navigationBar.tintColor = .black //otherwise it's blue... idk why
        }
    }
    
    //MARK: - Setup
    
    func setupMessagesCollectionView() {
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.delegate = self
                
        let nib = UINib(nibName: String(describing: MatchCollectionCell.self), bundle: nil)
        messagesCollectionView.register(nib, forCellWithReuseIdentifier: String(describing: MatchCollectionCell.self))
//        self.messagesCollectionView.register(CustomTextMessageContentCell.self)
        
        scrollsToLastItemOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        showMessageTimestampOnSwipeLeft = true // default false
        messagesCollectionView.refreshControl = refreshControl
        
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.sectionInset = UIEdgeInsets(top: 1, left: 8, bottom: 2, right: 8)
        layout?.setMessageOutgoingAvatarSize(.zero)
        layout?.setMessageIncomingAvatarSize(.init(width: 35, height: 35))
        layout?.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)))
        additionalBottomInset = 5
        layout?.setMessageOutgoingMessagePadding(.init(top: 0, left: 70, bottom: 0, right: 4)) //limit message max width
        layout?.setMessageIncomingMessagePadding(.init(top: 0, left: 4, bottom: 0, right: 70)) //limit message max width
    }
    
    func setupCustomNavigationBar() {
        navigationController?.isNavigationBarHidden = true
        customNavigationBar.applyLightBottomOnlyShadow()
        view.sendSubviewToBack(messagesCollectionView)
        
        //Remove top constraint which was set in super's super, MessagesViewController. Then, add a new one.
        view.constraints.first { $0.firstAnchor == messagesCollectionView.topAnchor }!.isActive = false
        messagesCollectionView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor).isActive = true
    }
    
    //TODO: both of these functions should check for previous messages. if there are messages sent before the first match request, then both should not be hidden
    
    func setupHiddenProfiles() {
        //The receiver is hidden until you receive a message from them.
        isReceiverHidden = !MatchRequestService.singleton.hasReceivedMatchRequestFrom(conversation.sangdaebang.id)
        
        //The only case you're hidden is if you received a message from them but haven't accepted it yet.
        isSenderHidden = MatchRequestService.singleton.hasReceivedMatchRequestFrom(conversation.sangdaebang.id) && !MatchRequestService.singleton.hasSentMatchRequestTo(conversation.sangdaebang.id)
    }
    
    func setupWhenPresentedFromPost() {
        xButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        
        //We want to start with the messageInputBar's textView as first responder
        //But for some reason, without this delay, self (the VC) remains the first responder
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.messageInputBar.inputTextView.becomeFirstResponder()
        }
    }
    
    //MARK: - User Interaction

    @IBAction func xButtonDidPressed(_ sender: UIButton) {
        handleDismiss()
    }
    
    func handleDismiss() {
        if isRespondingToPost {
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
        if isSenderHidden {
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
        if isReceiverHidden {
            //somehow tell the user //hey! they're hidden right now!
        } else {
            let profileVC = ProfileViewController.create(for: conversation.sangdaebang)
            navigationController!.present(profileVC, animated: true)
        }
    }
    
    @IBAction func moreButtonDidTapped(_ sender: UIButton) {
        let moreVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.ChatMore) as! ChatMoreViewController
        moreVC.loadViewIfNeeded() //doesnt work without this function call
        present(moreVC, animated: true)
    }
    
    // MARK: - Helpers
    
    //TODO: move the three sorting functions below to Conversation eventually
    func renderMoreMessagesAndMatchRequests() {
        let startLoadIndex = max(lastLoadIndex-LOAD_MESSAGES_INTERVAL, 0) //should never access a -1 of array
        Array(conversation.messageThread.server_messages[startLoadIndex...lastLoadIndex]).reversed().forEach({ message in
            insertMatchRequestIfNecessary(before: message)
            chatObjects.insert((turnMessageIntoMessageKitMessage(message)), at: 0)
        })
        
        lastLoadIndex = startLoadIndex
        if lastLoadIndex == 0 {
            insertMatchRequestAtVeryTopIfNecessary()
            messagesCollectionView.refreshControl = nil
        }
    }
    
    //if there's a matchRequest which is after the upcoming message but before the most recent message, insert it
    func insertMatchRequestIfNecessary(before upcomingMessage: Message) {
        for matchRequest in conversation.matchRequests {
            guard let first = chatObjects.first else {
                if matchRequest.timestamp > upcomingMessage.timestamp {
                    chatObjects.insert(turnMatchRequestIntoMessageKitMatchRequest(matchRequest), at: 0)
                }
                continue
            }
            if matchRequest.timestamp < first.sentDate.timeIntervalSince1970 && matchRequest.timestamp > upcomingMessage.timestamp {
                chatObjects.insert(turnMatchRequestIntoMessageKitMatchRequest(matchRequest), at: 0)
            }
        }
    }
    
    func insertMatchRequestAtVeryTopIfNecessary() {
        for matchRequest in conversation.matchRequests {
            if matchRequest.timestamp < chatObjects[0].sentDate.timeIntervalSince1970 {
                chatObjects.insert(turnMatchRequestIntoMessageKitMatchRequest(matchRequest), at: 0)
            }
        }
    }
        
    func setupMessageInputBarForChatting() {
        messageInputBar.separatorLine.isHidden = false
        messageInputBar.layer.shadowOpacity = 0

        messageInputBar.inputTextView.tintColor = mistUIColor()
        messageInputBar.inputTextView.placeholder = INPUTBAR_PLACEHOLDER
        messageInputBar.sendButton.setTitleColor(mistUIColor(), for: .normal)
        messageInputBar.inputTextView.delegate = self
        
        messageInputBar.setMiddleContentView(messageInputBar.inputTextView, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 52, animated: false)
        
//        messageInputBar.sendButton.activityViewColor = .white
//        messageInputBar.sendButton.backgroundColor = mistUIColor()
//        messageInputBar.sendButton.layer.cornerRadius = 10
//        messageInputBar.sendButton.setTitleColor(.white, for: .normal)
//        messageInputBar.sendButton.setTitleColor(UIColor(white: 1, alpha: 0.3), for: .highlighted)
//        messageInputBar.sendButton.setTitleColor(UIColor(white: 1, alpha: 0.3), for: .disabled)
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
    
    func isLastSectionVisible() -> Bool {
        guard !chatObjects.isEmpty else { return false }
        let lastIndexPath = IndexPath(item: 0, section: chatObjects.count - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        guard indexPath.section > 0 else { return true }
        let elapsedTimeSincePreviousMessage =  chatObjects[indexPath.section].sentDate.timeIntervalSince1970.getElapsedTime(since: chatObjects[indexPath.section-1].sentDate.timeIntervalSince1970)
        if elapsedTimeSincePreviousMessage.hours > 0 {
            return true
        }
        return false
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return chatObjects[indexPath.section].sender.senderId == chatObjects[indexPath.section - 1].sender.senderId
    }

    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < chatObjects.count else { return false }
        return chatObjects[indexPath.section].sender.senderId == chatObjects[indexPath.section + 1].sender.senderId
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

        if let messageKitMatch = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as? MessageKitMatch {
            let cell = messagesCollectionView.dequeueReusableCell(MatchCollectionCell.self, for: indexPath)
            cell.configure(with: messageKitMatch,
                           sangdaebang: conversation.sangdaebang,
                           delegate: self,
                           isSangdaebangHidden: isReceiverHidden,
                           isEnabled: messageKitMatch.matchRequest.read_only_post != nil)
            return cell
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
}

//MARK: - MatchRequestCellDelegate

extension ChatViewController: MatchRequestCellDelegate {
    
    func matchRequestCellDidTapped(postId: Int) {
        guard let post = PostService.singleton.getConversationPost(postId: postId) else { return }
        let postVC = PostViewController.createPostVC(with: post, shouldStartWithRaisedKeyboard: false, completionHandler: nil)
        navigationController!.pushViewController(postVC, animated: true)
    }
    
}

//MARK: - MessagesDataSource

extension ChatViewController: MessagesDataSource {
    
    func currentSender() -> SenderType {
        return UserService.singleton.getUserAsFrontendReadOnlyUser()
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return chatObjects.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return chatObjects[indexPath.section]
    }

    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(string: "Sent", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isTimeLabelVisible(at: indexPath) {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
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
        inputBar.inputTextView.placeholder = "Sending..."
        inputBar.inputTextView.resignFirstResponder()
        Task {
            do {
                if let placeholderMatchRequest = placeholderMessageKitMatchRequest {
                    try await sendMatchRequestAlongsideMessage(placeholderMatchRequest)
                }
                try conversation.messageThread.sendMessage(message_text: messageString)
                
                DispatchQueue.main.async { [weak self] in
                    self?.handleSuccessfulMessage(messageString)
                }
            } catch {
                CustomSwiftMessages.displayError(error)
                //TODO: handle when a message fails: remove the match request and the message from UI / conversation
            }
        }
    }
    
    func sendMatchRequestAlongsideMessage(_ placeholderMatchRequest: MessageKitMatch) async throws {
        try await ConversationService.singleton.sendMatchRequest(to: conversation.sangdaebang.id, forPostId: placeholderMatchRequest.matchRequest.post)
        placeholderMessageKitMatchRequest = nil
    }
    
    func handleSuccessfulMessage(_ messageString: String) {
        messageInputBar.sendButton.stopAnimating()
        messageInputBar.inputTextView.placeholder = INPUTBAR_PLACEHOLDER
        let attributedMessage = NSAttributedString(string: messageString, attributes: [.font: UIFont(name: Constants.Font.Medium, size: 15)!])
        let message = MessageKitMessage(text: attributedMessage,
                                        sender: UserService.singleton.getUserAsFrontendReadOnlyUser(),
                                        receiver: conversation.sangdaebang,
                                        messageId: String(Int.random(in: 0..<Int.max)),
                                        date: Date())
        insertMessage(message)
        messagesCollectionView.scrollToLastItem(animated: true)
    }
        
    func insertMessage(_ message: MessageKitMessage) {
        chatObjects.append(message)
        // Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([chatObjects.count - 1])
            if chatObjects.count >= 2 {
                messagesCollectionView.reloadSections([chatObjects.count - 2])
            }
        }, completion: { [] _ in
            //The below code was left from the MessageKit demo, but i dont think this is the right approach
//            if self?.isLastSectionVisible() == true {
//                self?.messagesCollectionView.scrollToLastItem(animated: true)
//            }
        })
    }
    
    func turnMessageIntoMessageKitMessage(_ message: Message) -> MessageKitMessage {
        let attributedMessage = NSAttributedString(string: message.body, attributes: [.font: UIFont(name: Constants.Font.Medium, size: 15)!])
        return MessageKitMessage(text: attributedMessage,
                                 sender: message.sender == UserService.singleton.getId() ? UserService.singleton.getUserAsFrontendReadOnlyUser() : conversation.sangdaebang,
                                 receiver: message.receiver == UserService.singleton.getId() ? UserService.singleton.getUserAsFrontendReadOnlyUser() : conversation.sangdaebang,
                                 messageId: String(message.id),
                                 date: Date(timeIntervalSince1970: message.timestamp))
    }
    
    func turnMatchRequestIntoMessageKitMatchRequest(_ matchRequest: MatchRequest) -> MessageKitMatch {
        let postTitle = matchRequest.read_only_post?.title ?? MatchRequest.DELETED_POST_TITLE
        return MessageKitMatch(matchRequest: matchRequest,
                               postTitle: postTitle,
                               matchRequester: matchRequest.match_requesting_user == UserService.singleton.getId() ? UserService.singleton.getUserAsFrontendReadOnlyUser() : conversation.sangdaebang)
    }
    
    func createPlaceholderMatchRequest(with userId: Int, postId: Int, postTitle: String)  {
        let placeholderMatchRequest = MatchRequest(id: MatchRequest.PLACEHOLDER_ID,
                     match_requesting_user: UserService.singleton.getId(),
                     match_requested_user: userId,
                     post: postId,
                     read_only_post: nil,
                     timestamp: Date().timeIntervalSince1970)
        placeholderMessageKitMatchRequest = MessageKitMatch(matchRequest: placeholderMatchRequest,
                            postTitle: postTitle,
                            matchRequester: UserService.singleton.getUserAsFrontendReadOnlyUser())
    }
    
}

//MARK: - WantToChatDelegate

extension ChatViewController: WantToChatDelegate {
    
    func handleAccept(_ acceptButton: UIButton) {
        Task {
            do {
                acceptButton.configuration?.showsActivityIndicator = true
                try await ConversationService.singleton.sendMatchRequest(to: conversation.sangdaebang.id, forPostId: conversation.matchRequests.sorted().last!.post)
                DispatchQueue.main.async { [weak self] in
                    self?.setupMessageInputBarForChatting()
                    self?.isSenderHidden = false
                    self?.messagesCollectionView.scrollToLastItem(animated: false)
                }
            } catch {
                CustomSwiftMessages.displayError(error)
            }
            acceptButton.configuration?.showsActivityIndicator = false
        }
    }
    
    func handleIgnore() {
        handleDismiss()
    }
    
    func handleBlock() {
        //block them with blockservice
        //remove this conversation from your conversations
        //handleDismiss
        
        //then, we need to make sure whenever you a chatVC appears for a blocked scenario, then...
        
        //where should blocks prevent conversations from loading in? within conversations service load()? probably. if someone blocked you during the converstaion, should we have it no longer appear in your conversations thread? or should you still see it?
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
        avatarView.isHidden = isNextMessageSameSender(at: indexPath)
        let theirPic = isReceiverHidden ? conversation.sangdaebang.blurredPic : conversation.sangdaebang.profilePic
        avatarView.set(avatar: Avatar(image: theirPic, initials: ""))
    }

}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isTimeLabelVisible(at: indexPath) ? 60 : 0
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isFromCurrentSender(message: message) && chatObjects.last?.messageId == message.messageId ? 16 : 0
    }
        
//    func textCellSizeCalculator(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CellSizeCalculator? {
//        return self.textMessageSizeCalculator
//    }
    
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
