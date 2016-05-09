//
//  EasySlider.swift
//  NNPlayground
//
//  Created by 陈禹志 on 16/5/9.
//  Copyright © 2016年 杨培文. All rights reserved.
//

import UIKit

class EasySlider: UISlider {
    
    var thumbImage = UIImage(named: "Slider")
    var diameter:CGFloat = 20
    {
        didSet{
            setThumbImage(OriginImage(thumbImage!, size: CGSize(width: diameter, height: diameter)), forState: .Normal)
        }
    }
    
    override func didMoveToSuperview() {
        setThumbImage(OriginImage(thumbImage!, size: CGSize(width: diameter, height: diameter)), forState: .Normal)
    }
    
    func OriginImage(image:UIImage, size:CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        image.drawInRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
}
