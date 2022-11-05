////
////  ExploreMapContainerView.swift
////  mist-ios
////
////  Created by Adam Novak on 2022/10/13.
////
//
//import Foundation
//
//class ExploreMapContainerView: UIView {
//
//    //MARK: - Properties
//
//    //UI
//
//
//    @IBOutlet weak var searchButton: UIButton!
//    @IBOutlet weak var filterButton: UIButton!
//    @IBOutlet weak var reloadButton: UIButton!
//
//    //Delegate
//    var feedToggleViewDelegate: FeedToggleViewDelegate!
//
//    //Constants
//    let SELECTED_FONT = UIFont(name: Constants.Font.Heavy, size: 18)
//    let DESELECTED_FONT = UIFont(name: Constants.Font.Roman, size: 18)
//
//    //MARK: - Constructors
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        customInit()
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        customInit()
//    }
//
//    //OHHHH and i gotta detect that...
//
//    private func customInit() {
//        viewInit()
//        backgroundView.applyLightMediumShadow()
//        backgroundView.roundCornersViaCornerRadius(radius: 7)
//        backgroundColor = .clear
//        backgroundView.backgroundColor = .white
//
//        let tapOne = UITapGestureRecognizer(target: self, action: #selector(labelOneTap))
//        labelOne.addGestureRecognizer(tapOne)
//        let tapTwo = UITapGestureRecognizer(target: self, action: #selector(labelTwoTap))
//        labelTwo.addGestureRecognizer(tapTwo)
//        let tapThree = UITapGestureRecognizer(target: self, action: #selector(labelThreeTap))
//        labelThree.addGestureRecognizer(tapThree)
//        let tapFour = UITapGestureRecognizer(target: self, action: #selector(labelFourTap))
//        labelFour.addGestureRecognizer(tapFour)
//    }
//
//    private func viewInit() {
//        guard let contentView = loadViewFromNib(nibName: "FeedToggleView") else { return }
//        contentView.frame = self.bounds
//        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        addSubview(contentView)
//    }
//
//    private func deselectAllLabels() {
//        for index in 0..<labels.count {
//            deselectLabel(index: index)
//        }
//    }
//
//    private func deselectLabel(index: Int) {
//        let label = labels[index]
//        label.font = DESELECTED_FONT
//        label.textColor = .systemGray
//    }
//
//    private func selectLabel(index: Int) {
//        let label = labels[index]
//        label.font = SELECTED_FONT
//        label.textColor = Constants.Color.mistBlack
//    }
//
//    //MARK: - UserInteraction
//
//    @objc private func labelOneTap() {
//        feedToggleViewDelegate.labelDidTapped(index: 0)
//    }
//
//    @objc private func labelTwoTap() {
//        feedToggleViewDelegate.labelDidTapped(index: 1)
//    }
//
//    @objc private func labelThreeTap() {
//        feedToggleViewDelegate.labelDidTapped(index: 2)
//    }
//
//    @objc private func labelFourTap() {
//        feedToggleViewDelegate.labelDidTapped(index: 3)
//    }
//
//}
//
////MARK: - Public Interface
//
//extension ExploreMapContainerView {
//
//    // Note: the constraints for the PostView should already be set-up when this is called.
//    // Otherwise you'll get loads of constraint errors in the console
//    func configure(labelNames: [String],
//                   startingSelectedIndex: Int,
//                   delegate: FeedToggleViewDelegate) {
//        guard startingSelectedIndex < labelNames.count && startingSelectedIndex >= 0 else {
//            fatalError("selected index greater than names")
//        }
//        for index in 0..<labelNames.count {
//            labels[index].text = labelNames[index]
//        }
//        for index in labelNames.count..<labels.count {
//            labels[index].isHidden = true
//        }
//        deselectAllLabels()
//        selectLabel(index: startingSelectedIndex)
//        self.feedToggleViewDelegate = delegate
//    }
//
//    func toggleFeed(labelIndex: Int) {
//        guard labelIndex >= 0 && labelIndex < labels.count else { return }
//        deselectAllLabels()
//        selectLabel(index: labelIndex)
//    }
//
//}
