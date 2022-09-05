//
//  WhatIsMistboxViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/29/22.
//

import Foundation
import UIKit

class WhatIsMistboxViewController: UIViewController, LargeImageCollectionCellDelegate {
    
    let images: [UIImage] = [
        UIImage(named: "mistbox-graphic-1")!,
        UIImage(named: "mistbox-graphic-2")!,
        UIImage(named: "mistbox-graphic-3")!,
        UIImage(named: "mistbox-graphic-4")!
    ]
    
    let guidelinesLabel = UILabel()
    let pageControl = UIPageControl()
    var collectionView: UICollectionView!
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupPageControl()
        setupGuidelinesLabel()
    }
    
    var didAppear = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !didAppear {
            collectionView.frame = view.safeAreaLayoutGuide.layoutFrame
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didAppear = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    //MARK: - Setup
    
    func setupCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        let size = UIScreen.main.bounds.size
        flowLayout.itemSize = CGSize(width: size.width, height: size.height)
        
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: flowLayout)
        collectionView.isPagingEnabled = true
        
        view.addSubview(collectionView)
        view.addSubview(pageControl)
        collectionView.register(LargeImageAndButtonCollectionCell.self, forCellWithReuseIdentifier: String(describing: LargeImageAndButtonCollectionCell.self))
        collectionView.reloadData()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = true
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    func setupPageControl() {
        pageControl.numberOfPages = images.count
        pageControl.pageIndicatorTintColor = Constants.Color.mistLilac.withAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = Constants.Color.mistLilac
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.widthAnchor.constraint(equalToConstant: 200),
            pageControl.heightAnchor.constraint(equalToConstant: 40),
            pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(window?.safeAreaInsets.bottom ?? 0)),
        ])
    }
    
    func setupGuidelinesLabel() {
        guidelinesLabel.text = "mistbox"
        guidelinesLabel.font = UIFont(name: Constants.Font.Heavy, size: 50)
        guidelinesLabel.textColor = Constants.Color.mistBlack
        guidelinesLabel.numberOfLines = 1
        guidelinesLabel.minimumScaleFactor = 0.5
        guidelinesLabel.textAlignment = .center
        guidelinesLabel.adjustsFontSizeToFitWidth = true
        guidelinesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guidelinesLabel)
        NSLayoutConstraint.activate([
            guidelinesLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guidelinesLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -60),
            guidelinesLabel.heightAnchor.constraint(equalToConstant: 70),
            guidelinesLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20 + (window?.safeAreaInsets.bottom ?? 0) / 2),
        ])
    }
    
    //MARK: - Helpers
    
    func closeButtonPressed() {
        dismiss(animated: true)
    }
}

extension WhatIsMistboxViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: LargeImageAndButtonCollectionCell.self), for: indexPath) as! LargeImageAndButtonCollectionCell
        cell.setup(image: images[indexPath.section], delegate: self, index: indexPath.section)
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }
}

extension WhatIsMistboxViewController: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        recalculatePageControlCurrentPage(scrollView)
    }
    
    func recalculatePageControlCurrentPage(_ scrollView: UIScrollView) {
        let offSet = scrollView.contentOffset.x
        let width = scrollView.frame.width
        let horizontalCenter = width / 2
        pageControl.currentPage = Int(offSet + horizontalCenter) / Int(width)
    }
    
}
