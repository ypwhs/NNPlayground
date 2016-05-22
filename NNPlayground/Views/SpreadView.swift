//
//  SpreadView.swift
//  UIPlayground
//
//  Created by 陈禹志 on 16/4/26.
//  Copyright © 2016年 com.insta. All rights reserved.
//

import UIKit

class SpreadView: UIView {
    
    var layers = 3
    var buttonWidth:CGFloat = 30
    var subNodeButtonY:CGFloat = 114
    var blueColor = UIColor(red: 0x64/0xFF, green: 0xB5/0xFF, blue: 0xF6/0xFF, alpha: 1.0)
    
    
    @IBAction func Regenerate(sender: UIButton) {
        //setData
        setCircleData?()
        resetAlpha(setCircleButton)
        
        //slider
        setRatioSlider.setValue(0.5, animated: true)
        setRatioLabel.text = "训练数据百分比：50%"
        setRatio?(current: 4)
        setNoiseSlider.setValue(0, animated: true)
        setNoiseLabel.text = "噪声：0"
        setNoise?(current: 0)
        setBatchSizeSlider.setValue(0.333333333, animated: true)
        setBatchSizeLabel.text = "批量大小：10"
        setBatchSize?(current: 9)
        
        //addLayer
        layers = 3
        addLayer?()
        addNodeButton[0].hidden = false
        subNodeButton[0].hidden = false
        for i in 1...5 {
            addNodeButton[i].hidden = true
            subNodeButton[i].hidden = true
        }
        addLayerLabel.text = "隐藏层数：\(layers-2)"
        
        //addNode
        
        //dropDown
        learningRateDropView.showSelectedLabel?(name: "0.03", num: 5)
        learningRateDropView.labelIsSelected = 5
        activationDropView.showSelectedLabel?(name: "Tanh", num: 1)
        activationDropView.labelIsSelected = 1
        regularizationDropView.showSelectedLabel?(name: "None", num: 0)
        regularizationDropView.labelIsSelected = 0
        regularizationRateDropView.showSelectedLabel?(name: "0", num: 0)
        regularizationRateDropView.labelIsSelected = 0
    }
    
    // MARK: - Introduce
//    private lazy var introduceDropWebView: DropWebView = {
//        let view = DropWebView()
//        return view
//    }()
    var introduce: ((url: NSURL) -> Void)?
    @IBAction func IntroduceAction(sender: UIButton) {
//        if let window = self.window {
//            introduceDropWebView.showInView(window, button: sender, url: "https://ypwhs.gitbooks.io/nnplayground/content/")
//        }
        //        openURL(NSURL(string: "https://ypwhs.gitbooks.io/nnplayground/content/"))
        
        self.hide()
        introduce?(url: NSURL(string: "https://ypwhs.gitbooks.io/nnplayground/content/")!)
    }
    // MARK: - SetData
    var setCircleData: (() -> Void)?
    var setExclusiveOrData: (() -> Void)?
    var setGaussianData: (() -> Void)?
    var setSpiralData: (() -> Void)?
    
    @IBOutlet weak var setCircleButton: SelectDataButton!
    @IBOutlet weak var setExclusiveOrButton: SelectDataButton!
    @IBOutlet weak var setGaussianButton: SelectDataButton!
    @IBOutlet weak var setSpiralButton: SelectDataButton!
    func resetAlpha(sender: SelectDataButton) {
        let setDataButtons = [setCircleButton,setExclusiveOrButton,setGaussianButton,setSpiralButton]
        for i in setDataButtons {
            if i == sender {
                i.isChosen = true
            }
            else {
                i.isChosen = false
            }
        }
    }
    
    @IBAction func setCircle(sender: SelectDataButton) {
        setCircleData?()
        resetAlpha(sender)
    }
    @IBAction func setExclusiveOr(sender: SelectDataButton) {
        setExclusiveOrData?()
        resetAlpha(sender)
    }
    @IBAction func setGaussian(sender: SelectDataButton) {
        setGaussianData?()
        resetAlpha(sender)
    }
    @IBAction func setSpiral(sender: SelectDataButton) {
        setSpiralData?()
        resetAlpha(sender)
    }
    
    // MARK: - UISlider
    var setRatio: ((current: Int) -> Void)?
    var setNoise: ((current: Int) -> Void)?
    var setBatchSize: ((current: Int) -> Void)?
    
    @IBOutlet weak var setRatioSlider: EasySlider!
    @IBOutlet weak var setNoiseSlider: EasySlider!
    @IBOutlet weak var setBatchSizeSlider: EasySlider!
    @IBOutlet weak var setRatioLabel: UILabel!
    @IBOutlet weak var setNoiseLabel: UILabel!
    @IBOutlet weak var setBatchSizeLabel: UILabel!
    
