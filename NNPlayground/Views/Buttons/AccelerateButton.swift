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
    
    let π:CGFloat = CGFloat(Double.pi)
    
    @IBInspectable var fillColor: UIColor = UIColor.white{
        didSet{
            setNeedsDisplay()
        }
    }
    @IBInspectable var isEquilateralTriangle: Bool = true
    @IBInspectable var frontWidthRatio: CGFloat = 3/16
    override var isHighlighted: Bool {
        didSet{
            if isHighlighted {
                fillColor = UIColor(red: 0xEE/0xFF, green: 0xEE/0xFF, blue: 0xEE/0xFF, alpha: 1.0)
            }
            else {
                fillColor = UIColor.white
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: rect)
        fillColor.setFill()
        path.fill()
        
        let pathColor = UIColor(red: 24/255.0, green: 61/255.0, blue: 78/255.0, alpha: 1)
        
        if isEquilateralTriangle {
            let trianglePath_1 = UIBezierPath()
            
            let x1 = bounds.width*(0.5 - frontWidthRatio) - 0.5
            let yn = sqrt(3.0)*bounds.height*frontWidthRatio*2/5
            
            trianglePath_1.move(to: CGPoint(x:x1,
                                            y:bounds.height/2 + yn))
            trianglePath_1.addLine(to: CGPoint(x:x1,
                                               y:bounds.height/2 - yn))
            trianglePath_1.addLine(to: CGPoint(
                x:bounds.width*(0.5 + frontWidthRatio/5) - 0.5,
                y:bounds.height/2))
            pathColor.setFill()
            trianglePath_1.fill()
            
            let x2 = bounds.width*(0.5 + frontWidthRatio/5) + 0.5
            let trianglePath_2 = UIBezierPath()
            trianglePath_2.move(to: CGPoint(x:x2,
                                            y:bounds.height/2 + yn))
            trianglePath_2.addLine(to: CGPoint(x:x2,
                                               y:bounds.height/2 - yn))
            trianglePath_2.addLine(to: CGPoint(
                x:bounds.width*(0.5 + frontWidthRatio*7/5) + 0.5,
                y:bounds.height/2))
            trianglePath_2.fill()
        }
        else {
            let trianglePath_1 = UIBezierPath()
            trianglePath_1.move(to: CGPoint(
                x:bounds.width*(0.5 - frontWidthRatio) - 0.5,
                y:bounds.height/2 + bounds.height*frontWidthRatio*4/3))
            trianglePath_1.addLine(to: CGPoint(
                x:bounds.width*(0.5 - frontWidthRatio) - 0.5,
                y:bounds.height/2 - bounds.height*frontWidthRatio*4/3))
            trianglePath_1.addLine(to: CGPoint(
                x:bounds.width*(0.5 + frontWidthRatio/3) - 0.5,
                y:bounds.height/2))
            pathColor.setFill()
            trianglePath_1.fill()
            
            let trianglePath_2 = UIBezierPath()
            trianglePath_2.move(to: CGPoint(
                x:bounds.width*(0.5 + frontWidthRatio/3) + 0.5,
                y:bounds.height/2 + bounds.height*frontWidthRatio*4/3))
            trianglePath_2.addLine(to: CGPoint(
                x:bounds.width*(0.5 + frontWidthRatio/3) + 0.5,
                y:bounds.height/2 - bounds.height*frontWidthRatio*4/3))
            trianglePath_2.addLine(to: CGPoint(
                x:bounds.width*(0.5 + frontWidthRatio*5/3) + 0.5,
                y:bounds.height/2))
            trianglePath_2.fill()
        }
        
    }

}
