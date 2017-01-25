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
    
    override func draw(_ rect: CGRect) {
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
        for d in test{
            if d > max{
                max = d
            }
            if d < min{
                min = d
            }
        }
        
        min *= 0.9
        let delta = (max - min)*1.1
        
        let width = rect.width
        let height = rect.height
        let n = train.count
        
        var trainpoints = [CGPoint]()
        let w2:Int = 5000
        if n < w2{
            for i in 0..<n{
                trainpoints.append(CGPoint(x: width*CGFloat(i)/CGFloat(n-1), y: (1 - (train[i] - min) / delta) * height))
            }
        }else{
            for i in 0..<w2{
                trainpoints.append(CGPoint(x: width*CGFloat(i)/CGFloat(w2), y: (1 - (train[i * n / w2] - min) / delta) * height))
            }
        }
        
        var testpoints = [CGPoint]()
        if n < w2{
            for i in 0..<n{
                testpoints.append(CGPoint(x: width*CGFloat(i)/CGFloat(n-1), y: (1 - (test[i] - min) / delta) * height))
            }
        }else{
            for i in 0..<w2{
                testpoints.append(CGPoint(x: width*CGFloat(i)/CGFloat(w2), y: (1 - (test[i * n / w2] - min) / delta) * height))
            }
        }
        
        context?.setLineWidth(1.0)
        UIColor(white: 0, alpha: 0.2).setStroke()
        context?.addLines(between: trainpoints)
        context?.drawPath(using: .stroke)
        
        UIColor.black.setStroke()
        context?.addLines(between: testpoints)
        context?.drawPath(using: .stroke)
    }
    
    func addLoss(_ a:Double, b:Double){
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
