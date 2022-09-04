//
//  UIFont+Ext.swift
//  Cosmonaut
//
//  Created by J Manuel Zaragoza on 8/19/22.
//

import Foundation
import UIKit

extension UIFont {
    class func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let font : UIFont
        
        if let desc = systemFont.fontDescriptor.withDesign(.rounded) {
            font = UIFont(descriptor: desc, size: size)
        } else {
            font = systemFont
        }
        
        return font
    }
}
