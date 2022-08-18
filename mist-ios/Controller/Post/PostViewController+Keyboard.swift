//
//  ChatViewController+Keyboard.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/13/22.
//

import Foundation
import UIKit
import Combine
import MessageKit
import InputBarAccessoryView

extension PostViewController {
    
    var additionalBottomInset: CGFloat {
        get {
            return 51 //5 + inputBar.frame.height
        }
    }
    
    var scrollsToLastItemOnKeyboardBeginsEditing: Bool {
        get {
            return true
        }
    }

    // MARK: - Register Observers
    
    func addKeyboardObservers() {
        view.addSubview(inputBar)
        keyboardManager.bind(inputAccessoryView: inputBar) //properly positions inputAccessoryView
        keyboardManager.bind(to: tableView) //enables interactive dismissal
        keyboardManager.shouldApplyAdditionBottomSpaceToInteractiveDismissal = true
//        updateMessageCollectionViewBottomInset()
        
        /// Observe didBeginEditing to scroll down the content
        NotificationCenter.default
            .publisher(for: UITextView.textDidBeginEditingNotification)
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleTextViewDidBeginEditing(notification)
            }
//            .store(in: &disposeBag)

        NotificationCenter.default
            .publisher(for: UITextView.textDidChangeNotification)
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .compactMap { $0.object as? InputTextView }
            .filter { [weak self] textView in
                return textView == self?.inputBar.inputTextView
            }
            .map(\.text)
            .removeDuplicates()
            .delay(for: .milliseconds(50), scheduler: DispatchQueue.main) /// Wait for next runloop to lay out inputView properly
            .sink { [weak self] _ in
                self?.updateMessageCollectionViewBottomInset()

//                if !(self?.maintainPositionOnInputBarHeightChanged ?? false) {
//                    self?.messagesCollectionView.scrollToLastItem()
//                }
            }
//            .store(in: &disposeBag)

        Publishers.MergeMany(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification),
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        )
        .subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] _ in
            self?.updateMessageCollectionViewBottomInset()
        })
//        .store(in: &disposeBag)
    }

    // MARK: - Updating insets

    /// Updates bottom messagesCollectionView inset based on the position of inputContainerView
    func updateMessageCollectionViewBottomInset() {
        /// This is important to skip notifications from child modal controllers in iOS >= 13.0
        guard self.presentedViewController == nil else { return }
        let collectionViewHeight = tableView.frame.height
        let newBottomInset = collectionViewHeight - (inputBar.frame.minY - additionalBottomInset) - automaticallyAddedBottomInset
        print("new bottom isnet", newBottomInset)
        let normalizedNewBottomInset = max(0, newBottomInset)
        let differenceOfBottomInset = newBottomInset - messageCollectionViewBottomInset

        UIView.performWithoutAnimation {
            guard differenceOfBottomInset != 0 else { return }
            tableView.contentInset.bottom = normalizedNewBottomInset
            tableView.verticalScrollIndicatorInsets.bottom = newBottomInset
        }
    }

    // MARK: - Private methods

    private func handleTextViewDidBeginEditing(_ notification: Notification) {
        guard
            scrollsToLastItemOnKeyboardBeginsEditing,
            let inputTextView = notification.object as? InputTextView,
            inputTextView === inputBar.inputTextView
        else {
            return
        }
//        tableView.scrollToBottom(animated: true)
        updateMessageCollectionViewBottomInset()
        
        //WAIT... contentoffset vs inset??
//        tableView.contentOffset.y = 45 + keyboardHeight
        tableView.contentInset.bottom = 45 + keyboardHeight
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.tableView.scrollToBottom(animated: true)
        }
    }

    /// UIScrollView can automatically add safe area insets to its contentInset,
    /// which needs to be accounted for when setting the contentInset based on screen coordinates.
    ///
    /// - Returns: The distance automatically added to contentInset.bottom, if any.
    private var automaticallyAddedBottomInset: CGFloat {
        return tableView.adjustedContentInset.bottom - messageCollectionViewBottomInset
    }

    private var messageCollectionViewBottomInset: CGFloat {
        return tableView.contentInset.bottom
    }

    /// UIScrollView can automatically add safe area insets to its contentInset,
    /// which needs to be accounted for when setting the contentInset based on screen coordinates.
    ///
    /// - Returns: The distance automatically added to contentInset.top, if any.
    private var automaticallyAddedTopInset: CGFloat {
        return tableView.adjustedContentInset.top - messageCollectionViewTopInset
    }

    private var messageCollectionViewTopInset: CGFloat {
        return tableView.contentInset.top
    }
}
