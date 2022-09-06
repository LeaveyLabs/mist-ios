//
//  EnvelopeView.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/4/22.
//

import Foundation

extension UIButton {
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        color.setFill()
        UIRectFill(rect)
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        setBackgroundImage(colorImage, for: state)
  }
}

class EnvelopeView: UIView {
        
    //MARK: - Properties
    
    static let envelopeImageWidthHeightRatio: CGFloat = 327 / 382

    //UI
    @IBOutlet weak var envelopeImageView: UIImageView!
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var openButtonShadowSuperView: UIView!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelMaskingView: UIView!
    @IBOutlet weak var titleLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var extraShadowView: UIView!
    
    var postId: Int!
    var delegate: MistboxCellDelegate!
    
    var rect: CGRect!
    
    static let boldAttributes: [NSAttributedString.Key : Any] = [
        .font: UIFont(name: Constants.Font.Heavy, size: 18)!,
        .foregroundColor: UIColor.white,
    ]
    static let normalAttributes: [NSAttributedString.Key : Any] = [
        .font: UIFont(name: Constants.Font.Roman, size: 18)!,
        .foregroundColor: UIColor.white,
    ]
    
    //MARK: - Constructors
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customInit()
    }
    
    private func customInit() {
        guard let contentView = loadViewFromNib(nibName: "EnvelopeView") else { return }
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        setupButtons()
        envelopeImageView.applyMediumShadow()
        titleLabel.applyMediumShadow()
        extraShadowView.applyMediumShadow() //so that when the label animates up, the shadow is still remaining underneath
        titleLabelMaskingView.clipsToBounds = true
    }
    
    
    func setupButtons() {
        openButton.roundCornersViaCornerRadius(radius: 8)
        openButton.clipsToBounds = true
//        openButton.applyMediumShadow() //this will reset clips to bounds
        openButtonShadowSuperView.applyMediumShadow()
        skipButton.roundCornersViaCornerRadius(radius: 5)
        skipButton.clipsToBounds = true
        
        if #available(iOS 14, *) {
            skipButton.setImage(UIImage(systemName: "xmark.bin"), for: .normal)
        }
        else {
            skipButton.setImage(UIImage(systemName: "bin.xmark"), for: .normal)
        }
        skipButton.applyMediumShadow()
        openButton.setBackgroundColor(Constants.Color.mistPurple, for: .normal)
        openButton.setBackgroundColor(Constants.Color.mistLilac, for: .highlighted)
    }
                                                 
    func rerenderOpenCount() {
        guard let remainingOpens = MistboxManager.shared.getRemainingOpens() else { return }
        let openTextNormal = "open (" + String(remainingOpens) + ")"
        let openText = NSMutableAttributedString(string: openTextNormal)
        if let openRange = openTextNormal.range(of: "open") {
            openText.setAttributes(EnvelopeView.boldAttributes, range: NSRange(openRange, in: openTextNormal))
        }
        if let numberRange = openTextNormal.range(of: "(" + String(remainingOpens) + ")") {
            openText.setAttributes(EnvelopeView.normalAttributes, range: NSRange(numberRange, in: openTextNormal))
        }
        openButton.setAttributedTitle(openText, for: .normal)
    }
        
    //MARK: - User Interaction
    
    @IBAction func openButtonDidTapped(_ sender: UIButton) {
        if let remainingOpens = MistboxManager.shared.getRemainingOpens(),
           remainingOpens == 0 {
            CustomSwiftMessages.showNoMoreOpensMessage()
        } else {
            finishSwiping(.up)
        }
    }
    
    @IBAction func skipButtonDidtapped(_ sender: UIButton) {
        delegate.didSkipMist(postId: postId)
    }
    
}

//MARK: - Public Interface

extension EnvelopeView {
    
    // Note: the constraints for the PostView should already be set-up when this is called.
    // Otherwise you'll get loads of constraint errors in the console
    func configureForPost(post: Post, delegate: MistboxCellDelegate, panGesture: UIPanGestureRecognizer) {
        self.postId = post.id
        self.delegate = delegate
        self.titleLabel.text = post.title
        rerenderOpenCount()
        self.titleLabelMaskingView.transform = CGAffineTransform(translationX: 0, y: 0).rotated(by:0)
//        panGesture.addTarget(self, action: #selector(handlePan(gestureRecognizer:)))
//        mask(titleLabel, maskRect: CGRect(x: titleLabel.center.x, y: titleLabel.center.y, width: titleLabel.frame.width + 10, height: titleLabel.frame.height + 50))
        // Cuts 20pt borders around the view, keeping part inside rect intact
    }
    
}

extension UIView {
    
    func mask(withRect rect: CGRect, inverse: Bool = false) {
        let path = UIBezierPath(rect: rect)
        let maskLayer = CAShapeLayer()

        if inverse {
            path.append(UIBezierPath(rect: self.bounds))
            maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        }

        maskLayer.path = path.cgPath

        self.layer.mask = maskLayer
    }

}

// MARK: - PanGesture


// Panning gesture
var panOffset = CGPoint.zero
var isPanning = false
var isSlidingUp = false

enum SwipeDirection {
    case up, incomplete
}

extension EnvelopeView {
    
//    private func setupPanGesture() {
//        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gestureRecognizer:)))
//        addGestureRecognizer(pan)
//    }
    
//    @objc func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
////        postCalloutView?.layer.removeAllAnimations() //stop the demo if it's in motion
////        hasSwipeDemoAnimationRun = true
//        switch gestureRecognizer.state {
//        case .began:
//            if panOffset.y >= 0 {
//                gestureRecognizer.cancel()
//            }
//            print("began", gestureRecognizer.translation(in: self))
//        case .changed:
//            panOffset = gestureRecognizer.translation(in: self)
//            incrementSwipe()
//        case .ended:
//            isPanning = false
//            let didSwipeUp = panOffset.y < -20
//            if didSwipeUp {
//                finishSwiping(.up)
//            } else {
//                finishSwiping(.incomplete)
//            }
//        default:
//            break
//        }
//    }
//    
//    private func incrementSwipe() {
//        titleLabel.transform = CGAffineTransform(translationX: 0, y: panOffset.y * 2)
//    }
        
    private func finishSwiping(_ direction: SwipeDirection) {
        switch direction {
        case .up:
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
//                self.titleLabelHeightConstraint.constant += 30
//                self.layoutIfNeeded()
                self.titleLabelMaskingView.transform = CGAffineTransform(translationX: 0, y: -30)
            } completion: { finished in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.delegate.didOpenMist(postId: self.postId)
                }
            }
        case .incomplete:
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           options: .curveEaseOut) {
                self.titleLabelMaskingView.transform = CGAffineTransform(translationX: 0, y: 0).rotated(by:0)
            } completion: { finished in
                
            }
        }
    }
}
