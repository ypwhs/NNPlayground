//
//  AddButton.swift
//  UIPlayground
//
//  Created by 陈禹志 on 16/4/26.
//  Copyright © 2016年 com.insta. All rights reserved.
//

import UIKit

@IBDesignable
class CheckButton: UIButton {
    
    @IBInspectable var fillColor: UIColor = UIColor(red: 0x18/0xFF, green: 0x3D/0xFF, blue: 0x4E/0xFF, alpha: 1)
    @IBInspectable var checked: Bool = false
    {
        didSet{
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        let w:CGFloat = 14
        let x:CGFloat = 2
        let y:CGFloat = rect.height/2 - w/2
        let group = CGRectMake(2, rect.height/2 - w/2, w, w)
        
        let checkMarkFrame = UIBezierPath(roundedRect: group, cornerRadius: 2)
        checkMarkFrame.lineWidth = 1.5
        if checked{
            fillColor.setStroke()
        }else{
            UIColor(white: 0.43, alpha: 1).setStroke()
        }
        checkMarkFrame.stroke()
        
        if checked{
            let fill = UIBezierPath(roundedRect: group, cornerRadius: 2)
            fillColor.setFill()
            fill.fill()
            
            let bezierPath = UIBezierPath()
            bezierPath.moveToPoint(CGPointMake(x + 0.2 * w, y + 0.6 * w))
            bezierPath.addLineToPoint(CGPointMake(x + (0.2 + 0.15) * w, y + (0.6 + 0.15) * w))
            bezierPath.addLineToPoint(CGPointMake(x + (0.2 + 0.15 + 0.4) * w, y + (0.6 + 0.15 - 0.4) * w))
            bezierPath.lineCapStyle = .Square
            
            UIColor.whiteColor().setStroke()
            bezierPath.lineWidth = 2.5;
            bezierPath.stroke()
        }
    }

}
