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

class SimpleChatViewController: ChatViewController {
    
    //MARK: - Propreties

    //UI
    @IBOutlet weak var senderProfilePicButton: UIButton!
    @IBOutlet weak var senderProfileNameButton: UIButton!
    @IBOutlet weak var receiverProfilePicButton: UIButton!
    @IBOutlet weak var receiverProfileNameButton: UIButton!
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var customNavigationBar: UIView!
    
    //Data
    var postId: Int!
    var authorId: Int!
    
    var isNewMessageFromPost: Bool = true
    
    //MARK: - Initialization
    
    class func create(postId: Int, authorId: Int) -> SimpleChatViewController {
        let chatVC =
        UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Chat) as! SimpleChatViewController
        chatVC.postId = postId
        chatVC.authorId = authorId
        return chatVC
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomNavigationBar()
        senderProfilePicButton.imageView?.becomeProfilePicImageView(with: senderProfilePicButton.imageView!.image!.blur())
        receiverProfilePicButton.imageView?.becomeProfilePicImageView(with: receiverProfilePicButton.imageView!.image!.blur())
        
        
        if isNewMessageFromPost {
            xButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            
            //We want to start with the messageInputBar's textView as first responder
            //But for some reason, without this delay, self (the VC) remains the first responder
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                self.messageInputBar.inputTextView.becomeFirstResponder()
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //MARK: - Setup
    
    func setupCustomNavigationBar() {
        navigationController?.isNavigationBarHidden = true
        customNavigationBar.applyLightBottomOnlyShadow()
        view.sendSubviewToBack(messagesCollectionView)
        
        //Remove top constraint which was set in super's super, MessagesViewController. Then, add a new one.
        view.constraints.first { $0.firstAnchor == messagesCollectionView.topAnchor }!.isActive = false
        messagesCollectionView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor).isActive = true
    }
    
    //MARK: - User Interaction

    @IBAction func xButtonDidPressed(_ sender: UIBarButtonItem) {
        messageInputBar.inputTextView.resignFirstResponder()
        self.resignFirstResponder() //to prevent the inputAccessory from staying on the screen after dismiss
        self.dismiss(animated: true)
    }
    
    @IBAction func senderProfileDidTapped(_ sender: UIBarButtonItem) {
        let profileVC = ProfileViewController.create(for: UserService.singleton.getUserAsFrontendReadOnlyUser())
        navigationController!.present(profileVC, animated: true)
    }
    
    @IBAction func receiverProfileDidTapped(_ sender: UIBarButtonItem) {
        let profileVC = ProfileViewController.create(for: UserService.singleton.getUserAsFrontendReadOnlyUser())
        navigationController!.present(profileVC, animated: true)
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

extension SimpleChatViewController: MessagesDisplayDelegate {
    
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

extension SimpleChatViewController: MessagesLayoutDelegate {
    
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
