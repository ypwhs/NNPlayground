//
//  DropDownCell.swift
//  UIPlayground
//
//  Created by 陈禹志 on 16/5/4.
//  Copyright © 2016年 com.insta. All rights reserved.
//

import UIKit

class DropDownCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBOutlet weak var isSelectedImage: UIImageView!
    
    @IBOutlet weak var detailLabel: UILabel!
}
