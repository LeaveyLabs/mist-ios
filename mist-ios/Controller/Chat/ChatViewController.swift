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
import MessageUI

class ChatViewController: MessagesViewController {
    
    //MARK: - Propreties
    
    //We are using the subview rather than the first responder approach
    override var canBecomeFirstResponder: Bool { return false }
    
    override var inputAccessoryView: UIView?{
        return nil //this should be "messageInputBar" according to the docs, but then i was dealing with other problems. Instead, i just set the additionalBottomInset as necessary when they toggle keyboard up and down
    }
    let inputBar = InputBarAccessoryView()
    let keyboardManager = KeyboardManager()
    
    var viewHasAppeared = false

    let INPUTBAR_PLACEHOLDER = "message"
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
            senderProfileNameButton.setTitle(UserService.singleton.getFirstName(), for: .normal)
            senderProfileNameButton.setImage(UserService.singleton.isVerified() ? UIImage(systemName: "checkmark.seal.fill") : nil, for: .normal)
            if isAuthedUserProfileHidden {
                senderProfilePicButton.imageView?.becomeProfilePicImageView(with: UserService.singleton.getSilhouette())
            } else {
                senderProfilePicButton.imageView?.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
            }
        }
    }
    
    //here's where it's complicated
    //all our ssandaebangs are frontendCompleteUsers
    //we'd have to reconfigure this...
    //we want to allow for conversations WITHOUT a frontendCompleteUser, bc when you're starting a dm w someone, you only need their silhouette
    //we also dont wanna make 50k changes in one commit
    
    //options:
    //1 load in frontendCOmpleteUser when opening up the DM chat. don't let them send the message until both the machrequest and the frontendCOmpleteUserProcess
    //2 make sangdaebang into a ReadOnlyUser    
    //we also need to load in the profile picture upon newly received match requests
    
    var isSangdaebangProfileHidden: Bool! {
        didSet {
            receiverProfileNameButton.setImage(conversation.sangdaebang.is_verified ? UIImage(systemName: "checkmark.seal.fill") : nil, for: .normal)
            if isSangdaebangProfileHidden {
                receiverProfilePicButton.imageView?.becomeProfilePicImageView(with: conversation.sangdaebang.silhouette)
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
        updateAdditionalBottomInsetForDismissedKeyboard()
        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: CustomMessagesFlowLayout()) //for registering custom MessageSizeCalculator for MessageKitMatch
        super.viewDidLoad()
        setupMessagesCollectionView()
        setupCustomNavigationBar()
        setupHiddenProfiles() //must come after setting up the data
        setupKeyboard()
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
        
        navigationController?.fullscreenInteractivePopGestureRecognizer(delegate: self)
    }
    
    func setupKeyboard() {
        messagesCollectionView.contentInsetAdjustmentBehavior = .never //dont think this does anything
        messageInputBar = inputBar
        inputBar.delegate = self
        inputBar.inputTextView.delegate = self
        
        //Keyboard manager from InputBarAccessoryView
        view.addSubview(messageInputBar)
        keyboardManager.shouldApplyAdditionBottomSpaceToInteractiveDismissal = true
        keyboardManager.bind(inputAccessoryView: messageInputBar) //properly positions inputAccessoryView
        keyboardManager.bind(to: messagesCollectionView) //enables interactive dismissal
                
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillShow(sender:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillHide(sender:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillChangeFrame(sender:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)
        
    }
    
    @objc func keyboardWillShow(sender: NSNotification) {
        additionalBottomInset = 52
    }
    
    @objc func keyboardWillHide(sender: NSNotification) {
        updateAdditionalBottomInsetForDismissedKeyboard()
    }
    
    var keyboardHeight: CGFloat = 0
    @objc func keyboardWillChangeFrame(sender: NSNotification) {
        let i = sender.userInfo!
        let newKeyboardHeight = (i[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        let isKeyboardTypeToggling = keyboardHeight > 0 && newKeyboardHeight > 0
        if isKeyboardTypeToggling {
            DispatchQueue.main.async { [self] in
                additionalBottomInset += newKeyboardHeight - keyboardHeight
                messagesCollectionView.scrollToLastItem()
            }
        }
        keyboardHeight = newKeyboardHeight
    }
    
    func updateAdditionalBottomInsetForDismissedKeyboard() {
        //can't use view's safe area insets because they're 0 on viewdidload
        additionalBottomInset = 52 + (window?.safeAreaInsets.bottom ?? 0)
    }
    
    //i had to add this code because scrollstolastitemonkeyboardbeginsediting doesnt work
    func textViewDidBeginEditing(_ textView: UITextView) {
        DispatchQueue.main.async {
            self.messagesCollectionView.scrollToLastItem(animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController!.setNavigationBarHidden(true, animated: animated)
        messagesCollectionView.reloadDataAndKeepOffset()
        if !inputBar.inputTextView.canBecomeFirstResponder {
            inputBar.inputTextView.canBecomeFirstResponder = true //bc we set to false in viewdiddisappear
        }
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewHasAppeared = true
        ConversationService.singleton.updateLastMessageReadTime(withUserId: conversation.sangdaebang.id)
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
            navigationController?.navigationBar.tintColor = Constants.Color.mistBlack //otherwise it's blue... idk why
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
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? TextMessageCell {
            cell.messageLabel.textInsets = .init(top: 8, left: 16, bottom: 8, right: 15)
        }
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
        if isMostRecentMessageFromSender(message: message, at: indexPath) {
            return NSAttributedString(string: "sent", attributes: [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 11)!, NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        }
        return nil
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isTimeLabelVisible(at: indexPath) {
            return NSAttributedString(string: getFormattedTimeStringForChat(timestamp: message.sentDate.timeIntervalSince1970).lowercased(), attributes: [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 12)!, NSAttributedString.Key.foregroundColor: UIColor.lightGray])
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
                DispatchQueue.main.async { [self] in
                    handleNewMessage()
                }
                Task {
                    NotificationsManager.shared.askForNewNotificationPermissionsIfNecessary(permission: .dmNotificationsAfterDm, onVC: self)
                }
            } catch {
                CustomSwiftMessages.displayError(error)
            }
        }
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        //TODO later: when going onto a new line of text, recalculate inputBar like we do within the postVC
//        additionalBottomInset = 52
//        messagesCollectionView.scrollToLastItem()
    }
        
    @MainActor
    func handleNewMessage() {
        ConversationService.singleton.updateLastMessageReadTime(withUserId: conversation.sangdaebang.id)
        isAuthedUserProfileHidden = conversation.isAuthedUserHidden
        if isSangdaebangProfileHidden && !conversation.isSangdaebangHidden {
            //Don't insert a new section, simply reload the data. This is because even though we're handling a new message, we're also removing the last placeholder "info" message, so we shouldn't insert any sections
//            messagesCollectionView.reloadDataAndKeepOffset()
            isSangdaebangProfileHidden = conversation.isSangdaebangHidden
        } else {
            //ANIMATING NEW MESSAGES CAUSES ISSUES WITH THE BUBBLE INSETS
//            let range = Range(uncheckedBounds: (0, messagesCollectionView.numberOfSections - 1))
//            let indexSet = IndexSet(integersIn: range)
//            messagesCollectionView.reloadSections(indexSet)
            // Reload last section to update header/footer labels and insert a new one
//            UIView.animate(withDuration: <#T##TimeInterval#>, delay: <#T##TimeInterval#>, animations: <#T##() -> Void#>)
//            messagesCollectionView.reloadDataAndKeepOffset()

//            messagesCollectionView.performBatchUpdates({
//                messagesCollectionView.insertSections([numberOfSections(in: messagesCollectionView) - 1])
//                if numberOfSections(in: messagesCollectionView) >= 2 {
//                    messagesCollectionView.reloadSections([numberOfSections(in: messagesCollectionView) - 2])
//                }
//            }) {_ in
//            }
//            messagesCollectionView.reloadData()
        }
        
        self.messagesCollectionView.reloadDataAndKeepOffset()

        //TODO: we do want to scrollToLastItem, but ONLY if the bottom message is below the keyboard. otherwise we get weird animations when creating the first 5 or 7 or so messages
            //no nono
        //we don't want to update the contentOffset when there is too little content
//        messagesCollectionView.scrollToLastItem(animated: true)
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
        view.endEditing(true)
        navigationController!.pushViewController(postVC, animated: true)
    }
    
}

//MARK: - WantToChatDelegate

extension ChatViewController: WantToChatDelegate {
    
    func handleAccept(_ acceptButton: UIButton) {
        acceptButton.loadingIndicator(true)
        acceptButton.isEnabled = false
        acceptButton.setTitle("", for: .disabled)
        Task {
            do {
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
            DispatchQueue.main.async {
                acceptButton.loadingIndicator(false)
                acceptButton.isEnabled = true
            }
        }
    }
    
    func handleIgnore() {
        customDismiss()
    }
    
    func handleBlock(_ blockButton: UIButton) {
        CustomSwiftMessages.showBlockPrompt { [self] didBlock in
            if didBlock {
                DispatchQueue.main.async {
                    blockButton.loadingIndicator(true)
                    blockButton.isEnabled = false
                    blockButton.setTitle("", for: .disabled)
                }
                Task {
                    do {
                        try await BlockService.singleton.blockUser(conversation.sangdaebang.id)
                        DispatchQueue.main.async {
                            self.customDismiss()
                        }
                    } catch {
                        CustomSwiftMessages.displayError(error)
                    }
                    DispatchQueue.main.async {
                        blockButton.loadingIndicator(false)
                        blockButton.isEnabled = true
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
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return Constants.Color.mistBlack
    }
        
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        return MessageLabel.defaultAttributes
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .phoneNumber]
    }
        
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .lightGray.withAlphaComponent(0.2) : .white
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        return isFromCurrentSender(message: message) ? .bubble : .bubbleOutline(.darkGray.withAlphaComponent(0.23))
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let nextIndexPath = IndexPath(item: 0, section: indexPath.section+1)
        avatarView.isHidden = isNextMessageSameSender(at: indexPath) && !isTimeLabelVisible(at: nextIndexPath)
        let theirPic = isSangdaebangProfileHidden ? conversation.sangdaebang.silhouette : conversation.sangdaebang.profilePic
        avatarView.set(avatar: Avatar(image: theirPic, initials: ""))
    }

}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {
        
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isTimeLabelVisible(at: indexPath) ? 50 : 0
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isMostRecentMessageFromSender(message: message, at: indexPath) ? 16 : 0
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
        dismissKeyboard()
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        dismissKeyboard()
    }
    
    func didTapCellTopLabel(in cell: MessageCollectionViewCell) {
        dismissKeyboard()
    }
    
    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        dismissKeyboard()
    }
    
    @objc func dismissKeyboard() {
        updateAdditionalBottomInsetForDismissedKeyboard()
        inputBar.inputTextView.resignFirstResponder()
    }
    
}

// MARK: - MessageLabelDelegate

extension ChatViewController: MessageLabelDelegate, MFMessageComposeViewControllerDelegate {
    
    func didSelectURL(_ url: URL) {
        openURL(url)
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print(phoneNumber)
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = ""
            controller.recipients = [phoneNumber]
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Helpers

extension ChatViewController {
    
    func isMostRecentMessageFromSender(message: MessageType, at indexPath: IndexPath) -> Bool {
        let isMostRecentMessage = indexPath.section == conversation.getRenderedChatObjects().count - 1
        return isMostRecentMessage && isFromCurrentSender(message: message)
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
