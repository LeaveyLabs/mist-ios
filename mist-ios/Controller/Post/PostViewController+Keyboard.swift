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
            return 60 + (window?.safeAreaInsets.bottom ?? 0)
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
                self?.scrollToBottom()
            }
//            .store(in: &disposeBag)

        Publishers.MergeMany(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification),
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        )
        .subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            if !self.activityIndicator.isAnimating { //so we don't move up the loading indicator above the keyboard while loading in comments
                self.updateMessageCollectionViewBottomInset()
            }
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
        let normalizedNewBottomInset = max(0, newBottomInset)
        let differenceOfBottomInset = newBottomInset - messageCollectionViewBottomInset

        UIView.performWithoutAnimation {
            guard differenceOfBottomInset != 0 else { return }
            tableView.contentInset.bottom = normalizedNewBottomInset
            tableView.verticalScrollIndicatorInsets.bottom = newBottomInset
        }
    }

    // MARK: - Private methods
    
    private func scrollToBottom() {
        let bottom: NSIndexPath = IndexPath(row: tableView(tableView, numberOfRowsInSection: 0) - 1, section: 0) as NSIndexPath
        tableView.scrollToRow(at: bottom as IndexPath, at: .bottom, animated: true)
    }

    private func handleTextViewDidBeginEditing(_ notification: Notification) {
        guard
            scrollsToLastItemOnKeyboardBeginsEditing,
            let inputTextView = notification.object as? InputTextView,
            inputTextView === inputBar.inputTextView
        else {
            return
        }
        if !activityIndicator.isAnimating {
            tableView.layoutIfNeeded()
            scrollToBottom()
        }
        // tableView.scrollToBottom(animated: true) //only properly scrolls on the first, but not subsequent, calls for some reason
//        tableView.setContentOffset(.init(x: 0, y: tableView.contentSize.height - tableView.contentInset.bottom + 10), animated: true) //works fine, but a bit complicated
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
