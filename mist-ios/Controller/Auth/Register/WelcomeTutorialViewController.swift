//
//  WelcomeTutorialViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 4/6/22.
//

import UIKit

final class CVCell: UICollectionViewCell {
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
                
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -60),
            imageView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.8),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
    }
    
    func setup(image: UIImage ) {
        imageView.image = image
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class WelcomeTutorialViewController: UIViewController {
    
    let images: [UIImage] = [
        UIImage(named: "auth-graphic-text-1")!,
        UIImage(named: "auth-graphic-text-2")!,
        UIImage(named: "auth-graphic-text-3")!
    ]
    
  let pageControl = UIPageControl()
    var collectionView: UICollectionView!

  override func viewDidLoad() {
      super.viewDidLoad()
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
        pageControl.numberOfPages = images.count
        pageControl.tintColor = .black
      collectionView.register(CVCell.self, forCellWithReuseIdentifier: String(describing: CVCell.self))
        collectionView.reloadData()
        collectionView.dataSource = self
      collectionView.bounces = false
//        collectionView.isAutoscrollEnabled = false
      collectionView.showsHorizontalScrollIndicator = false
  }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.frame = view.bounds
        pageControl.frame.origin.y = view.bounds.maxY - 80 - pageControl.frame.height
        pageControl.sizeToFit()
        pageControl.tintColor = Constants.Color.mistLilac
    }
}

extension WelcomeTutorialViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CVCell.self), for: indexPath) as! CVCell
        cell.setup(image: images[indexPath.section])
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }
    
//    var numberOfItems: Int {
//        return images.count
//    }
//
//    func carouselCollectionView(_ carouselCollectionView: CarouselCollectionView, cellForItemAt index: Int, fakeIndexPath: IndexPath) -> UICollectionViewCell {
//    }
//
//    func carouselCollectionView(_ carouselCollectionView: CarouselCollectionView, didSelectItemAt index: Int) {
//        print("Did select item at \(index)")
//    }
//
//    func carouselCollectionView(_ carouselCollectionView: CarouselCollectionView, didDisplayItemAt index: Int) {
//        pageControl.currentPage = index
//    }
}
