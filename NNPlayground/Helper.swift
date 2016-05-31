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
    //    CATransition* transition = [CATransition animation];
    //    transition.startProgress = 0;
    //    transition.endProgress = 1.0;
    //    transition.type = kCATransitionPush;
    //    transition.subtype = kCATransitionFromRight;
    //    transition.duration = 1.0;
    //
    //    // Add the transition animation to both layers
    //    [myView1.layer addAnimation:transition forKey:@"transition"];
    //    [myView2.layer addAnimation:transition forKey:@"transition"];
    //
    //    // Finally, change the visibility of the layers.
    //    myView1.hidden = YES;
    //    myView2.hidden = NO;

//    let transition = CATransition()
//    transition.startProgress = 0;
//    transition.endProgress = 1.0;
//    transition.type = kCATransitionPush;
//    transition.subtype = kCATransitionFromRight;
//    transition.duration = 1.0;
//    
//    sender.layer.addAnimation(transition, forKey: "transition")
    
    let graduallyAnimation = CABasicAnimation(keyPath: "transform.scale")
    graduallyAnimation.duration = 0.1
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