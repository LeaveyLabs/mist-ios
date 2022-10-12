//
//  GradientView.swift
//  mist-ios
//
//  Created by Adam Monterey on 10/11/22.
//

import Foundation

class GradientView: UIView {
    
    override open class var layerClass: AnyClass {
       return CAGradientLayer.classForCoder()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("only through code")
//        super.init(coder: aDecoder)
    }
    
//    override init(frame: CGRect) {
//        <#code#>
//    }
    
    init(frame: CGRect, firstColor: UIColor, secondColor: UIColor) {
        super.init(frame: frame)
        let gradientLayer = layer as! CAGradientLayer
        gradientLayer.colors = [firstColor, secondColor]
    }
    
}