    func setSpacing(sender: EasySlider, total: Float) -> Int {
        let spacing = (sender.maximumValue - sender.minimumValue)/total
        let num = Int(sender.value/spacing)
        sender.setValue(Float(num)*spacing, animated: true)
        return num
    }
    
    @IBAction func setRatioAction(sender: EasySlider) {
        let num = setSpacing(sender, total: 8)
        setRatio?(current: num)
        setRatioLabel.text = "训练数据百分比：\(num + 1)0%"
    }
    @IBAction func setNoiseAction(sender: EasySlider) {
        let num = setSpacing(sender, total: 10)
        setNoise?(current: num)
        setNoiseLabel.text = "噪声：\(num)"
    }
    @IBAction func setBatchSizeAction(sender: EasySlider) {
        let num = setSpacing(sender, total: 29)
        setBatchSize?(current: num)
        setBatchSizeLabel.text = "批量大小：\(num + 1)"
    }
    
    // MARK: - AddLayer
    var addLayer: (() -> Void)?
    @IBOutlet weak var addLayerLabel: UILabel!
    
    func addLayerButtons(sender:AddButton) {
        if sender.isAddButton && layers < 8 {
            layers += 1
            addNodeButton[layers - 3].hidden = false
            subNodeButton[layers - 3].hidden = false
            if !addNodeButton[layers - 4].enabled {
                addNodeButton[layers - 3].strokeColor = UIColor.lightGrayColor()
                addNodeButton[layers - 3].enabled = false
            }
            if !subNodeButton[layers - 4].enabled {
                subNodeButton[layers - 3].strokeColor = UIColor.lightGrayColor()
                subNodeButton[layers - 3].enabled = false
            }
        }
        if !sender.isAddButton && layers > 2 {
            layers -= 1
            addNodeButton[layers - 2].hidden = true
            subNodeButton[layers - 2].hidden = true
        }
        addLayer?()
        
        if layers == 8 {
            addLayerButton.strokeColor = UIColor.lightGrayColor()
            addLayerButton.enabled = false
        }
        else {
            addLayerButton.strokeColor = blueColor
            addLayerButton.enabled = true
        }
        if layers == 2 {
            subLayerButton.strokeColor = UIColor.lightGrayColor()
            subLayerButton.enabled = false
        }
        else {
            subLayerButton.strokeColor = blueColor
            subLayerButton.enabled = true
        }
        addLayerLabel.text = "隐藏层数：\(layers-2)"
    }
    
    @IBOutlet weak var addLayerButton: AddButton!
    @IBOutlet weak var subLayerButton: AddButton!
    @IBAction func addLayerAction(sender: AddButton) {
        addLayerButtons(sender)
    }
    @IBAction func subLayerAction(sender: AddButton) {
        addLayerButtons(sender)
    }
    
    // MARK: - AddNode
    var addNode: ((layer: Int, isAdd: Bool) -> Int)?
    func addNodeAction(sender:AddButton) {
        var num = 1
        var nodes = 4
        if sender.isAddButton {
            for i in addNodeButton {
                if i == sender {
                    nodes = addNode!(layer: num, isAdd: true)
                    break
                }
                num += 1
            }
        }
        else {
            for i in subNodeButton {
                if i == sender {
                    nodes = addNode!(layer: num, isAdd: false)
                    break
                }
                num += 1
            }
        }
        if nodes == 8 || nodes == 1 {
            sender.strokeColor = UIColor.lightGrayColor()
            sender.enabled = false
        }
        else{
            if sender.isAddButton {
                subNodeButton[num - 1].strokeColor = blueColor
                subNodeButton[num - 1].enabled = true
            }
            else {
                addNodeButton[num - 1].strokeColor = blueColor
                addNodeButton[num - 1].enabled = true
            }
        }
        
    }
    
