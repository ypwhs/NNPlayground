//
//  AccelerateButton.swift
//  NNPlayground
//
//  Created by 陈禹志 on 16/5/13.
//  Copyright © 2016年 杨培文. All rights reserved.
//

import UIKit

@IBDesignable
class AccelerateButton: UIButton {
    
    let π:CGFloat = CGFloat(M_PI)
    
    @IBInspectable var fillColor: UIColor = UIColor.whiteColor()
    @IBInspectable var isEquilateralTriangle: Bool = true
    @IBInspectable var frontWidthRatio: CGFloat = 3/16
    
    override func drawRect(rect: CGRect) {
        let path = UIBezierPath(ovalInRect: rect)
        fillColor.setFill()
        path.fill()
        
        let pathColor = UIColor(red: 24/255.0, green: 61/255.0, blue: 78/255.0, alpha: 1)
        
        if isEquilateralTriangle {
            let trianglePath_1 = UIBezierPath()
            trianglePath_1.moveToPoint(CGPoint(
                x:bounds.width*(0.5 - frontWidthRatio) - 0.5,
                y:bounds.height/2 + sqrt(3.0)*bounds.height*frontWidthRatio*2/5))
            trianglePath_1.addLineToPoint(CGPoint(
                x:bounds.width*(0.5 - frontWidthRatio) - 0.5,
                y:bounds.height/2 - sqrt(3.0)*bounds.height*frontWidthRatio*2/5))
            trianglePath_1.addLineToPoint(CGPoint(
                x:bounds.width*(0.5 + frontWidthRatio/5) - 0.5,
                y:bounds.height/2))
            pathColor.setFill()
            trianglePath_1.fill()
            
            let trianglePath_2 = UIBezierPath()
            trianglePath_2.moveToPoint(CGPoint(
                x:bounds.width*(0.5 + frontWidthRatio/5) + 0.5,
                y:bounds.height/2 + sqrt(3.0)*bounds.height*frontWidthRatio*2/5))
            trianglePath_2.addLineToPoint(CGPoint(
                x:bounds.width*(0.5 + frontWidthRatio/5) + 0.5,
                y:bounds.height/2 - sqrt(3.0)*bounds.height*frontWidthRatio*2/5))
            trianglePath_2.addLineToPoint(CGPoint(
                x:bounds.width*(0.5 + frontWidthRatio*7/5) + 0.5,
                y:bounds.height/2))
            trianglePath_2.fill()
        }
        else {
            let trianglePath_1 = UIBezierPath()
            trianglePath_1.moveToPoint(CGPoint(
                x:bounds.width*(0.5 - frontWidthRatio) - 0.5,
                y:bounds.height/2 + bounds.height*frontWidthRatio*4/3))
            trianglePath_1.addLineToPoint(CGPoint(
                x:bounds.width*(0.5 - frontWidthRatio) - 0.5,
                y:bounds.height/2 - bounds.height*frontWidthRatio*4/3))
            trianglePath_1.addLineToPoint(CGPoint(
                x:bounds.width*(0.5 + frontWidthRatio/3) - 0.5,
                y:bounds.height/2))
            pathColor.setFill()
            trianglePath_1.fill()
            
            let trianglePath_2 = UIBezierPath()
            trianglePath_2.moveToPoint(CGPoint(
                x:bounds.width*(0.5 + frontWidthRatio/3) + 0.5,
                y:bounds.height/2 + bounds.height*frontWidthRatio*4/3))
            trianglePath_2.addLineToPoint(CGPoint(
                x:bounds.width*(0.5 + frontWidthRatio/3) + 0.5,
                y:bounds.height/2 - bounds.height*frontWidthRatio*4/3))
            trianglePath_2.addLineToPoint(CGPoint(
                x:bounds.width*(0.5 + frontWidthRatio*5/3) + 0.5,
                y:bounds.height/2))
            trianglePath_2.fill()
        }
        
    }

}
