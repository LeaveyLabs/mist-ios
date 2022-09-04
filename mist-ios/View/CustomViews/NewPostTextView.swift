//
//  UITextField+MaxCharacters.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/01.
//

import Foundation
import UIKit

//LEARNING FROM MISTAKES

//init(coder) is for when created in storyboard
//When using UIView subclasses, they either must be explicitly constructed in
//code like NewPostTextView(), or the view in IB must be classed as NewPostTextView.
//... The reason you don't need to do UIView() for each IBOutlet in xcode is because
//by just connecting the IBOutlet to UIView in storyboard, behind the scenes, UIView() is
//called. So if you want NewPostTextView() to be called, you have to set the view in IB
//to NewPostTextView

//Im choosing not to override the initializers, because I would like to initialize from IB,
//but I would also like to have the ParentVC be passed in the initializer, and I don't know
//how to pass the parentVC through the init(coder) initiailizer / if thats even possible

//The way i fixed the progressCircle / progressLabel positioning:
//either you use autolayout+constraints, or the view's position is caluclated on its own
//setting the .frame.origin or the .center of a view, or calling .sizeToFit(), only work
//when the view does not use constraints
//setting translatesAutoResizingMaskIntoConstraints = false means youre now using/creating your own
//constraints and that seting .frame.origin or .center does nothing
//The other problem I had was that I was setting constraints manually on the subview,
//but the parentView was using TranslatesAutoResizingMask. I fixed the weird appearance by
//adding manual constraints to the parentView (circularProgressView). Perhaps the parent also
//must have manual constraints if the child is going to? or, perhaps this behavior was because
//the way the text was updating in UILabel, how it starting as "" and switched to "9"...
//Regardless, it works fine to set the constraints on both the parent and subview.



class NewPostTextView: UITextView {
    var circularProgressView = CircularProgressView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    var progressLabel: UILabel = UILabel()
    var maxLength: Int!
    
    //MARK: - Constructor
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        setupCircularProgressViewAndLabel()
    }
    
    // Called by parentVC
    func initializerToolbar(target: Any, doneSelector: Selector, withProgressBar: Bool) {
        //Initialize with explicit frame to prevent autolayout warnings
        let toolBar = UIToolbar(frame: CGRect(x: 0.0,
                                              y: 0.0,
                                              width: UIScreen.main.bounds.size.width,
                                              height: 44.0))//1
        toolBar.barTintColor = .white
        
        let progressCircle = UIBarButtonItem.init(customView: circularProgressView)
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)//2
        
        let doneButton = UIBarButtonItem(title: "done", style: .done, target: target, action: doneSelector)
        doneButton.tintColor = .lightGray
        let customAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 17)!]
        doneButton.setTitleTextAttributes(customAttributes, for: .normal)
                
        let items = withProgressBar ? [doneButton, flexible, progressCircle] : [doneButton, flexible]
        toolBar.setItems(items, animated: false)//4
        
        self.inputAccessoryView = toolBar//5
    }
    
    // MARK: - Setup
    
    func setupCircularProgressViewAndLabel() {
        circularProgressView.progress = 0.0
        circularProgressView.trackLineWidth = 3.0
        circularProgressView.trackTintColor = .lightGray.withAlphaComponent(0.2)
        circularProgressView.progressTintColor = Constants.Color.mistLilac
        circularProgressView.roundedProgressLineCap = true
        
        // Constraints
        circularProgressView.translatesAutoresizingMaskIntoConstraints = false
        circularProgressView.widthAnchor.constraint(equalToConstant: circularProgressView.frame.width).isActive = true
        circularProgressView.heightAnchor.constraint(equalToConstant: circularProgressView.frame.height).isActive = true
        
        progressLabel.textAlignment = .center
        progressLabel.font = UIFont(name: Constants.Font.Medium, size: 16)
        progressLabel.textColor = Constants.Color.mistLilac
        
        // Constraints
        circularProgressView.addSubview(progressLabel)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false //when false, setting .center does nothing
        progressLabel.centerXAnchor.constraint(equalTo: circularProgressView.centerXAnchor).isActive = true
        progressLabel.centerYAnchor.constraint(equalTo: circularProgressView.centerYAnchor).isActive = true
    }
    
    // Currently not in use
    func addExplanationButton() {
//        let barButton = UIBarButtonItem(image: UIImage(systemName: "questionmark.circle"), style: .plain, target: target, action: selector)
//        barButton.tintColor = .lightGray
    
//        let explainButton = UIButton()
//        explainButton.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
//        explainButton.setTitle(" How do mists work?", for: .normal)
//        explainButton.tintColor = .lightGray
//        explainButton.setTitleColor(.lightGray, for: .normal)
//        let explainBarButton = UIBarButtonItem.init(customView: explainButton)
    }
    
    
    //MARK: - User Interaction
    
    // Called by parentVC
    func updateProgress() {
        circularProgressView.progress = Float(text.count) / Float(maxLength)
        let charactersRemaining = Int(maxLength) - text.count
        if charactersRemaining < 10 {
            progressLabel.text = String(charactersRemaining)
            if charactersRemaining < 0 {
                circularProgressView.progressTintColor = .red
                progressLabel.textColor = .red
            } else {
                circularProgressView.progressTintColor = Constants.Color.mistLilac
                progressLabel.textColor = Constants.Color.mistLilac
            }
        } else {
            progressLabel.text = ""
        }
    }
}

