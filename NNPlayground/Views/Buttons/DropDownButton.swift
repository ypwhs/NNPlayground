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

    @IBInspectable var fillColor: UIColor = UIColor.white
    @IBInspectable var strokeColor: UIColor = UIColor(red: 0x64/0xFF, green: 0xB5/0xFF, blue: 0xF6/0xFF, alpha: 1.0)
    
    override func draw(_ rect: CGRect) {
        //title左对齐
        self.contentHorizontalAlignment = .left
        self.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        
        let path = UIBezierPath(rect: rect)
        fillColor.setFill()
        path.fill()
        
        //underline
        let underlineHeight: CGFloat = 1.0
        let underlineWidth: CGFloat = bounds.width - 10
        
        let underlinePath = UIBezierPath()
        underlinePath.lineWidth = underlineHeight
        
        underlinePath.move(to: CGPoint(
            x:bounds.width/2 - underlineWidth/2 + 0.5,
            y:bounds.height))
        underlinePath.addLine(to: CGPoint(
            x:bounds.width/2 + underlineWidth/2 + 0.5,
            y:bounds.height))
        
        strokeColor.setStroke()
        
        underlinePath.stroke()
        
        //triangle
        let drawSize = CGSize(width: 10, height: 5)
        let originPoint = CGPoint(x: bounds.width - drawSize.width*1.5, y: bounds.height/2 - drawSize.height/2)
        let trianglePath = UIBezierPath()
        trianglePath.move(to: CGPoint(x:originPoint.x,
            y:originPoint.y))
        trianglePath.addLine(to: CGPoint(x:originPoint.x + drawSize.width,
            y:originPoint.y))
        trianglePath.addLine(to: CGPoint(x:originPoint.x + drawSize.width/2,
            y:originPoint.y + drawSize.height))

        strokeColor.setFill()
        trianglePath.fill()

    }
}
