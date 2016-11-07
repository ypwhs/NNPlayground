//
//  RunButton.swift
//  UIPlayground
//
//  Created by 陈禹志 on 16/4/27.
//  Copyright © 2016年 com.insta. All rights reserved.
//

import UIKit

@IBDesignable
class RunButton: UIButton {

    @IBInspectable var fillColor: UIColor = UIColor(red: 24/255.0, green: 61/255.0, blue: 78/255.0, alpha: 1)
    @IBInspectable var isRunButton: Bool = true
    {
        didSet{
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: rect)
        fillColor.setFill()
        path.fill()

        if isRunButton {
            //create the path
            let trianglePath = UIBezierPath()
            trianglePath.move(to: CGPoint(
                x:bounds.width/2 - sqrt(3.0)*bounds.width/18,
                y:bounds.height/3))
            trianglePath.addLine(to: CGPoint(
                x:bounds.width/2 - sqrt(3.0)*bounds.width/18,
                y:bounds.height*2/3))
            trianglePath.addLine(to: CGPoint(
                x:bounds.width/2 + sqrt(3.0)*bounds.width/9,
                y:bounds.height/2))
            UIColor.white.setFill()
            trianglePath.fill()
        }
        else {
            let pausePath = UIBezierPath()
            pausePath.lineWidth = sqrt(3.0)*bounds.width*2/27
            pausePath.move(to: CGPoint(
                x:bounds.width/2 - sqrt(3.0)*bounds.width*2/27,
                y:bounds.width/2 - bounds.width/6))
            pausePath.addLine(to: CGPoint(
                x:bounds.width/2 - sqrt(3.0)*bounds.width*2/27,
                y:bounds.width/2 + bounds.width/6))
            
            pausePath.move(to: CGPoint(
                x:bounds.width/2 + sqrt(3.0)*bounds.width*2/27,
                y:bounds.width/2 - bounds.width/6))
            pausePath.addLine(to: CGPoint(
                x:bounds.width/2 + sqrt(3.0)*bounds.width*2/27,
                y:bounds.width/2 + bounds.width/6))
            //set the stroke color
            UIColor.white.setStroke()
        
            //draw the stroke
            pausePath.stroke()
        }
        
        
    }


}
