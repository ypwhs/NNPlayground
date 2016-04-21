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
        initColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initColor()
    }
    
    func initColor(){
        let pr:Int = 97
        let pg:Int = 167
        let pb:Int = 213
        
        let wr:Int = 0xe8
        let wg:Int = 0xea
        let wb:Int = 0xeb
        
        let nr:Int = 246
        let ng:Int = 184
        let nb:Int = 113
        
        for i in 0...NUM_SHADES{
            //            let factor = sqrt(Double(i)/Double(NUM_SHADES))
            let factor = Double(i)/Double(NUM_SHADES)
            //            let factor = pow(Double(i)/Double(NUM_SHADES), 0.25)
            let r1 = Double(wr) + Double((pr - wr))*factor
            let g1 = Double(wg) + Double((pg - wg))*factor
            let b1 = Double(wb) + Double((pb - wb))*factor
            
            let r2 = Double(wr) + Double((nr - wr))*factor
            let g2 = Double(wg) + Double((ng - wg))*factor
            let b2 = Double(wb) + Double((nb - wb))*factor
            
            let color1 = UInt32((0xFF<<24) + (Int(r1)<<16) + (Int(g1)<<8) + Int(b1))
            let color2 = UInt32((0xFF<<24) + (Int(r2)<<16) + (Int(g2)<<8) + Int(b2))
            //            print(r2, g2, b2, String(format: "%x", color1) )
            positiveColor.append(color2)
            negativeColor.append(color1)
        }
    }
    
    var positiveColor:[UInt32] = []
    var negativeColor:[UInt32] = []
    
    func getColor(v:Double)->UInt32{
        var value = v
        if value > 0{
            if value > 1{
                value = 1
            }
            let index = Int(value * Double(NUM_SHADES-1))
            return positiveColor[index]
        }else{
            if value < -1{
                value = -1
            }
            let index = Int(-value * Double(NUM_SHADES-1))
            return negativeColor[index]
        }
    }
    
    var values:[Double] = []
    var img = UIImage()
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bitsPerCompontent = 8
    let bytesPerRow = 4*100
    
    func setBackground(rawData:UnsafeMutablePointer<UInt32>){
        let bitmap:CGContextRef = CGBitmapContextCreate(rawData, 100, 100, bitsPerCompontent, bytesPerRow, colorSpace, CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)!
        
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
    
    func setHeatValues(values: [Double]) {
        self.values = values
        self.setNeedsDisplay()
        //        print("setNeedsDisplay")
    }
    
    var x:[[Double]] = []
    var y:[Double] = []
    func setData(x:[[Double]], y:[Double]){
        self.x = x
        self.y = y
        self.setNeedsDisplay()
    }
    
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
