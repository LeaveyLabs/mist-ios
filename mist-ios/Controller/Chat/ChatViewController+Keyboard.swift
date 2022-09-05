//
//  ChatViewController+Keyboard.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/13/22.
//

//import Foundation
//import UIKit
//import Combine
//import MessageKit
//import InputBarAccessoryView
//
//extension ChatViewController {
//
////    var overriddenAdditionalBottomInset: CGFloat {
////        return 60 + (window?.safeAreaInsets.bottom ?? 0)
////    }
////    override var additionalBottomInset: CGFloat {
////        get {
////            return 60 + (window?.safeAreaInsets.bottom ?? 0)
////        }
////        set { }
////    }
////
////    var scrollsToLastItemOnKeyboardBeginsEditing: Bool {
////        get {
////            return true
////        }
////    }
//
//    // MARK: - Register Observers
//
//    func addKeyboardObservers() {
//        view.addSubview(inputBar)
//        keyboardManager.bind(inputAccessoryView: inputBar) //properly positions inputAccessoryView
//        keyboardManager.bind(to: messagesCollectionView) //enables interactive dismissal
//        keyboardManager.shouldApplyAdditionBottomSpaceToInteractiveDismissal = true
////        additionalBottomInset = 54
//
//        /// Observe didBeginEditing to scroll down the content
//        NotificationCenter.default
//            .publisher(for: UITextView.textDidBeginEditingNotification)
//            .subscribe(on: DispatchQueue.global())
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] notification in
//                self?.handleTextViewDidBeginEditing(notification)
//            }
////            .store(in: &disposeBag)
//
//        NotificationCenter.default
//            .publisher(for: UITextView.textDidChangeNotification)
//            .subscribe(on: DispatchQueue.global())
//            .receive(on: DispatchQueue.main)
//            .compactMap { $0.object as? InputTextView }
//            .filter { [weak self] textView in
//                return textView == self?.inputBar.inputTextView
//            }
//            .map(\.text)
//            .removeDuplicates()
//            .delay(for: .milliseconds(50), scheduler: DispatchQueue.main) /// Wait for next runloop to lay out inputView properly
//            .sink { [weak self] _ in
//                self?.updateMessageCollectionViewBottomInset()
//                if !(self?.maintainPositionOnKeyboardFrameChanged ?? false) {
//                    self?.messagesCollectionView.scrollToLastItem()
//                }
//            }
////            .store(in: &disposeBag)
//
//        Publishers.MergeMany(
//            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification),
//            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
//        )
//        .subscribe(on: DispatchQueue.global())
//        .receive(on: DispatchQueue.main)
//        .sink(receiveValue: { [weak self] _ in
//            self?.updateMessageCollectionViewBottomInset()
//        })
////        .store(in: &disposeBag)
//    }
//
//    // MARK: - Updating insets
//
//    /// Updates bottom messagesCollectionView inset based on the position of inputContainerView
//    func updateMessageCollectionViewBottomInset() {
//        /// This is important to skip notifications from child modal controllers in iOS >= 13.0
//        guard self.presentedViewController == nil else { return }
//        let collectionViewHeight = messagesCollectionView.frame.height
////        print(inputBar.frame.minY, additionalBottomInset)
////        let newBottomInset = 0.0
////        let newBottomInset = collectionViewHeight - (inputBar.frame.minY - (additionalBottomInset + (window?.safeAreaInsets.bottom ?? 0))) - automaticallyAddedBottomInset
//        let newBottomInset = collectionViewHeight - (inputBar.frame.minY - additionalBottomInset) - automaticallyAddedBottomInset
//        print(collectionViewHeight, inputBar.frame.minY)
//
//        print(newBottomInset)
//        let normalizedNewBottomInset = max(0, newBottomInset)
//        let differenceOfBottomInset = newBottomInset - messageCollectionViewBottomInset
//
//        UIView.performWithoutAnimation {
//            guard differenceOfBottomInset != 0 else { return }
//            messagesCollectionView.contentInset.bottom = normalizedNewBottomInset
//            messagesCollectionView.verticalScrollIndicatorInsets.bottom = newBottomInset
//        }
//    }
//
//    // MARK: - Private methods
//
//    private func handleTextViewDidBeginEditing(_ notification: Notification) {
//        guard
//            scrollsToLastItemOnKeyboardBeginsEditing,
//            let inputTextView = notification.object as? InputTextView,
//            inputTextView === inputBar.inputTextView
//        else {
//            return
//        }
//        messagesCollectionView.layoutIfNeeded()
////        scrollToBottom()
//        messagesCollectionView.scrollToLastItem()
//    }
//
//    /// UIScrollView can automatically add safe area insets to its contentInset,
//    /// which needs to be accounted for when setting the contentInset based on screen coordinates.
//    ///
//    /// - Returns: The distance automatically added to contentInset.bottom, if any.
//    private var automaticallyAddedBottomInset: CGFloat {
//        return messagesCollectionView.adjustedContentInset.bottom - messageCollectionViewBottomInset
//    }
//
//    private var messageCollectionViewBottomInset: CGFloat {
//        return messagesCollectionView.contentInset.bottom
//    }
//
//    /// UIScrollView can automatically add safe area insets to its contentInset,
//    /// which needs to be accounted for when setting the contentInset based on screen coordinates.
//    ///
//    /// - Returns: The distance automatically added to contentInset.top, if any.
//    private var automaticallyAddedTopInset: CGFloat {
//        return messagesCollectionView.adjustedContentInset.top - messageCollectionViewTopInset
//    }
//
//    private var messageCollectionViewTopInset: CGFloat {
//        return messagesCollectionView.contentInset.top
//    }
//}