    lazy var addNodeButton: [AddButton] = {
        let view = AddButton()
        view.frame = CGRect(x: 50, y: 100, width: 30, height: 30)
        view.addTarget(self, action: #selector(addNodeAction), forControlEvents: .TouchUpInside)
        var views = [view]
        for i in 2...6 {
            let view = AddButton()
            view.frame = CGRect(x: i*50, y: 100, width: 30, height: 30)
            view.addTarget(self, action: #selector(addNodeAction), forControlEvents: .TouchUpInside)
            views.append(view)
        }
        return views
    }()
    
    lazy var subNodeButton: [AddButton] = {
        let view = AddButton()
        view.frame = CGRect(x: 50, y: 150, width: 30, height: 30)
        view.isAddButton = false
        view.addTarget(self, action: #selector(addNodeAction), forControlEvents: .TouchUpInside)
        var views = [view]
        for i in 2...6 {
            let view = AddButton()
            view.isAddButton = false
            view.frame = CGRect(x: i*50, y: 150, width: 30, height: 30)
            view.addTarget(self, action: #selector(addNodeAction), forControlEvents: .TouchUpInside)
            views.append(view)
        }
        return views
    }()

    // MARK: - DropDown
    @IBOutlet weak var learningRateButton: DropDownButton!
    var setLearningRate: ((num: Int) -> Void)?
    private lazy var learningRateDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["0.00001","0.0001","0.001","0.003","0.01","0.03","0.1","0.3","1","3","10"]
        view.showSelectedLabel = {(name: String, num: Int) in
            self.learningRateButton.setTitle(name, forState: .Normal)
            view.hide()
            self.setLearningRate?(num: num)
        }
        view.labelIsSelected = 5
        return view
    }()
    @IBAction func learningRateDrop(sender: DropDownButton) {
        if let window = self.window {
            learningRateDropView.showInView(window,button: sender)
        }
    }
    
    
    @IBOutlet weak var activationButton: DropDownButton!
    var setActivation: ((num: Int) -> Void)?
    private lazy var activationDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["ReLU","Tanh","Sigmoid","Linear"]
        view.showSelectedLabel = {(name: String, num: Int) in
            self.activationButton.setTitle(name, forState: .Normal)
            view.hide()
            self.setActivation?(num: num)
        }
        view.labelIsSelected = 1
        return view
    }()
    @IBAction func activationDrop(sender: DropDownButton) {
        if let window = self.window {
            activationDropView.showInView(window,button: sender)
        }
    }
    
    
    @IBOutlet weak var regularizationButton: DropDownButton!
    var setRegularization: ((num: Int) -> Void)?
    private lazy var regularizationDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["None","L1","L2"]
        view.showSelectedLabel = {(name: String, num: Int) in
            self.regularizationButton.setTitle(name, forState: .Normal)
            view.hide()
            self.setRegularization?(num: num)
        }
        view.labelIsSelected = 0
        return view
    }()
    @IBAction func regularizationDrop(sender: DropDownButton) {
        if let window = self.window {
            regularizationDropView.showInView(window,button: sender)
        }
    }
    
    
    @IBOutlet weak var regularizationRateButton: DropDownButton!
    var setRegularizationRate: ((num: Int) -> Void)?
    private lazy var regularizationRateDropView: DropDownView = {
        let view = DropDownView()
        view.labelName = ["0","0.001","0.003","0.01","0.03","0.1","0.3","1","3","10"]
        view.showSelectedLabel = {(name: String, num: Int) in
            self.regularizationRateButton.setTitle(name, forState: .Normal)
            view.hide()
            self.setRegularizationRate?(num: num)
        }
        view.labelIsSelected = 0
        return view
    }()
    @IBAction func regularizationRateDrop(sender: DropDownButton) {
        if let window = self.window {
            regularizationRateDropView.showInView(window,button: sender)
        }
    }
        
    //MARK: - View
    func showInView(view:UIView) {
        frame = view.bounds
        view.addSubview(self)
        
        layoutIfNeeded()
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseIn, animations: {[weak self]  _ in
            self?.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)
            }, completion: { _ in
        })
        
    }
    
    func hide() {
        UIView.animateWithDuration(0.2, delay: 0.1, options: .CurveEaseOut, animations: {[weak self]  _ in
            self?.backgroundColor = UIColor.clearColor()
            }, completion: {[weak self]  _ in
                self?.removeFromSuperview()
            })
    }
    
    var isFirstTimeBeenAddAsSubview = true
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if isFirstTimeBeenAddAsSubview {
            isFirstTimeBeenAddAsSubview = false
            
            makeUI()
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(SpreadView.hide))
            self.addGestureRecognizer(tap)
            
            tap.cancelsTouchesInView = true
            tap.delegate = self
        }
    }
    
    func makeUI() {
        setCircleButton.isChosen = true
        
        let setDataButtonWidth = NSLayoutConstraint(item: setCircleButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: buttonWidth + 10)
        let addLayerButtonWidth = NSLayoutConstraint(item: addLayerButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: buttonWidth)
        NSLayoutConstraint.activateConstraints([setDataButtonWidth,addLayerButtonWidth])
        
        self.layoutIfNeeded()
        
        subNodeButtonY = setRatioSlider.frame.minY
        for i in 0...5 {
            self.addSubview(addNodeButton[i])
            (addNodeButton[i] as AddButton).frame.origin = CGPoint(x: (addNodeButton[i] as AddButton).frame.minX, y: subNodeButtonY + 2 * buttonWidth)
            self.addSubview(subNodeButton[i])
            (subNodeButton[i] as AddButton).frame.origin = CGPoint(x: (subNodeButton[i] as AddButton).frame.minX, y: subNodeButtonY)
            if i != 0 {
                addNodeButton[i].hidden = true
                subNodeButton[i].hidden = true
            }
        }
        
    }
    
}

extension SpreadView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if touch.view != self {
            return false
        }
        return true
    }
    
}
