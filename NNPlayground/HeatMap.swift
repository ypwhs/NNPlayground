//
//  HeatMap.swift
//  NNPlayground
//
//  Created by 杨培文 on 16/4/21.
//  Copyright © 2016年 杨培文. All rights reserved.
//

import UIKit
let SCALE = 3
class HeatMapView: UIView {
    let NUM_SHADES = 256
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var img = UIImage()
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bitsPerCompontent = 8
    let bytesPerRow = 4*100
    
    func setBackground(rawData:UnsafeMutablePointer<UInt32>){
        let bitmap:CGContextRef = CGBitmapContextCreate(rawData, 100, 100, bitsPerCompontent, bytesPerRow, colorSpace, CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.NoneSkipLast.rawValue)!
        
        let newImageRef = CGBitmapContextCreateImage(bitmap)!
        img = UIImage(CGImage: newImageRef)
        self.setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        img.drawInRect(rect)
        let width = Double(rect.width / 2)
        let height = Double(rect.height / 2)
        for i in 0..<x.count{
            var path = UIBezierPath(ovalInRect: CGRect(x: Double(width * x[i][0] + width)-1, y: Double(height * x[i][1] + height)-1, width: 7, height: 7))
            white.setFill()
            path.fill()
            
            path = UIBezierPath(ovalInRect: CGRect(x: Double(width * x[i][0] + width), y: Double(height * x[i][1] + height), width: 5.0, height: 5.0))
            if y[i] > 0{
                orange.setFill()
            }else{
                blue.setFill()
            }
            path.fill()
        }
    }
    
    var x:[[Double]] = []
    var y:[Double] = []
    
    func setData(x1:UnsafeMutablePointer<Double>, x2:UnsafeMutablePointer<Double>, y:UnsafeMutablePointer<Double>, size:Int){
        self.x = []
        self.y = []
        for i in 0..<size{
            self.x.append([x1[i], x2[i]])
            self.y.append(y[i])
        }
        self.setNeedsDisplay()
    }
    
    let orange = UIColor(red: 245/256.0, green: 147/256.0, blue: 36/256.0, alpha: 1)
    let blue = UIColor(red: 8/256.0, green: 119/256.0, blue: 189/256.0, alpha: 1)
    let white = UIColor(red: 232/256.0, green: 234/256.0, blue: 235/256.0, alpha: 1)
    
}
