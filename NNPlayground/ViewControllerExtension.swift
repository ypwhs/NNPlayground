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
    func exOpenURL(_ URL: Foundation.URL) {
        if #available(iOS 9.0, *) {
            let safariViewController = SFSafariViewController(url: URL)
            present(safariViewController, animated: true, completion: nil)
            
        } else {
            UIApplication.shared.openURL(URL)
        }
        
    }
}
