//
//  SelectDataButton.swift
//  NNPlayground
//
//  Created by 陈禹志 on 16/5/6.
//  Copyright © 2016年 杨培文. All rights reserved.
//

import UIKit

class SelectDataButton: UIButton {
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        layer.masksToBounds = true
        layer.cornerRadius = 5
        layer.borderWidth = 2
        layer.borderColor = UIColor.blackColor().CGColor
    }

}
