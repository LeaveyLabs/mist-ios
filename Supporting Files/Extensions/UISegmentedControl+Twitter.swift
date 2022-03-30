//
//  UISegmentedControl+Twitter.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/29.
//

import Foundation
import UIKit

//https://stackoverflow.com/questions/42755590/how-to-display-only-bottom-border-for-selected-item-in-uisegmentedcontrol
extension UISegmentedControl {

    func setupSegment() {
        self.fixBackgroundSegmentControl()
        self.removeBorder()
        let segmentUnderlineWidth: CGFloat = self.bounds.width
        let segmentUnderlineHeight: CGFloat = 2.0
        let segmentUnderlineXPosition = self.bounds.minX
        let segmentUnderLineYPosition = self.bounds.size.height - 1.0
        let segmentUnderlineFrame = CGRect(x: segmentUnderlineXPosition, y: segmentUnderLineYPosition, width: segmentUnderlineWidth, height: segmentUnderlineHeight)
        let segmentUnderline = UIView(frame: segmentUnderlineFrame)
        segmentUnderline.backgroundColor = UIColor.white

        self.addSubview(segmentUnderline)
        self.addUnderlineForSelectedSegment()
    }
    
    func removeUnderline(){
      guard let underline = self.viewWithTag(1) else {return}
      underline.removeFromSuperview()
    }

    func addUnderlineForSelectedSegment(){
        let underlineWidth: CGFloat = self.bounds.size.width / CGFloat(self.numberOfSegments)
        let underlineHeight: CGFloat = 2.0
        let underlineXPosition = CGFloat(selectedSegmentIndex * Int(underlineWidth))
        let underLineYPosition = self.bounds.size.height - 1.0
        let underlineFrame = CGRect(x: underlineXPosition, y: underLineYPosition, width: underlineWidth, height: underlineHeight)
        let underline = UIView(frame: underlineFrame)
        underline.backgroundColor = mistUIColor()
        underline.tag = 1
        self.addSubview(underline)
    }

    func changeUnderlinePosition(){
        guard let underline = self.viewWithTag(1) else {return}
        let underlineFinalXPosition = (self.bounds.width / CGFloat(self.numberOfSegments)) * CGFloat(selectedSegmentIndex)
        underline.frame.origin.x = underlineFinalXPosition

    }
    
    //set background color to white
    //https://stackoverflow.com/questions/58105920/how-to-set-backgroundcolor-of-uisegmentedcontrol-to-white-in-ios-13
    func fixBackgroundSegmentControl(){
        if #available(iOS 13.0, *) {
            //just to be sure it is full loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                for i in 0...(self.numberOfSegments-1)  {
                    let backgroundSegmentView = self.subviews[i]
                    //it is not enogh changing the background color. It has some kind of shadow layer
                    backgroundSegmentView.isHidden = true
                }
            }
        }
    }
    
    func removeBorder(){
        self.tintColor = UIColor.clear
        self.backgroundColor = UIColor.white
        self.setTitleTextAttributes( [NSAttributedString.Key.foregroundColor : mistUIColor()], for: .selected)
        self.setTitleTextAttributes( [NSAttributedString.Key.foregroundColor : UIColor.gray], for: .normal)
        if #available(iOS 13.0, *) {
            self.selectedSegmentTintColor = UIColor.clear
        }
    }
    
}
