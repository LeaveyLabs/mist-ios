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
        let messageView = MessageView.viewFromNib(layout: .cardView)
        messageView.backgroundHeight = 60
        messageView.configureTheme(.error)
        messageView.configureDropShadow()
        messageView.button?.isHidden = true
        messageView.configureContent(title: "Something went wrong.",
                                     body: "Please try again.",
                                     iconImage: nil,
                                     iconText: "😔",
                                     buttonImage: UIImage(systemName: "xmark"),
                                     buttonTitle: "Close") { button in
            SwiftMessages.hide()
        }
        
        var messageConfig = SwiftMessages.Config()
        messageConfig.presentationContext = .window(windowLevel: .statusBar)
        messageConfig.presentationStyle = .top
        messageConfig.duration = .seconds(seconds: 3)

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