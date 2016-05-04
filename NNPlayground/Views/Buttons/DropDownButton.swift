//
//  DropDownButton.swift
//  UIPlayground
//
//  Created by 陈禹志 on 16/4/26.
//  Copyright © 2016年 com.insta. All rights reserved.
//

import UIKit

@IBDesignable
class DropDownButton: UIButton {

    @IBInspectable var fillColor: UIColor = UIColor.whiteColor()
    
    override func drawRect(rect: CGRect) {
        //title左对齐
        self.contentHorizontalAlignment = .Left
        self.contentEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 0)
        
        let path = UIBezierPath(rect: rect)
        fillColor.setFill()
        path.fill()
        
        //underline
        let underlineHeight: CGFloat = 1.0
        let underlineWidth: CGFloat = bounds.width - 10
        
        let underlinePath = UIBezierPath()
        underlinePath.lineWidth = underlineHeight
        
        underlinePath.moveToPoint(CGPoint(
            x:bounds.width/2 - underlineWidth/2 + 0.5,
            y:bounds.height))
        underlinePath.addLineToPoint(CGPoint(
            x:bounds.width/2 + underlineWidth/2 + 0.5,
            y:bounds.height))
        
        UIColor(red: 102/255.0, green: 204/255.0, blue: 255/255.0, alpha: 1.0).setStroke()
        
        underlinePath.stroke()
        
        //triangle
        let drawSize = CGSize(width: 10, height: 5)
        let originPoint = CGPoint(x: bounds.width - drawSize.width*1.5, y: bounds.height/2 - drawSize.height/2)
        let trianglePath = UIBezierPath()
        trianglePath.moveToPoint(CGPoint(x:originPoint.x,
            y:originPoint.y))
        trianglePath.addLineToPoint(CGPoint(x:originPoint.x + drawSize.width,
            y:originPoint.y))
        trianglePath.addLineToPoint(CGPoint(x:originPoint.x + drawSize.width/2,
            y:originPoint.y + drawSize.height))

        UIColor(red: 102/255.0, green: 204/255.0, blue: 255/255.0, alpha: 1.0).setFill()
        trianglePath.fill()

    }
}
