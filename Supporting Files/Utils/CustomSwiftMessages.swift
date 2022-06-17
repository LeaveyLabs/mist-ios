//
//  CustomSwiftMessages.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/29.
//

import Foundation
import SwiftMessages

enum PermissionType {
    case userLocation
}

struct CustomSwiftMessages {
    static func showError(errorDescription: String) {
        print(errorDescription)
        let errorMessageView: CustomCardView = try! SwiftMessages.viewFromNib()
        errorMessageView.configureTheme(.error)
        errorMessageView.button?.isHidden = true
        errorMessageView.configureContent(title: "Something went wrong.",
                                     body: "Please try again.",
                                     iconText: "😔")
        errorMessageView.dismissButton.tintColor = .white
        errorMessageView.dismissAction = {
            SwiftMessages.hide()
        }
        
        var messageConfig = SwiftMessages.Config()
        messageConfig.presentationContext = .window(windowLevel: .normal)
        messageConfig.presentationStyle = .top
        messageConfig.duration = .seconds(seconds: 3)

        SwiftMessages.show(config: messageConfig, view: errorMessageView)
    }
    
    static func showInfo(_ title: String, _ body: String, emoji: String) {
        let messageView: CustomCardView = try! SwiftMessages.viewFromNib()
        messageView.configureTheme(backgroundColor: .white, foregroundColor: .black)
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
    
    static func showSuccess(_ title: String, _ body: String) {
        let messageView: CustomCardView = try! SwiftMessages.viewFromNib()
        messageView.configureTheme(backgroundColor: .systemGreen, foregroundColor: .white)
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
    
    static func showPermissionRequest(permissionType: PermissionType, onApprove: @escaping () -> Void) {
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
    
    static func showAlert(onDiscard: @escaping () -> Void, onSave: @escaping () -> Void) {
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
