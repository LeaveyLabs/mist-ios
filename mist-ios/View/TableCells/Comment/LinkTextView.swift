//
//  LinkTextView.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/9/22.
//

import Foundation

//Referenfe:https://stackoverflow.com/questions/1256887/create-tap-able-links-in-the-nsattributedstring-of-a-uilabel
class LinkTextView: UITextView {
    
    typealias OnLinkTap = (URL) -> Bool
    
    var onLinkTap: OnLinkTap?
    
    typealias Links = [String: String]
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        isScrollEnabled = false //on other applications, setting isScrollEnabled to false causes wrong behavior. Here, it's working fine though
        isEditable = false
        isSelectable = true
    }
    
    func addLinks(_ links: Links) {
        guard attributedText.length > 0  else {
            return
        }
        let mText = NSMutableAttributedString(attributedString: attributedText)
        
        self.textColor = .blue
        for (linkText, urlString) in links {
            if linkText.count > 0 {
                let linkRanges = mText.string.ranges(of: linkText)
                for range in linkRanges {
                    let nsrange = NSRange(range, in: self.attributedText.string)
                    mText.addAttribute(.link, value: urlString, range: nsrange)
//                    mText.addAttributes(CommentAutocompleteManager.tagTextAttributes, range: NSRange)
                }
            }
        }
        attributedText = mText
        self.textColor = .red
    }
    
    //Disable long press on links
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
//        print(event?.allTouches?.first?.preciseLocation(in: self))
        cancelTextFieldLongPress(event)
    }
    
    @objc func cancelTextFieldLongPress(_ event: UIEvent?) {
        event?.allTouches!.forEach { touch in
            touch.gestureRecognizers?.forEach({ recognizer in
                if !recognizer .isKind(of: UIPanGestureRecognizer.self) {
                    recognizer.cancel()
                }
            })
        }
    }
    
    //To disable general interaction with text view's text, like double tap highlighting
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let pos = closestPosition(to: point),
              let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: UITextDirection.layout(.left)) else { return false }
        let startIndex = offset(from: beginningOfDocument, to: range.start)
        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
}

extension UIGestureRecognizer {
    
    func cancel() {
        self.isEnabled = false
        self.isEnabled = true
    }
}