class NewPostTextField: UITextField {
    
    var circularProgressView = CircularProgressView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    var progressLabel: UILabel = UILabel()
    var maxLength: Int!
        
    //placeholder insets
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 7, dy: 7)
    }
    //text insets
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 7, dy: 7)
    }
    
    //MARK: - Constructor
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        setupCircularProgressViewAndLabel()
    }
    
    // Called by parentVC
    func initializerToolbar(target: Any, doneSelector: Selector, withProgressBar: Bool) {
        //Initialize with explicit frame to prevent autolayout warnings
        let toolBar = UIToolbar(frame: CGRect(x: 0.0,
                                              y: 0.0,
                                              width: UIScreen.main.bounds.size.width,
                                              height: 44.0))//1
        toolBar.barTintColor = .white
        
        let progressCircle = UIBarButtonItem.init(customView: circularProgressView)
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)//2
        
        let doneButton = UIBarButtonItem(title: "done", style: .done, target: target, action: doneSelector)
        doneButton.tintColor = .lightGray
        let customAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 17)!]
        doneButton.setTitleTextAttributes(customAttributes, for: .normal)
        
        //not adding done button for now because this messages with the textview keyboard constraints
        let items = withProgressBar ? [doneButton, flexible, progressCircle] : [doneButton, flexible]
        toolBar.setItems(items, animated: false)//4
        
        self.inputAccessoryView = toolBar//5
    }
    
    // MARK: - Setup
    
    func setupCircularProgressViewAndLabel() {
        circularProgressView.progress = 0.0
        circularProgressView.trackLineWidth = 3.0
        circularProgressView.trackTintColor = .lightGray.withAlphaComponent(0.2)
        circularProgressView.progressTintColor = Constants.Color.mistLilac
        circularProgressView.roundedProgressLineCap = true
        
        // Constraints
        circularProgressView.translatesAutoresizingMaskIntoConstraints = false
        circularProgressView.widthAnchor.constraint(equalToConstant: circularProgressView.frame.width).isActive = true
        circularProgressView.heightAnchor.constraint(equalToConstant: circularProgressView.frame.height).isActive = true
        
        progressLabel.textAlignment = .center
        progressLabel.font = UIFont(name: Constants.Font.Medium, size: 16)
        progressLabel.textColor = Constants.Color.mistLilac
        
        // Constraints
        circularProgressView.addSubview(progressLabel)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false //when false, setting .center does nothing
        progressLabel.centerXAnchor.constraint(equalTo: circularProgressView.centerXAnchor).isActive = true
        progressLabel.centerYAnchor.constraint(equalTo: circularProgressView.centerYAnchor).isActive = true
    }
    
    //MARK: - User Interaction
    
    // Called by parentVC
    func updateProgress() {
        let textCount = text?.count ?? 0
        circularProgressView.progress = Float(textCount) / Float(maxLength)
        let charactersRemaining = Int(maxLength) - textCount
        if charactersRemaining < 10 {
            progressLabel.text = String(charactersRemaining)
            if charactersRemaining < 0 {
                circularProgressView.progressTintColor = .red
                progressLabel.textColor = .red
            } else {
                circularProgressView.progressTintColor = Constants.Color.mistLilac
                progressLabel.textColor = Constants.Color.mistLilac
            }
        } else {
            progressLabel.text = ""
        }
    }
}
