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
    
    @IBInspectable var fillColor: UIColor = UIColor.white{
        didSet{
            setNeedsDisplay()
        }
    }
    @IBInspectable var strokeColor: UIColor = UIColor(red: 0x64/0xFF, green: 0xB5/0xFF, blue: 0xF6/0xFF, alpha: 1.0){
        didSet{
            useColor = strokeColor
        }
    }
    @IBInspectable var unableColor: UIColor = UIColor.lightGray
    @IBInspectable var isAddButton: Bool = true
    var useColor: UIColor = UIColor(red: 0x64/0xFF, green: 0xB5/0xFF, blue: 0xF6/0xFF, alpha: 1.0){
        didSet{
            setNeedsDisplay()
        }
    }
    
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
    
    override var isEnabled: Bool {
        didSet{
            if isEnabled {
                useColor = strokeColor
            }
            else {
                useColor = unableColor
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: rect)
        fillColor.setFill()
        path.fill()
        
        let plusHeight: CGFloat = 3.0
        let plusWidth: CGFloat = min(bounds.width, bounds.height) * 0.6
        
        let plusPath = UIBezierPath()
        plusPath.lineWidth = plusHeight
        
        plusPath.move(to: CGPoint(
            x:bounds.width/2 - plusWidth/2,
            y:bounds.height/2))
        
        plusPath.addLine(to: CGPoint(
            x:bounds.width/2 + plusWidth/2,
            y:bounds.height/2))
        
        if isAddButton {
            plusPath.move(to: CGPoint(
                x:bounds.width/2,
                y:bounds.height/2 - plusWidth/2))

            plusPath.addLine(to: CGPoint(
                x:bounds.width/2,
                y:bounds.height/2 + plusWidth/2))
        }
        
        useColor.setStroke()
        
        //draw the stroke
        plusPath.stroke()
    }

}
