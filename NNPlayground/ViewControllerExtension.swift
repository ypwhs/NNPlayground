//
//  ViewControllerExtension.swift
//  NNPlayground
//
//  Created by 陈禹志 on 16/5/21.
//  Copyright © 2016年 杨培文. All rights reserved.
//

import UIKit
import SafariServices

extension UIViewController {
    func exOpenURL(URL: NSURL) {
        if #available(iOS 9.0, *) {
            let safariViewController = SFSafariViewController(URL: URL)
            presentViewController(safariViewController, animated: true, completion: nil)
            
        } else {
            UIApplication.sharedApplication().openURL(URL)
        }
        
    }
}
