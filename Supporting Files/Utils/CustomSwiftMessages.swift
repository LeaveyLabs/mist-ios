//
//  CustomSwiftMessages.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/29.
//

import Foundation
import SwiftMessages
import MapKit

enum PermissionType {
    case userLocation
}

//MARK: Errors

struct CustomSwiftMessages {
    
    static func displayError(_ errorDescription: String, _ recoveryDescription: String) {
        print(errorDescription)
        createAndShowError(title: errorDescription, body: recoveryDescription, emoji: "😔")
    }
    
    static func displayError(_ error: Error) {
        if let apiError = error as? APIError {
            print(apiError)
            createAndShowError(title: apiError.errorDescription!, body: apiError.recoverySuggestion!, emoji: "😔")
        } else if let mkError = error as? MKError {
            if mkError.errorCode == 4 {
                createAndShowError(title: "Something went wrong.", body: "Please try again later.", emoji: "😔")
            } else {
                print(error.localizedDescription)
            }
        } else {
            print(error.localizedDescription)
            createAndShowError(title: "Something went wrong.", body: "Please try again later.", emoji: "😔")
        }
    }
    
    private static func createAndShowError(title: String, body: String, emoji: String) {
        DispatchQueue.main.async { //ensures that these ui actions occur on the main thread
            let errorMessageView: CustomCardView = try! SwiftMessages.viewFromNib()
            errorMessageView.configureTheme(.error)
            errorMessageView.applyMediumShadow()
            errorMessageView.configureContent(title: title,
                                         body: body,
                                         iconText: emoji)
            errorMessageView.button?.isHidden = true
            errorMessageView.dismissButton.tintColor = .white
            errorMessageView.dismissAction = {
                SwiftMessages.hide()
            }
            
            var messageConfig = SwiftMessages.Config()
            messageConfig.presentationContext = .window(windowLevel: .normal)
            messageConfig.presentationStyle = .top
            messageConfig.duration = .seconds(seconds: 3)
            
            SwiftMessages.hideAll()
            SwiftMessages.show(config: messageConfig, view: errorMessageView)
        }
    }
}

//MARK: - Info

extension CustomSwiftMessages {
    
    static func showInfo(_ title: String, _ body: String, emoji: String) {
        DispatchQueue.main.async { //ensures that these ui actions occur on the main thread
            let messageView: CustomCardView = try! SwiftMessages.viewFromNib()
            messageView.configureTheme(backgroundColor: .white, foregroundColor: .black)
            messageView.applyMediumShadow()
            messageView.button?.isHidden = true
            messageView.configureContent(title: title,
                                         body: body,
                                         iconText: emoji)
            messageView.dismissButton.tintColor = .black
            messageView.dismissAction = {
                SwiftMessages.hide()
            }
            
            var messageConfig = SwiftMessages.Config()
            messageConfig.presentationContext = .window(windowLevel: .normal)
            messageConfig.presentationStyle = .top
            messageConfig.duration = .seconds(seconds: 3)

            SwiftMessages.show(config: messageConfig, view: messageView)
        }
    }
}

//MARK: - Success

extension CustomSwiftMessages {
    
    static func showSuccess(_ title: String, _ body: String) {
        DispatchQueue.main.async { //ensures that these ui actions occur on the main thread
            let messageView: CustomCardView = try! SwiftMessages.viewFromNib()
            messageView.configureTheme(backgroundColor: .systemGreen, foregroundColor: .white)
            messageView.applyMediumShadow()
            messageView.button?.isHidden = true
            messageView.configureContent(title: title,
                                         body: body,
                                         iconText: "😇")
            messageView.dismissButton.tintColor = .white
            messageView.dismissAction = {
                SwiftMessages.hide()
            }
            
            var messageConfig = SwiftMessages.Config()
            messageConfig.presentationContext = .window(windowLevel: .normal)
            messageConfig.presentationStyle = .top
            messageConfig.duration = .seconds(seconds:2)

            SwiftMessages.show(config: messageConfig, view: messageView)
        }
    }
}

//MARK: - IDK

extension CustomSwiftMessages {
    
    static func showPermissionRequest(permissionType: PermissionType, onApprove: @escaping () -> Void) {
        DispatchQueue.main.async { //ensures that these ui actions occur on the main thread

            let messageView: CustomCenteredView = try! SwiftMessages.viewFromNib()
            
            var title, body: String
            switch permissionType {
            case .userLocation:
                title = "Would you like to share your current location?"
                body = "This makes finding and submitting mists even easier."
            }
            messageView.configureContent(title: title, body: body, iconText: "🦄")
            messageView.approveAction = {
                SwiftMessages.hide()
                onApprove()
            }
            messageView.dismissAction = {
                SwiftMessages.hide()
            }
            
            messageView.configureBackgroundView(width: 300)
            messageView.backgroundView.backgroundColor = UIColor.init(white: 0.97, alpha: 1)
            messageView.backgroundView.layer.cornerRadius = 10
            SwiftMessages.show(config: middlePresentationConfig(), view: messageView)
        }
    }
    
    static func showAlert(onDiscard: @escaping () -> Void, onSave: @escaping () -> Void) {
        DispatchQueue.main.async { //ensures that these ui actions occur on the main thread
            let messageView: CustomCenteredView = try! SwiftMessages.viewFromNib()
            messageView.configureContent(title: "Before you go", body: "Would you like to save this post as a draft?", iconText: "🗑")
            
            let approveString = AttributedString(CustomAttributedString.createFor(text: "Save", fontName: Constants.Font.Heavy, size: 20))
            let dismissStirng = AttributedString(CustomAttributedString.createFor(text: "Discard", fontName: Constants.Font.Medium, size: 19))
            messageView.approveButton.configuration!.attributedTitle = approveString
            messageView.dismissButton.configuration!.attributedTitle = dismissStirng
            messageView.approveAction = {
                SwiftMessages.hide()
                onSave()
            }
            messageView.dismissAction = {
                SwiftMessages.hide()
                onDiscard()
            }
            
            messageView.backgroundView.backgroundColor = UIColor.init(white: 0.97, alpha: 1)
            messageView.backgroundView.layer.cornerRadius = 10
            messageView.configureBackgroundView(width: 300)
            SwiftMessages.show(config: middlePresentationConfig(), view: messageView)
        }
    }
    
    static func showSettingsAlertController(title: String, message: String, on controller: UIViewController) {

      let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

      let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
      let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: ""), style: .default) { (UIAlertAction) in
          UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)! as URL, options: [:], completionHandler: nil)
      }

      alertController.addAction(cancelAction)
      alertController.addAction(settingsAction)
      controller.present(alertController, animated: true, completion: nil)
   }
    
    //MARK: - Helpers
    
    static func middlePresentationConfig() -> SwiftMessages.Config {
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .center
        config.duration = .forever
        config.dimMode = .blur(style: .dark, alpha: 0.5, interactive: false)
        config.interactiveHide = false
        config.presentationContext  = .window(windowLevel: UIWindow.Level.statusBar)
        return config
    }
}
