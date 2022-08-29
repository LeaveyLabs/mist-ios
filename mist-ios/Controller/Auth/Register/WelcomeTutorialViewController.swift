//
//  WelcomeTutorialViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 4/6/22.
//

import UIKit

class WelcomeTutorialViewController: UIViewController {
    
    let images: [UIImage] = [
        UIImage(named: "auth-graphic-text-1")!,
        UIImage(named: "auth-graphic-text-2")!,
        UIImage(named: "auth-graphic-text-3")!
    ]
    
    var hasContinued = false
    var visibleIndex: Int? = 0
    
    let pageControl = UIPageControl()
    var collectionView: UICollectionView!
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupPageControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        collectionView.frame = view.safeAreaLayoutGuide.layoutFrame
        view.bringSubviewToFront(pageControl)
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
        collectionView.register(CollectionImageCell.self, forCellWithReuseIdentifier: String(describing: CollectionImageCell.self))
        
  //      let nib = UINib(nibName: String(describing: CreateProfileCollectionViewCell.self), bundle: nil)
  //      collectionView.register(nib, forCellWithReuseIdentifier: String(describing: CreateProfileCollectionViewCell.self))
        collectionView.reloadData()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = true
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    func setupPageControl() {
        pageControl.numberOfPages = images.count + 1
        pageControl.pageIndicatorTintColor = Constants.Color.mistLilac.withAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = Constants.Color.mistLilac
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.widthAnchor.constraint(equalToConstant: 200),
            pageControl.heightAnchor.constraint(equalToConstant: 100),
            pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(window?.safeAreaInsets.bottom ?? 0)),
        ])
    }
    
    //MARK: - Helpers
    
    func tryToContinue() {
        let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.CreateProfile)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension WelcomeTutorialViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CollectionImageCell.self), for: indexPath) as! CollectionImageCell
        cell.setup(image: images[indexPath.section])
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }
}

extension WelcomeTutorialViewController: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let xvelocity = collectionView.panGestureRecognizer.velocity(in: view).x
        let xtranslation = collectionView.panGestureRecognizer.translation(in: view).x
        if let visibleIndex = visibleIndex, visibleIndex == 2, xtranslation < 0 {
            if !hasContinued {
                hasContinued = true
                tryToContinue()
            }
        }
        
        
        recalculatePageControlCurrentPage(scrollView)
    }
    
    func recalculatePageControlCurrentPage(_ scrollView: UIScrollView) {
        let offSet = scrollView.contentOffset.x
        let width = scrollView.frame.width
        let horizontalCenter = width / 2
        pageControl.currentPage = Int(offSet + horizontalCenter) / Int(width)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        stoppedScrolling()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            stoppedScrolling()
        }
    }
    
    func stoppedScrolling() {
        visibleIndex = collectionView.indexPathsForVisibleItems.first?.section
    }
    
}
