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
    @IBOutlet weak var titleMaskingView: UIView!
    @IBOutlet weak var titleShadowView: UIView!
    
    var postId: Int!
    var delegate: MistboxCellDelegate!
    var isAnimating = false
    
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
        titleShadowView.applyMediumShadow()
        titleMaskingView.clipsToBounds = true
        skipButton.setImage(UIImage(systemName: "bin.xmark"), for: .normal) //to avoid name deprecation warning
    }
    
    
    func setupButtons() {
        openButton.roundCornersViaCornerRadius(radius: 8)
        openButton.clipsToBounds = true
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
        guard !isAnimating else { return }
        isAnimating = true
        if let remainingOpens = MistboxManager.shared.getRemainingOpens(),
           remainingOpens == 0 {
            CustomSwiftMessages.showNoMoreOpensMessage()
        } else {
            finishSwiping(.up)
        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            self.isAnimating = false
//        }
    }
    
    @IBAction func skipButtonDidtapped(_ sender: UIButton) {
        guard !isAnimating else { return }
        isAnimating = true
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
        self.titleShadowView.transform = CGAffineTransform(translationX: 0, y: 0).rotated(by:0)
        layoutIfNeeded()
        isAnimating = false
//        panGesture.addTarget(self, action: #selector(handlePan(gestureRecognizer:)))
//        mask(titleLabel, maskRect: CGRect(x: titleLabel.center.x, y: titleLabel.center.y, width: titleLabel.frame.width + 10, height: titleLabel.frame.height + 50))
        // Cuts 20pt borders around the view, keeping part inside rect intact
//        flipUp()
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
//var panOffset = CGPoint.zero
//var isPanning = false
//var isSlidingUp = false
//

//
extension EnvelopeView {
    
    enum SwipeDirection {
        case up, incomplete
    }
    
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
            self.layoutIfNeeded()
            let ytranslate = envelopeImageView.frame.height * 0.2
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                self.titleShadowView.transform = CGAffineTransform(translationX: 0, y: -ytranslate)
            } completion: { finished in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.delegate.didOpenMist(postId: self.postId)
                }
            }
        case .incomplete:
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           options: .curveEaseOut) {
                self.titleShadowView.transform = CGAffineTransform(translationX: 0, y: 0).rotated(by:0)
            } completion: { finished in
                
            }
        }
    }
}
extension EnvelopeView {
    
//    func flipUp() {
//        var perspective = CATransform3DIdentity
//        perspective.m34 = -1.0 / layer.frame.size.width/2
//        
//        let animation = CABasicAnimation()
//        animation.keyPath = "transform"
//        animation.fromValue = NSValue(caTransform3D:
//            CATransform3DMakeRotation(0, 0, 0, 0))
//        animation.toValue = NSValue(caTransform3D:
//            CATransform3DConcat(perspective,CATransform3DMakeRotation(CGFloat(CGFloat.pi), 1, 0, 0)))
//        animation.duration = CFTimeInterval(3)
//        animation.repeatCount = 10
////        animation.beginTime = CACurrentMediaTime() + CFTimeInterval(0.5)
////        animation.timingFunction = getTimingFunction(curve: 1)
//        titleMaskingView.layer.add(animation, forKey: "3d")
//    }
}
