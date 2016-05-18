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
            setNeedsDisplay()
        }
    }
    @IBInspectable var isAddButton: Bool = true
    
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
    
    override func drawRect(rect: CGRect) {
        let path = UIBezierPath(ovalInRect: rect)
        fillColor.setFill()
        path.fill()
        
        //set up the width and height variables
        //for the horizontal stroke
        let plusHeight: CGFloat = 3.0
        let plusWidth: CGFloat = min(bounds.width, bounds.height) * 0.6
        
        //create the path
        let plusPath = UIBezierPath()
        plusPath.lineWidth = plusHeight
        
        //move the initial point of the path
        //to the start of the horizontal stroke
        plusPath.moveToPoint(CGPoint(
            x:bounds.width/2 - plusWidth/2,
            y:bounds.height/2))
        
        //add a point to the path at the end of the stroke
        plusPath.addLineToPoint(CGPoint(
            x:bounds.width/2 + plusWidth/2,
            y:bounds.height/2))
        
        //Vertical Line
        if isAddButton {
            //move to the start of the vertical stroke
            plusPath.moveToPoint(CGPoint(
                x:bounds.width/2,
                y:bounds.height/2 - plusWidth/2))
            
            //add the end point to the vertical stroke
            plusPath.addLineToPoint(CGPoint(
                x:bounds.width/2,
                y:bounds.height/2 + plusWidth/2))
        }
        
        //set the stroke color
        strokeColor.setStroke()
        
        //draw the stroke
        plusPath.stroke()
    }

}
