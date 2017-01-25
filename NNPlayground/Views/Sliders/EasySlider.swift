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
            setThumbImage(OriginImage(thumbImage, size: CGSize(width: diameter, height: diameter)), for: UIControlState())
        }
    }
    
    override func didMoveToSuperview() {
        thumbImage = UIImage(cgImage: drawImage())
        setThumbImage(OriginImage(thumbImage, size: CGSize(width: diameter, height: diameter)), for: UIControlState())
    }
    
    func OriginImage(_ image:UIImage, size:CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }
    
    func drawImage() -> CGImage {
        var cgImage = UIImage().cgImage
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:UInt32 = CGBitmapInfo().rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        let context = CGContext(data: nil, width: Int(diameter*2), height: Int(diameter*2), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo)

        context?.setFillColor(red: 0x64/0xFF, green: 0xB5/0xFF, blue: 0xF6/0xFF, alpha: 1.0)
        context?.addArc(center: CGPoint(x: diameter, y: diameter), radius: diameter, startAngle: 0, endAngle: 2*π, clockwise: false)
        context?.drawPath(using: .fill)
        
        cgImage = context?.makeImage()
        
        return cgImage!
    }
}
