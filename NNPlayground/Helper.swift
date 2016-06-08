//
//  Helper.swift
//  NNPlayground
//
//  Created by 陈禹志 on 16/5/30.
//  Copyright © 2016年 杨培文. All rights reserved.
//

import Foundation
import UIKit

typealias CancelableTask = (cancel: Bool) -> Void

func delay(time: NSTimeInterval, work: dispatch_block_t) -> CancelableTask? {
    
    var finalTask: CancelableTask?
    
    let cancelableTask: CancelableTask = { cancel in
        if cancel {
            finalTask = nil
            
        } else {
            dispatch_async(dispatch_get_main_queue(), work)
        }
    }
    
    finalTask = cancelableTask
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
        if let task = finalTask {
            task(cancel: false)
        }
    }
    
    return finalTask
}

func cancel(cancelableTask: CancelableTask?) {
    cancelableTask?(cancel: true)
}

func hideAddButton(sender: AddButton, hide: Bool) {
    
    let graduallyAnimation = CABasicAnimation(keyPath: "transform.scale")
    graduallyAnimation.duration = 0.2
    graduallyAnimation.fillMode = kCAFillModeForwards
    
    if hide {
        graduallyAnimation.fromValue = 1
        graduallyAnimation.toValue = 0.01
        sender.layer.addAnimation(graduallyAnimation, forKey: "graduallyAnimation")
        delay(0.1){
            sender.hidden = true
        }
    }
    else {
        graduallyAnimation.fromValue = 0.01
        graduallyAnimation.toValue = 1
        sender.layer.addAnimation(graduallyAnimation, forKey: "graduallyAnimation")
        sender.hidden = false
    }

}

func transitionSender(sender:UIView, hide: Bool) {
    
    let transition = CATransition()
    transition.duration = 0.2
    
    sender.layer.addAnimation(transition, forKey: "transition")
    
    if hide {
        sender.hidden = true
    }
    else {
        sender.hidden = false
    }

}

func stretchTransition(sender:UIView, toLeft: Bool, changeHidden: Bool) {
    let transition = CATransition()
    transition.duration = 0.2
    if changeHidden&&(!sender.hidden) {
        transition.type = kCATransitionReveal
    }
    else{
        transition.type = kCATransitionMoveIn
    }
    
    if toLeft {
        transition.subtype = kCATransitionFromRight
    }
    else {
        transition.subtype = kCATransitionFromLeft
    }
    
    sender.layer.addAnimation(transition, forKey: "transition")
    
    if changeHidden {
        sender.hidden = !sender.hidden
    }
}