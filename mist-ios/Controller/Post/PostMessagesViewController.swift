////
////  FixedMessagesViewController.swift
////  mist-ios
////
////  Created by Adam Monterey on 8/13/22.
////
//
//import UIKit
//import MessageKit
//import InputBarAccessoryView
//
//class PostMessagesViewController: MessagesViewController {
//
//    //MARK: - Propreties
//
//    //We are using the subview rather than the first responder approach
//    override var canBecomeFirstResponder: Bool { return false }
//
//    override var inputAccessoryView: UIView?{
//        return nil //this should be "messageInputBar" according to the docs, but then i was dealing with other problems. Instead, i just increased the bottom tableview inset by 43 points. The problem: when dismissing the chat view, the bottom message scrolls behind the keyboard. That's a downside im willing to take right now
//    }
//    let keyboardManager = KeyboardManager()
//
//    let INPUTBAR_PLACEHOLDER = "Message"
//    let MAX_MESSAGE_LENGTH = 999
//
//    //Data
//    var post: Post!
//    var comments = [Comment]()
//    var commentAuthors = [Int: FrontendReadOnlyUser]() //[authorId: author]
//
//    //MARK: - Lifecycle
//
//    override func viewDidLoad() {
//        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: CustomMessagesFlowLayout()) //for registering custom MessageSizeCalculator for MessageKitMatch
//        super.viewDidLoad()
//        setupMessagesCollectionView()
//        setupMessageInputBar()
//
////        messagesCollectionView.directionalPressGestureRecognizer.allowedPressTypes
//
//        //Keyboard manager from InputBarAccessoryView
//        view.addSubview(messageInputBar)
//        keyboardManager.shouldApplyAdditionBottomSpaceToInteractiveDismissal = true
//        keyboardManager.bind(inputAccessoryView: messageInputBar) //properly positions inputAccessoryView
//        keyboardManager.bind(to: messagesCollectionView) //enables interactive dismissal
//
//        DispatchQueue.main.async { //scroll on the next cycle so that collectionView's data is loaded in beforehand
//            self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: false)
//        }
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        messagesCollectionView.reloadDataAndKeepOffset()
//    }
//
//    var viewHasAppeared = false
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        viewHasAppeared = true
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        messageInputBar.inputTextView.resignFirstResponder() //better ui animation
//    }
//
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        viewHasAppeared = false
//    }
//
//    //MARK: - Setup
//
//    func setupMessagesCollectionView() {
//        messagesCollectionView.delegate = self
//        messagesCollectionView.messagesDataSource = self
//        messagesCollectionView.messageCellDelegate = self
//        messagesCollectionView.messagesLayoutDelegate = self
//        messagesCollectionView.messagesDisplayDelegate = self
//        scrollsToLastItemOnKeyboardBeginsEditing = true // default false
////        maintainPositionOnKeyboardFrameChanged = true // default false. this was causing a weird snap when scrolling the keyboard down
////        showMessageTimestampOnSwipeLeft = true // default false
//        additionalBottomInset = 51 + (window?.safeAreaInsets.bottom ?? 0)
//    }
//
//    func setupMessageInputBar() {
//        messageInputBar.configureForCommenting()
//        messageInputBar.delegate = self
//        messageInputBar.inputTextView.delegate = self
//        messageInputBar.inputTextView.placeholder = INPUTBAR_PLACEHOLDER
//    }
//
//    //MARK: - User Interaction
//
//    @IBAction func xButtonDidPressed(_ sender: UIButton) {
//        navigationController?.popViewController(animated: true)
//    }
//
//    // MARK: - UICollectionViewDataSource
//
////    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
////
////        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
////            fatalError("Ouch. nil data source for messages")
////        }
////
////        // Very important to check this when overriding `cellForItemAt`
////        // Super method will handle returning the typing indicator cell
////        guard !isSectionReservedForTypingIndicator(indexPath.section) else {
////            return super.collectionView(collectionView, cellForItemAt: indexPath)
////        }
////
////        if let messageKitMatch = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as? MessageKitMatchRequest {
////            let cell = messagesCollectionView.dequeueReusableCell(MatchCollectionCell.self, for: indexPath)
////            cell.configure(with: messageKitMatch,
////                           sangdaebang: conversation.sangdaebang,
////                           delegate: self,
////                           isSangdaebangHidden: isSangdaebangProfileHidden)
////            return cell
////        }
////        if let messageKitInfo = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as? MessageKitInfo {
////            let cell = messagesCollectionView.dequeueReusableCell(InformationCollectionCell.self, for: indexPath)
////            cell.configure(with: messageKitInfo)
////            return cell
////        }
////        return super.collectionView(collectionView, cellForItemAt: indexPath)
////    }
//}
//
////MARK: - MessagesDataSource
//
//extension PostMessagesViewController: MessagesDataSource {
//
//    func currentSender() -> SenderType {
//        return UserService.singleton.getUserAsFrontendReadOnlyUser()
//    }
//
//    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
//        return comments.count
//    }
//
//    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
//        return conversation.getRenderedChatObjects()[indexPath.section]
//    }
//
//    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
//        if isLastMessageFromSender(message: message, at: indexPath) {
//            return NSAttributedString(string: "Sent", attributes: [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 11)!, NSAttributedString.Key.foregroundColor: UIColor.lightGray])
//        }
//        return nil
//    }
//
//    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
//        if isTimeLabelVisible(at: indexPath) {
//            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 11)!, NSAttributedString.Key.foregroundColor: UIColor.lightGray])
//        }
//        return nil
//    }
//}
//
//// MARK: - InputBarDelegate
//
//extension PostMessagesViewController: InputBarAccessoryViewDelegate {
//
//    @objc
//    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
//        processInputBar(messageInputBar)
//    }
//
//    func processInputBar(_ inputBar: InputBarAccessoryView) {
//        let messageString = inputBar.inputTextView.attributedText.string.trimmingCharacters(in: .whitespaces)
//        inputBar.inputTextView.text = String()
//        inputBar.sendButton.isEnabled = false
//        messageInputBar.inputTextView.placeholder = INPUTBAR_PLACEHOLDER
//        Task {
//            do {
//                try await conversation.sendMessage(messageText: messageString)
//                DispatchQueue.main.async { [weak self] in
//                    self?.handleNewMessage()
//                }
//            } catch {
//                CustomSwiftMessages.displayError(error)
//            }
//        }
//    }
//
//    func handleNewMessage() {
//        isAuthedUserProfileHidden = conversation.isAuthedUserHidden
//        if isSangdaebangProfileHidden && !conversation.isSangdaebangHidden {
//            //Don't insert a new section, simply reload the data. This is because even though we're handling a new message, we're also removing the last placeholder "info" message, so we shouldn't insert any sections
//            messagesCollectionView.reloadData()
//            isSangdaebangProfileHidden = conversation.isSangdaebangHidden
//        } else {
//            // Reload last section to update header/footer labels and insert a new one
//            messagesCollectionView.performBatchUpdates({
//                messagesCollectionView.insertSections([numberOfSections(in: messagesCollectionView) - 1])
//                if numberOfSections(in: messagesCollectionView) >= 2 {
//                    messagesCollectionView.reloadSections([numberOfSections(in: messagesCollectionView) - 2])
//                }
//            })
//
//        }
//        messagesCollectionView.scrollToLastItem(animated: true)
//    }
//
//}
//
////MARK: - ChatMoreDelegate
//
//extension PostMessagesViewController: ChatMoreDelegate {
//
//    func handleSuccessfulBlock() {
//        customDismiss()
//    }
//
//}
//
////MARK: - MatchRequestCellDelegate
//
//extension PostMessagesViewController: MatchRequestCellDelegate {
//
//    func matchRequestCellDidTapped(postId: Int) {
//        guard let post = PostService.singleton.getPost(withPostId: postId) else { return }
//        let postVC = PostViewController.createPostVC(with: post, shouldStartWithRaisedKeyboard: false, completionHandler: nil)
//        navigationController!.pushViewController(postVC, animated: true)
//    }
//
//}
//
////MARK: - WantToChatDelegate
//
//extension PostMessagesViewController: WantToChatDelegate {
//
//    func handleAccept(_ acceptButton: UIButton) {
//        Task {
//            do {
//                acceptButton.configuration?.showsActivityIndicator = true
//                try await conversation.sendAcceptingMatchRequest()
//                DispatchQueue.main.async { [weak self] in
//                    self?.setupMessageInputBarForChatting()
//                    self?.isAuthedUserProfileHidden = false
//                    DispatchQueue.main.async { [weak self] in
//                        //should happen on the next frame, after the input bar is changed
//                        self?.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
//                    }
//                }
//            } catch {
//                CustomSwiftMessages.displayError(error)
//            }
//            acceptButton.configuration?.showsActivityIndicator = false
//        }
//    }
//
//    func handleIgnore() {
//        customDismiss()
//    }
//
//    func handleBlock(_ blockButton: UIButton) {
//        CustomSwiftMessages.showBlockPrompt { [self] didBlock in
//            if didBlock {
//                Task {
//                    do {
//                        blockButton.configuration?.showsActivityIndicator = true
//                        try await BlockService.singleton.blockUser(conversation.sangdaebang.id)
//                        blockButton.configuration?.showsActivityIndicator = false
//                        DispatchQueue.main.async {
//                            self.customDismiss()
//                        }
//                    } catch {
//                        CustomSwiftMessages.displayError(error)
//                    }
//                }
//            }
//        }
//    }
//
//}
//
////MARK: - UITextViewDelegate
//
//extension PostMessagesViewController: UITextViewDelegate {
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        return textView.shouldChangeTextGivenMaxLengthOf(MAX_MESSAGE_LENGTH, range, text)
//    }
//}
//
//
//// MARK: - MessagesDisplayDelegate
//
//extension PostMessagesViewController: MessagesDisplayDelegate {
//
//    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
//        return MessageLabel.defaultAttributes
//    }
//
//    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
//        return [.url, .address, .phoneNumber, .date]
//    }
//
//    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
//        return isFromCurrentSender(message: message) ? .white : .lightGray.withAlphaComponent(0.25)
//    }
//
//    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
//        //The default message content view has uneven padding which can't be set by the open interface 😒
//        //Fix it here
//
//        ///if the message is not positioned correctly, then make the following edits
//        ///options:
//        ///only do this on the very first load of the VC
//        ///only do this on the very first render of the view ooooh i like this
//        /// if the view's cornerRadius is not 16.1
//
////        print("MESSAGE STYLE FUNCTION")
//
//        return .custom { view in
//            guard let messageLabel = view.subviews[0] as? MessageLabel else { return }
//            if self.isFromCurrentSender(message: message) {
//                view.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
//                view.layer.borderWidth = 1
//                messageLabel.center = CGPoint(x: messageLabel.center.x, y: messageLabel.center.y)
//            } else {
//                view.layer.borderColor = UIColor.clear.cgColor
//                view.layer.borderWidth = 0
//                messageLabel.center = CGPoint(x: messageLabel.center.x - 3, y: messageLabel.center.y)
//            }
//
//            //Only perform these positioning updates again if they were not already performed once
////            if view.layer.cornerRadius == 16.1 {
//                view.layer.cornerCurve = .continuous
//                view.layer.cornerRadius = 16.1
//                view.frame.size.width -= 4
////            }
//        }
//    }
//
//    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
//        let nextIndexPath = IndexPath(item: 0, section: indexPath.section+1)
//        avatarView.isHidden = isNextMessageSameSender(at: indexPath) && !isTimeLabelVisible(at: nextIndexPath)
//        let theirPic = isSangdaebangProfileHidden ? conversation.sangdaebang.blurredPic : conversation.sangdaebang.profilePic
//        avatarView.set(avatar: Avatar(image: theirPic, initials: ""))
//    }
//
//}
//
//// MARK: - MessagesLayoutDelegate
//
//extension PostMessagesViewController: MessagesLayoutDelegate {
//
//    //TODO: Can we delete these now that we have customcalculator?
//
//    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
//        return isTimeLabelVisible(at: indexPath) ? 50 : 0
//    }
//
//    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
//        return isLastMessageFromSender(message: message, at: indexPath) ? 16 : 0
//    }
//
//}
//
////MARK: - ScrollViewDelegate
//
//extension PostMessagesViewController {
//
//    override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
//        print("Why is this not being called?")
//    }
//
//    //Refreshes new messages when you reach the top
//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if scrollView.contentOffset.y <= 0 && !refreshControl.isRefreshing && !conversation.hasRenderedAllChatObjects() && viewHasAppeared && refreshControl.isEnabled {
//            refreshControl.beginRefreshing()
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
//                conversation.userWantsToSeeMoreMessages()
//                messagesCollectionView.reloadDataAndKeepOffset()
//                refreshControl.endRefreshing()
//                if conversation.hasRenderedAllChatObjects() { refreshControl.removeFromSuperview() }
//                refreshControl.isEnabled = false
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
//                    refreshControl.isEnabled = true //prevent another immediate reload
//                }
//            }
//        }
//    }
//
//}
//
//
//// MARK: - MessageCellDelegate
//
//extension PostMessagesViewController: MessageCellDelegate {
//
//    func didTapAvatar(in cell: MessageCollectionViewCell) {
//        handleReceiverProfileDidTapped()
//    }
//
//}
//
//// MARK: - MessageLabelDelegate
//
//extension PostMessagesViewController: MessageLabelDelegate {
//
//    func didSelectURL(_ url: URL) {
//        print("URL Selected: \(url)")
//    }
//}
//
//// MARK: - Helpers
//
//extension PostMessagesViewController {
//
//    func isLastMessageFromSender(message: MessageType, at indexPath: IndexPath) -> Bool {
//        let startingIndex = indexPath.section
//        if startingIndex > conversation.chatObjects.count { return false }
//        if startingIndex == conversation.chatObjects.count {
//            return isFromCurrentSender(message: message)
//        }
//        if !isFromCurrentSender(message: message) { return false } //make sure this message if from current sender
//        //make sure all later messages are NOT from the current sender
//        for index in startingIndex+1..<conversation.chatObjects.count {
//            if let message = conversation.chatObjects[index] as? MessageKitMessage {
//                if isFromCurrentSender(message: message) {
//                    return false
//                }
//            }
//        }
//        return true
//    }
//
//    func isLastMessage(at indexPath: IndexPath) -> Bool {
//        let isInfoCellVisible = conversation.isSangdaebangHidden
//        if isInfoCellVisible {
//            return indexPath.section == numberOfSections(in: messagesCollectionView) - 2
//        } else {
//            return indexPath.section == numberOfSections(in: messagesCollectionView) - 1
//        }
//    }
//
//    func isLastSectionVisible() -> Bool {
//        guard numberOfSections(in: messagesCollectionView) != 0 else { return false }
//        let lastIndexPath = IndexPath(item: 0, section: numberOfSections(in: messagesCollectionView) - 1)
//        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
//    }
//
//    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
//        guard indexPath.section > 0 else {
//            return conversation.hasRenderedAllChatObjects()
//        }
//        let previousIndexPath = IndexPath(item: 0, section: indexPath.section-1)
//        let previousItem = messageForItem(at: previousIndexPath, in: messagesCollectionView)
//        let thisItem = messageForItem(at: indexPath, in: messagesCollectionView)
//        let elapsedTimeSincePreviousMessage =  thisItem.sentDate.timeIntervalSince1970.getElapsedTime(since: previousItem.sentDate.timeIntervalSince1970)
//        if elapsedTimeSincePreviousMessage.hours > 0 {
//            return true
//        }
//        return false
//    }
//
//    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
//        guard indexPath.section > 0 else { return false }
//        let previousIndexPath = IndexPath(item: 0, section: indexPath.section-1)
//        let previousItem = messageForItem(at: previousIndexPath, in: messagesCollectionView)
//        let thisItem = messageForItem(at: indexPath, in: messagesCollectionView)
//        return thisItem.sender.senderId == previousItem.sender.senderId
//    }
//
//    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
//        guard indexPath.section + 1 < numberOfSections(in: messagesCollectionView) else { return false }
//        let nextIndexPath = IndexPath(item: 0, section: indexPath.section+1)
//        let nextItem = messageForItem(at: nextIndexPath, in: messagesCollectionView)
//        let thisItem = messageForItem(at: indexPath, in: messagesCollectionView)
//        return thisItem.sender.senderId == nextItem.sender.senderId
//    }
//}
//
