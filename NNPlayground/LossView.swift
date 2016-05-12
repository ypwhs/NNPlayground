//
//  LossView.swift
//  NNPlayground
//
//  Created by 杨培文 on 16/5/12.
//  Copyright © 2016年 杨培文. All rights reserved.
//

import UIKit

class LossView: UIView {
    var train:[CGFloat] = []
    var test:[CGFloat] = []
    
    override func drawRect(rect: CGRect) {
        if train.count < 1{
            return
        }
        let context = UIGraphicsGetCurrentContext();
        var max:CGFloat = 0, min:CGFloat = train[0];
        for d in train{
            if d > max{
                max = d
            }
            if d < min{
                min = d
            }
        }
        min -= 0.02
        let delta = max - min
        
        let width = rect.width
        let height = rect.height
        let n = train.count
        CGContextSetLineWidth(context , 1.0)
        
        UIColor.blackColor().setStroke()
        var trainpoints = [CGPoint]()
        for i in 0..<n{
            trainpoints.append(CGPointMake(width*CGFloat(i)/CGFloat(n-1), (1 - (train[i] - min) / delta) * height))
        }
        CGContextAddLines(context, trainpoints, trainpoints.count)
        CGContextDrawPath(context, .Stroke)
        
        UIColor(white: 0, alpha: 0.2).setStroke()
        var testpoints = [CGPoint]()
        for i in 0..<n{
            testpoints.append(CGPointMake(width*CGFloat(i)/CGFloat(n-1), (1 - (test[i] - min) / delta) * height))
        }
        CGContextAddLines(context, testpoints, testpoints.count)
        CGContextDrawPath(context, .Stroke)
    }
    
    func addLoss(a:Double, b:Double){
        train.append(CGFloat(a))
        test.append(CGFloat(b))
        setNeedsDisplay()
    }
    
    func clearData(){
        train = []
        test = []
        setNeedsDisplay()
    }

}
