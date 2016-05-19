//
//  EasySlider.swift
//  NNPlayground
//
//  Created by 陈禹志 on 16/5/9.
//  Copyright © 2016年 杨培文. All rights reserved.
//

import UIKit

class EasySlider: UISlider {
    
    let π:CGFloat = CGFloat(M_PI)
    
    var thumbImage = UIImage()
    
    var diameter:CGFloat = 20
    {
        didSet{
            setThumbImage(OriginImage(thumbImage, size: CGSize(width: diameter, height: diameter)), forState: .Normal)
        }
    }
    
    override func didMoveToSuperview() {
        thumbImage = UIImage(CGImage: drawImage())
        setThumbImage(OriginImage(thumbImage, size: CGSize(width: diameter, height: diameter)), forState: .Normal)
    }
    
    func OriginImage(image:UIImage, size:CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        image.drawInRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
    func drawImage() -> CGImage {
        var cgImage = UIImage().CGImage
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:UInt32 = CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue
        let context = CGBitmapContextCreate(nil, Int(diameter*2), Int(diameter*2), 8, 0, colorSpace, bitmapInfo)

        CGContextSetRGBFillColor(context, 0x64/0xFF, 0xB5/0xFF, 0xF6/0xFF, 1.0)
        CGContextAddArc(context, diameter, diameter, diameter, 0, 2*π, 0)
        CGContextDrawPath(context, .Fill)
        
        cgImage = CGBitmapContextCreateImage(context)
        
        return cgImage!
    }
}
