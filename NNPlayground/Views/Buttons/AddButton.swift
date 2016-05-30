//
//  AddButton.swift
//  UIPlayground
//
//  Created by 陈禹志 on 16/4/26.
//  Copyright © 2016年 com.insta. All rights reserved.
//

import UIKit

@IBDesignable
class AddButton: UIButton {
    
    @IBInspectable var fillColor: UIColor = UIColor.whiteColor(){
        didSet{
            setNeedsDisplay()
        }
    }
    @IBInspectable var strokeColor: UIColor = UIColor(red: 0x64/0xFF, green: 0xB5/0xFF, blue: 0xF6/0xFF, alpha: 1.0){
        didSet{
            useColor = strokeColor
        }
    }
    @IBInspectable var unableColor: UIColor = UIColor.lightGrayColor()
    @IBInspectable var isAddButton: Bool = true
    var useColor: UIColor = UIColor(red: 0x64/0xFF, green: 0xB5/0xFF, blue: 0xF6/0xFF, alpha: 1.0){
        didSet{
            setNeedsDisplay()
        }
    }
    
    override var highlighted: Bool {
        didSet{
            if highlighted {
                fillColor = UIColor(red: 0xEE/0xFF, green: 0xEE/0xFF, blue: 0xEE/0xFF, alpha: 1.0)
            }
            else {
                fillColor = UIColor.whiteColor()
            }
        }
    }
    
    override var enabled: Bool {
        didSet{
            if enabled {
                useColor = strokeColor
            }
            else {
                useColor = unableColor
            }
        }
    }
    
    override var hidden: Bool{
        willSet{
            if newValue {
                //减少动画未实现
                let graduallyAnimation = CABasicAnimation(keyPath: "transform.scale")
                graduallyAnimation.duration = 1
                graduallyAnimation.fromValue = 1
                graduallyAnimation.toValue = 0.01
                layer.addAnimation(graduallyAnimation, forKey: "graduallyAnimation")
                
            }
            else {
                let graduallyAnimation = CABasicAnimation(keyPath: "transform.scale")
                graduallyAnimation.duration = 0.1
                graduallyAnimation.fromValue = 0.01
                graduallyAnimation.toValue = 1
                layer.addAnimation(graduallyAnimation, forKey: "graduallyAnimation")
            }
        }
    }
    
    override func drawRect(rect: CGRect) {
        let path = UIBezierPath(ovalInRect: rect)
        fillColor.setFill()
        path.fill()
        
        let plusHeight: CGFloat = 3.0
        let plusWidth: CGFloat = min(bounds.width, bounds.height) * 0.6
        
        let plusPath = UIBezierPath()
        plusPath.lineWidth = plusHeight
        
        plusPath.moveToPoint(CGPoint(
            x:bounds.width/2 - plusWidth/2,
            y:bounds.height/2))
        
        plusPath.addLineToPoint(CGPoint(
            x:bounds.width/2 + plusWidth/2,
            y:bounds.height/2))
        
        if isAddButton {
            plusPath.moveToPoint(CGPoint(
                x:bounds.width/2,
                y:bounds.height/2 - plusWidth/2))

            plusPath.addLineToPoint(CGPoint(
                x:bounds.width/2,
                y:bounds.height/2 + plusWidth/2))
        }
        
        useColor.setStroke()
        
        //draw the stroke
        plusPath.stroke()
    }

}
