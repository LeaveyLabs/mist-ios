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
import MapKit
import MessageKit

class ChatViewController: MessageKitViewController {
    
    //MARK: - Propreties

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
    var isPresentedFromPost: Bool = true
        
    var isSenderHidden: Bool! {
        didSet {
            senderProfileNameButton.setTitle("You", for: .normal)
            if isSenderHidden {
                senderProfilePicButton.imageView?.becomeProfilePicImageView(with: UserService.singleton.getProfilePic().blur())
            } else {
                senderProfilePicButton.imageView?.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
            }
        }
    }
    var isReceiverHidden: Bool! {
        didSet {
            
            if isReceiverHidden {
                receiverProfilePicButton.imageView?.becomeProfilePicImageView(with: conversation.sangdaebang.profilePic.blur())
                receiverProfileNameButton.setTitle("???", for: .normal)
            } else {
                receiverProfilePicButton.imageView?.becomeProfilePicImageView(with: conversation.sangdaebang.profilePic)
                receiverProfileNameButton.setTitle(conversation.sangdaebang.first_name, for: .normal)
            }
        }
    }
    
    //MARK: - Initialization
    
    //Currently, postId is not being used
    class func create(postId: Int, author: FrontendReadOnlyUser) -> ChatViewController {
        let chatVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Chat) as! ChatViewController
        if let existingConversation = ConversationService.singleton.getConversationWith(userId: author.id) {
            chatVC.conversation = existingConversation
        } else {
            chatVC.conversation = ConversationService.singleton.openConversationWith(user: author)!
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
        super.viewDidLoad()
        setupCustomNavigationBar()
        setupHiddenProfiles() //NOTE: must come after setting up the data
        
        //if the conversation already exists in Service, just load the data in here
        //if the conversation does not already exist, you need to create a new one and load in the user's data
        //so when do we load the user's data? that coudl take a few seconds. whenever the postview is rendered? that seems to make the most sense. you can do an async let, and then await it when presenting SimpleChatViewController
        
        if isPresentedFromPost {
            setupWhenPresentedFromPost()
        }
        
    }
    
    //MARK: - Setup
    
    func setupHiddenProfiles() {
        //The receiver is hidden until you receive a message from them.
        isReceiverHidden = !MatchRequestService.singleton.hasReceivedMatchRequestFrom(conversation.sangdaebang.id)
        
        //The only case you're hidden is if you received a message from them but haven't accepted it yet.
        isSenderHidden = MatchRequestService.singleton.hasReceivedMatchRequestFrom(conversation.sangdaebang.id) && !MatchRequestService.singleton.hasSentMatchRequestTo(conversation.sangdaebang.id)
    }
    
    func setupCustomNavigationBar() {
        navigationController?.isNavigationBarHidden = true
        customNavigationBar.applyLightBottomOnlyShadow()
        view.sendSubviewToBack(messagesCollectionView)
        
        //Remove top constraint which was set in super's super, MessagesViewController. Then, add a new one.
        view.constraints.first { $0.firstAnchor == messagesCollectionView.topAnchor }!.isActive = false
        messagesCollectionView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor).isActive = true
    }
    
    func setupWhenPresentedFromPost() {
        xButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        
        //We want to start with the messageInputBar's textView as first responder
        //But for some reason, without this delay, self (the VC) remains the first responder
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            self.messageInputBar.inputTextView.becomeFirstResponder()
        }
    }
    
    //MARK: - User Interaction

    @IBAction func xButtonDidPressed(_ sender: UIButton) {
        if isPresentedFromPost {
            messageInputBar.inputTextView.resignFirstResponder()
            self.resignFirstResponder() //to prevent the inputAccessory from staying on the screen after dismiss
            self.dismiss(animated: true)
            if conversation.messageThread.server_messages.isEmpty {
                ConversationService.singleton.closeConversationWith(userId: conversation.sangdaebang.id)
            }
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
    
    //MARK: - ChatViewController
    
    override func configureMessageCollectionView() {
        super.configureMessageCollectionView()
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
    func textCellSizeCalculator(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CellSizeCalculator? {
        return nil
    }
    
}

// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {
    
    // MARK: - Text Messages
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        switch detector {
        case .hashtag, .mention: return [.foregroundColor: UIColor.blue]
        default: return MessageLabel.defaultAttributes
        }
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date, .transitInformation, .mention, .hashtag]
    }
    
    // MARK: - All Messages
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .blue : UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(tail, .curved)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
//        let avatar = SampleData.shared.getAvatarFor(sender: message.sender)
//        avatarView.set(avatar: avatar)
        avatarView.set(avatar: Avatar(image: UIImage(named: "adam"), initials: "AN"))
    }

}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 18
    }
    
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 17
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 20
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
}
