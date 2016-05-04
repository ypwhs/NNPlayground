//
//  ResetButton.swift
//  UIPlayground
//
//  Created by 陈禹志 on 16/4/27.
//  Copyright © 2016年 com.insta. All rights reserved.
//

import UIKit

let π:CGFloat = CGFloat(M_PI)

@IBDesignable
class ResetButton: UIButton {

    @IBInspectable var fillColor: UIColor = UIColor.whiteColor()
    @IBInspectable var isResetButton: Bool = true
    
    override func drawRect(rect: CGRect) {
        let path = UIBezierPath(ovalInRect: rect)
        fillColor.setFill()
        path.fill()
        
        let pathColor = UIColor(red: 24/255.0, green: 61/255.0, blue: 78/255.0, alpha: 1)
        let pathWidth:CGFloat = 2.0
        if isResetButton {
            //create the path
            let resetPath = UIBezierPath(arcCenter: CGPoint(x: bounds.width/2,y: bounds.height/2), radius: bounds.width/4, startAngle: -π/2, endAngle: π, clockwise: true)
            resetPath.lineWidth = pathWidth
            
            pathColor.setStroke()
            resetPath.stroke()
    
            let drawSize = CGSize(width: 4, height: 8)
            let originPoint = CGPoint(x: bounds.width/2 - drawSize.width, y: bounds.height/4)
            let trianglePath = UIBezierPath()
            trianglePath.moveToPoint(CGPoint(x:originPoint.x,
                y:originPoint.y))
            trianglePath.addLineToPoint(CGPoint(x:originPoint.x + drawSize.width,
                y:originPoint.y + drawSize.height/2))
            trianglePath.addLineToPoint(CGPoint(x:originPoint.x + drawSize.width,
                y:originPoint.y - drawSize.height/2))
            
            pathColor.setFill()
            trianglePath.fill()
        }
        else {
            let stepPath = UIBezierPath()
            stepPath.lineWidth = pathWidth
            
            stepPath.moveToPoint(CGPoint(x: bounds.width*11/16 + 1.0, y: bounds.height/2 + sqrt(3.0)*bounds.height/8))
            stepPath.addLineToPoint(CGPoint(x: bounds.width*11/16 + 1.0, y: bounds.height/2 - sqrt(3.0)*bounds.height/8))

            
            pathColor.setStroke()
            stepPath.stroke()
            
            let trianglePath = UIBezierPath()
            trianglePath.moveToPoint(CGPoint(
                x:bounds.width*5/16 - 1.0,
                y:bounds.height/2 + sqrt(3.0)*bounds.height/8))
            trianglePath.addLineToPoint(CGPoint(
                x:bounds.width*5/16 - 1.0,
                y:bounds.height/2 - sqrt(3.0)*bounds.height/8))
            trianglePath.addLineToPoint(CGPoint(
                x:bounds.width*11/16 - 1.0,
                y:bounds.height/2))
            pathColor.setFill()
            trianglePath.fill()
        }
    }

}
