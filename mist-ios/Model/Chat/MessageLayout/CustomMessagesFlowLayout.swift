//
//  asdf.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/30/22.
//

import Foundation
import UIKit
import MessageKit

open class CustomMessagesFlowLayout: MessagesCollectionViewFlowLayout {
    
    public override init() {
        super.init()
        sectionInset = UIEdgeInsets(top: 1, left: 10, bottom: 2, right: 8)
        setMessageOutgoingAvatarSize(.zero)
        setMessageIncomingAvatarSize(.init(width: 33, height: 33))
        setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)))
        setMessageOutgoingMessagePadding(.init(top: 0, left: 70, bottom: 0, right: 4)) //limit age max width
        setMessageIncomingMessagePadding(.init(top: 0, left: 4, bottom: 0, right: 70)) //limit age max width
        setMessageOutgoingCellTopLabelAlignment(.init(textAlignment: .center, textInsets: .init(top: 20, left: 0, bottom: 0, right: 0)))
        setMessageIncomingCellTopLabelAlignment(.init(textAlignment: .center, textInsets: .init(top: 20, left: 0, bottom: 0, right: 0)))
        setAvatarLeadingTrailingPadding(5)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open lazy var customMessageSizeCalculator = CustomMessageSizeCalculator(layout: self)
    
    open override func cellSizeCalculatorForItem(at indexPath: IndexPath) -> CellSizeCalculator {
        if isSectionReservedForTypingIndicator(indexPath.section) {
            return typingIndicatorSizeCalculator
        }
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        if case .custom = message.kind {
            return customMessageSizeCalculator
        }
        return super.cellSizeCalculatorForItem(at: indexPath)
    }
    
    open override func messageSizeCalculators() -> [MessageSizeCalculator] {
        var superCalculators = super.messageSizeCalculators()
        // Append any of your custom `MessageSizeCalculator` if you wish for the convenience
        // functions to work such as `setMessageIncoming...` or `setMessageOutgoing...`
        superCalculators.append(customMessageSizeCalculator)
        return superCalculators
    }
}

open class CustomMessageSizeCalculator: MessageSizeCalculator {
    
    public override init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init()
        self.layout = layout
    }
    
    open override func sizeForItem(at indexPath: IndexPath) -> CGSize {
        guard let layout = layout else { return .zero }
        let collectionViewWidth = layout.collectionView?.bounds.width ?? 0
        let contentInset = layout.collectionView?.contentInset ?? .zero
        let inset = layout.sectionInset.left + layout.sectionInset.right + contentInset.left + contentInset.right
        return CGSize(width: collectionViewWidth - inset, height: 110)
    }
  
}