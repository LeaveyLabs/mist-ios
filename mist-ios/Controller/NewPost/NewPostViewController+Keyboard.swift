//
//  NewPostViewController+Keyboard.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/3/22.
//

import Foundation
import UIKit
import Combine
import MessageKit
import InputBarAccessoryView

extension NewPostViewController {
    
//    var additionalBottomInset: CGFloat {
//        get {
//            return 60 + (window?.safeAreaInsets.bottom ?? 0)
//        }
//    }

    // MARK: - Register Observers
    
    func addKeyboardObservers() {
        keyboardManager.bind(to: scrollView) //enables interactive dismissal
        keyboardManager.shouldApplyAdditionBottomSpaceToInteractiveDismissal = true
        
        keyboardManager.on(event: .willHide) { [weak self] keyboardNotification in
            self?.updateBottomInset(keyboardHeight: 0)
        }
        
        keyboardManager.on(event: .didHide) { [weak self] keyboardNotification in //in case they press the "done" button on the toolbar, it seems that willHide doesnt get called
            self?.updateBottomInset(keyboardHeight: 0)
        }

        keyboardManager.on(event: .willShow) { [weak self] keyboardNotification in
            self?.updateBottomInset(keyboardHeight: keyboardNotification.endFrame.height)
        }
    }

    // MARK: - Updating insets

    /// Updates bottom messagesCollectionView inset based on the position of inputContainerView
    func updateBottomInset(keyboardHeight: Double) {
        /// This is important to skip notifications from child modal controllers in iOS >= 13.0
        guard self.presentedViewController == nil else { return }
//        let collectionViewHeight = scrollView.frame.height
        let newBottomInset = keyboardHeight - automaticallyAddedBottomInset
        
        let normalizedNewBottomInset = max(0, newBottomInset)
        let differenceOfBottomInset = newBottomInset - messageCollectionViewBottomInset

        UIView.performWithoutAnimation {
            guard differenceOfBottomInset != 0 else { return }
            scrollView.contentInset.bottom = normalizedNewBottomInset
            scrollView.verticalScrollIndicatorInsets.bottom = newBottomInset
        }
    }

    /// UIScrollView can automatically add safe area insets to its contentInset,
    /// which needs to be accounted for when setting the contentInset based on screen coordinates.
    ///
    /// - Returns: The distance automatically added to contentInset.bottom, if any.
    private var automaticallyAddedBottomInset: CGFloat {
        return scrollView.adjustedContentInset.bottom - messageCollectionViewBottomInset
    }
//
    private var messageCollectionViewBottomInset: CGFloat {
        return scrollView.contentInset.bottom
    }
}
