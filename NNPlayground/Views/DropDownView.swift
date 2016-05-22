//
//  DropDownView.swift
//  UIPlayground
//
//  Created by 陈禹志 on 16/4/25.
//  Copyright © 2016年 com.insta. All rights reserved.
//

import UIKit

class DropDownView: UIView {

    var totalHeight: CGFloat = 60 * 4
    var labelName: [String] = [""]
    var labelIsSelected = 0
    
    var dropDownButton:DropDownButton?
    var showSelectedLabel: ((name: String,num:Int) -> Void)?
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        return view
    }()
    
    lazy var tableView: UITableView = {
        let view = UITableView()
        
        view.dataSource = self
        view.delegate = self
        view.rowHeight = 60
        view.scrollEnabled = true
        view.separatorStyle = .None
        view.registerNib(UINib(nibName: "DropDownCell", bundle: nil), forCellReuseIdentifier: "DropDownCell")
        return view
    }()
    
    func showInView(view: UIView,button: DropDownButton) {
        frame = view.bounds
        dropDownButton = button
        if (dropDownButton) != nil {
            totalHeight = (dropDownButton?.frame.height)! * CGFloat(labelName.count)
            tableView.rowHeight = (dropDownButton?.frame.height)!
            if totalHeight > frame.height - (dropDownButton?.frame.maxY)! {
                totalHeight = frame.height - (dropDownButton?.frame.maxY)! - 10
            }
        }
        
        view.addSubview(self)
        
        layoutIfNeeded()
        
        containerView.alpha = 1
        
        UIView.animateWithDuration(Double(labelName.count) * 0.02, delay: 0.0, options: .TransitionCurlUp, animations: {[weak self]  _ in
            if let strongSelf = self {
                if (strongSelf.dropDownButton) != nil {
                    strongSelf.tableView.frame = CGRect(x: (strongSelf.dropDownButton?.frame.minX)!, y: (strongSelf.dropDownButton?.frame.maxY)!, width: (strongSelf.dropDownButton?.frame.width)!, height: strongSelf.totalHeight)
                }
            }
            
            self?.layoutIfNeeded()
            
            }, completion: { _ in
        })
    }
    
    func hide() {
        
        UIView.animateWithDuration(Double(labelName.count) * 0.02, delay: 0.0, options: .TransitionCurlDown, animations: {[weak self]  _ in
            
            if let strongSelf = self {
                if (strongSelf.dropDownButton) != nil {
                    strongSelf.tableView.frame = CGRect(x: (strongSelf.dropDownButton?.frame.minX)!, y: (strongSelf.dropDownButton?.frame.maxY)!, width: (strongSelf.dropDownButton?.frame.width)!, height: 0)
                }
            }
            
            self?.layoutIfNeeded()
            
            }, completion: {[weak self] _ in
                self?.removeFromSuperview()
        })
    }
    
    var isFirstTimeBeenAddAsSubview = true
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if isFirstTimeBeenAddAsSubview {
            isFirstTimeBeenAddAsSubview = false
            
            makeUI()
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(DropDownView.hide))
            containerView.addGestureRecognizer(tap)
            
            tap.cancelsTouchesInView = true
            tap.delegate = self
        }
    }
    
    func makeUI() {
        
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        let viewsDictionary = [
            "containerView": containerView,
            "tableView": tableView,
            ]
        
        // layout for containerView
        
        let containerViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[containerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let containerViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[containerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(containerViewConstraintsH)
        NSLayoutConstraint.activateConstraints(containerViewConstraintsV)
        
        // layout for tableView
        
        if (dropDownButton) != nil {
            tableView.frame = CGRect(x: (dropDownButton?.frame.minX)!, y: (dropDownButton?.frame.maxY)!, width: (dropDownButton?.frame.width)!, height: self.totalHeight)
        }
        
    }

}

extension DropDownView: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        if touch.view != containerView {
            return false
        }
        
        return true
    }

}

extension DropDownView: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return labelName.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DropDownCell") as! DropDownCell
        cell.detailLabel.text = labelName[indexPath.row]
        if indexPath.row == labelIsSelected {
            cell.isSelectedImage.hidden = false
        }
        else {
            cell.isSelectedImage.hidden = true
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        if tableView.cellForRowAtIndexPath(NSIndexPath(forRow: labelIsSelected, inSection: 0)) != nil {
            (tableView.cellForRowAtIndexPath(NSIndexPath(forRow: labelIsSelected, inSection: 0)) as! DropDownCell).isSelectedImage.hidden = true
        }
        labelIsSelected = indexPath.row
        (tableView.cellForRowAtIndexPath(NSIndexPath(forRow: labelIsSelected, inSection: 0)) as! DropDownCell).isSelectedImage.hidden = false
        
        showSelectedLabel?(name: "\(labelName[indexPath.row])", num: indexPath.row)
    }
}
