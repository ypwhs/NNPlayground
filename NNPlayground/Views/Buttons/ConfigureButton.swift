//
//  ConfigureButton.swift
//  UIPlayground
//
//  Created by 陈禹志 on 16/4/27.
//  Copyright © 2016年 com.insta. All rights reserved.
//

import UIKit

@IBDesignable
class ConfigureButton: UIButton {
    
    let π:CGFloat = .pi

    override func draw(_ rect: CGRect) {
        let width = bounds.width
        let height = bounds.height
        let aArc = π*3/16
        var x:CGFloat = 0
        var y:CGFloat = 0
        
        let innerPath = UIBezierPath(ovalIn: CGRect(x: width/3, y: height/3, width: width/3, height: height/3))
        UIColor.black.setStroke()
        innerPath.stroke()
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: width/6, y: height/2 - tan(π/16)*width/3))
        
        path.addLine(to: CGPoint(x: 1.0, y: height/2 - tan(π/16)*width/3))
        path.addLine(to: CGPoint(x: 1.0, y: height/2 + tan(π/16)*width/3))
        path.addLine(to: CGPoint(x: width/6, y: height/2 + tan(π/16)*width/3))
        
        x = width/2 - cos(aArc)*width/3
        y = height/2 + sin(aArc)*width/3
        path.addLine(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x - cos(π/4)*(width/6 - 1), y: y + cos(π/4)*(height/6 - 1)))
        x = width/2 - sin(aArc)*width/3
        y = height/2 + cos(aArc)*width/3
        path.addLine(to: CGPoint(x: x - cos(π/4)*(width/6 - 1), y: y + cos(π/4)*(height/6 - 1)))
        path.addLine(to: CGPoint(x: x, y: y))
        
        
        path.addLine(to: CGPoint(x: width/2 - tan(π/16)*width/3, y: width*5/6))
        path.addLine(to: CGPoint(x: width/2 - tan(π/16)*width/3, y: width - 1))
        path.addLine(to: CGPoint(x: width/2 + tan(π/16)*width/3, y: width - 1))
        path.addLine(to: CGPoint(x: width/2 + tan(π/16)*width/3, y: width*5/6))
        
        x = width/2 + sin(aArc)*width/3
        y = height/2 + cos(aArc)*width/3
        path.addLine(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + cos(π/4)*(width/6 - 1), y: y + cos(π/4)*(height/6 - 1)))
        x = width/2 + cos(aArc)*width/3
        y = height/2 + sin(aArc)*width/3
        path.addLine(to: CGPoint(x: x + cos(π/4)*(width/6 - 1), y: y + cos(π/4)*(height/6 - 1)))
        path.addLine(to: CGPoint(x: x, y: y))
        
        
        path.addLine(to: CGPoint(x: width*5/6, y: height/2 + tan(π/16)*width/3))
        path.addLine(to: CGPoint(x: width - 1.0, y: height/2 + tan(π/16)*width/3))
        path.addLine(to: CGPoint(x: width - 1.0, y: height/2 - tan(π/16)*width/3))
        path.addLine(to: CGPoint(x: width*5/6, y: height/2 - tan(π/16)*width/3))
        
        x = width/2 + cos(aArc)*width/3
        y = height/2 - sin(aArc)*width/3
        path.addLine(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + cos(π/4)*(width/6 - 1), y: y - cos(π/4)*(height/6 - 1)))
        x = width/2 + sin(aArc)*width/3
        y = height/2 - cos(aArc)*width/3
        path.addLine(to: CGPoint(x: x + cos(π/4)*(width/6 - 1), y: y - cos(π/4)*(height/6 - 1)))
        path.addLine(to: CGPoint(x: x, y: y))
        
        path.addLine(to: CGPoint(x: width/2 + tan(π/16)*width/3, y: width/6))
        path.addLine(to: CGPoint(x: width/2 + tan(π/16)*width/3, y: 1.0))
        path.addLine(to: CGPoint(x: width/2 - tan(π/16)*width/3, y: 1.0))
        path.addLine(to: CGPoint(x: width/2 - tan(π/16)*width/3, y: width/6))
        
        x = width/2 - sin(aArc)*width/3
        y = height/2 - cos(aArc)*width/3
        path.addLine(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x - cos(π/4)*(width/6 - 1), y: y - cos(π/4)*(height/6 - 1)))
        x = width/2 - cos(aArc)*width/3
        y = height/2 - sin(aArc)*width/3
        path.addLine(to: CGPoint(x: x - cos(π/4)*(width/6 - 1), y: y - cos(π/4)*(height/6 - 1)))
        path.addLine(to: CGPoint(x: x, y: y))
        
        path.addLine(to: CGPoint(x: width/6, y: height/2 - tan(π/16)*width/3))
        path.stroke()
    }

}
