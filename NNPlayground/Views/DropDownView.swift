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
    var labelIsSelected = 0 {
        didSet{
            tableView.reloadData()
        }
    }
    
    var dropDownButton:DropDownButton?
    var showSelectedLabel: ((_ name: String,_ num:Int) -> Void)?
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    lazy var tableView: UITableView = {
        let view = UITableView()
        
        view.dataSource = self
        view.delegate = self
        view.rowHeight = 60
        view.isScrollEnabled = true
        view.separatorStyle = .none
        view.register(UINib(nibName: "DropDownCell", bundle: nil), forCellReuseIdentifier: "DropDownCell")
        return view
    }()
    
    func showInView(_ view: UIView,button: DropDownButton) {
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
        UIView.animate(withDuration: Double(labelName.count) * 0.02, delay: 0.0, options: .transitionCurlUp, animations: {
        }, completion: { _ in
        })
//        UIView.animate(withDuration: Double(labelName.count) * 0.02, delay: 0.0, options: .transitionCurlUp, animations: {[weak self]  _ in
//            if let strongSelf = self {
//                if (strongSelf.dropDownButton) != nil {
//                    strongSelf.tableView.frame = CGRect(x: (strongSelf.dropDownButton?.frame.minX)!, y: (strongSelf.dropDownButton?.frame.maxY)!, width: (strongSelf.dropDownButton?.frame.width)!, height: strongSelf.totalHeight)
//                }
//            }
//
//            self?.layoutIfNeeded()
//
//            }, completion: { _ in
//        })
    }
    
    @objc func hide() {
        
        UIView.animate(withDuration: Double(labelName.count) * 0.02, delay: 0.0, options: .transitionCurlDown, animations: {
            
            if (self.dropDownButton) != nil {
                self.tableView.frame = CGRect(x: (self.dropDownButton?.frame.minX)!, y: (self.dropDownButton?.frame.maxY)!, width: (self.dropDownButton?.frame.width)!, height: 0)
            }
            
            self.layoutIfNeeded()
            
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
        
        let containerViewConstraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[containerView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let containerViewConstraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[containerView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activate(containerViewConstraintsH)
        NSLayoutConstraint.activate(containerViewConstraintsV)
        
        // layout for tableView
        
        if (dropDownButton) != nil {
            tableView.frame = CGRect(x: (dropDownButton?.frame.minX)!, y: (dropDownButton?.frame.maxY)!, width: (dropDownButton?.frame.width)!, height: self.totalHeight)
        }
        
    }

}

extension DropDownView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if touch.view != containerView {
            return false
        }
        
        return true
    }

}

extension DropDownView: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return labelName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DropDownCell") as! DropDownCell
        cell.detailLabel.text = labelName[(indexPath as NSIndexPath).row]
        if (indexPath as NSIndexPath).row == labelIsSelected {
            cell.isSelectedImage.isHidden = false
        }
        else {
            cell.isSelectedImage.isHidden = true
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        if tableView.cellForRow(at: IndexPath(row: labelIsSelected, section: 0)) != nil {
            (tableView.cellForRow(at: IndexPath(row: labelIsSelected, section: 0)) as! DropDownCell).isSelectedImage.isHidden = true
        }
        labelIsSelected = (indexPath as NSIndexPath).row
        (tableView.cellForRow(at: IndexPath(row: labelIsSelected, section: 0)) as! DropDownCell).isSelectedImage.isHidden = false
        
        showSelectedLabel?("\(labelName[(indexPath as NSIndexPath).row])", (indexPath as NSIndexPath).row)
    }
}
