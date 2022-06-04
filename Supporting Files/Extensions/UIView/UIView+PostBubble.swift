//
//  UIView+Triangle.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/29.
//

import Foundation

enum BubbleTrianglePosition {
    case left
    case bottom
    case right
}

extension UIView {
    
    func transformIntoPostBubble(arrowPosition: BubbleTrianglePosition) {
        let triangleView = UIView()
        triangleView.translatesAutoresizingMaskIntoConstraints = false //allows programmatic settings of constraints
        addSubview(triangleView)
        sendSubviewToBack(triangleView)
        layer.cornerRadius = 20 //TODO: how do i add a corner radius to the triangle, too?
        layer.cornerCurve = .continuous
        applyShadowOnView(self)
        
        // Set constraints for triangle view
        var constraints = [
            triangleView.heightAnchor.constraint(equalToConstant: 80),
            triangleView.widthAnchor.constraint(equalToConstant: 80),
            triangleView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
        ]
        switch arrowPosition {
        case .left:
            constraints.append(triangleView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: -10))
        case .bottom:
            constraints.append(triangleView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0))
        case .right:
            constraints.append(triangleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 10))
        }
        
        // Adjust the width constraint of the backgroundView
        
        for constraint in superview!.constraints {
            switch arrowPosition {
            case .left:
                if constraint.identifier == "leftBubbleConstraint" {
                   constraint.constant = 20
                }
            case .bottom:
                if constraint.identifier == "bottomBubbleConstraint" {
                   constraint.constant = 35
                }
            case .right:
                if constraint.identifier == "rightBubbleConstraint" {
                   constraint.constant = 20
                }
            }
        }
        NSLayoutConstraint.activate(constraints)
        superview!.layoutIfNeeded()
        
        // Draw triangle
        let heightWidth = triangleView.frame.size.height
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: heightWidth))
        switch arrowPosition {
        case .left:
            path.addLine(to: CGPoint(x:heightWidth/2, y: -30))
            path.addLine(to: CGPoint(x:heightWidth/2, y:heightWidth))
        case .bottom:
            path.addLine(to: CGPoint(x:heightWidth/2, y: heightWidth + 30))
            path.addLine(to: CGPoint(x:heightWidth, y:heightWidth))
        case .right:
            path.addLine(to: CGPoint(x:heightWidth/2, y: -30))
            path.addLine(to: CGPoint(x:heightWidth, y:heightWidth))
        }
        path.addLine(to: CGPoint(x:0, y:heightWidth))
        
        // Apply triangle
        let shape = CAShapeLayer()
        shape.path = path
        shape.fillColor = mistSecondaryUIColor().cgColor
        triangleView.layer.insertSublayer(shape, at: 0)
    }
}


// This is the same function which is local to that particular UIView.
// Im using the generic UIView Extension for now, but saving this just in case

////MARK: - Triangle Setup
//
//func setupBubbleTriangle(at bubbleTrianglePosition: BubbleTrianglePosition) {
//    let triangleView = UIView()
//    triangleView.translatesAutoresizingMaskIntoConstraints = false //allows programmatic settings of constraints
//    backgroundBubbleView.addSubview(triangleView)
//    backgroundBubbleView.sendSubviewToBack(triangleView)
//    backgroundBubbleView.layer.cornerRadius = 20 //TODO: how do i add a corner radius to the triangle, too?
//    backgroundBubbleView.layer.cornerCurve = .continuous
//    applyShadowOnView(backgroundBubbleView)
//    
//    // Set constraints for triangle view
//    var constraints = [
//        triangleView.heightAnchor.constraint(equalToConstant: 80),
//        triangleView.widthAnchor.constraint(equalToConstant: 80),
//        triangleView.bottomAnchor.constraint(equalTo: backgroundBubbleView.bottomAnchor, constant: 0),
//    ]
//    switch bubbleTrianglePosition {
//    case .left:
//        constraints.append(triangleView.leftAnchor.constraint(equalTo: backgroundBubbleView.leftAnchor, constant: -10))
//        leftBubbleConstraint.constant = 20
//    case .bottom:
//        constraints.append(triangleView.centerXAnchor.constraint(equalTo: backgroundBubbleView.centerXAnchor, constant: 0))
//        bottomBubbleConstraint.constant = 34
//    case .right:
//        constraints.append(triangleView.rightAnchor.constraint(equalTo: backgroundBubbleView.rightAnchor, constant: 10))
//        rightBubbleConstraint.constant = 20
//    }
//    NSLayoutConstraint.activate(constraints)
//    contentView.layoutIfNeeded()
//    
//    // Draw the triangle
//    let heightWidth = triangleView.frame.size.height
//    let path = CGMutablePath()
//    path.move(to: CGPoint(x: 0, y: heightWidth))
//    switch bubbleTrianglePosition {
//    case .left:
//        path.addLine(to: CGPoint(x:heightWidth/2, y: -30))
//        path.addLine(to: CGPoint(x:heightWidth/2, y:heightWidth))
//    case .bottom:
//        path.addLine(to: CGPoint(x:heightWidth/2, y: heightWidth + 30))
//        path.addLine(to: CGPoint(x:heightWidth, y:heightWidth))
//    case .right:
//        path.addLine(to: CGPoint(x:heightWidth/2, y: -30))
//        path.addLine(to: CGPoint(x:heightWidth, y:heightWidth))
//    }
//    path.addLine(to: CGPoint(x:0, y:heightWidth))
//    
//    // Appply the triangle to the view
//    let shape = CAShapeLayer()
//    shape.path = path
//    shape.fillColor = mistSecondaryUIColor().cgColor
//    triangleView.layer.insertSublayer(shape, at: 0)
//}
