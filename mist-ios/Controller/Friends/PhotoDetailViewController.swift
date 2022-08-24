//
//  ImageDetailViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/23/22.
//

import UIKit

class PhotoDetailViewController: UIViewController {

    var photo: UIImage!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!

    class func create(photo: UIImage) -> PhotoDetailViewController {
        let photoDetailVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.PhotoDetail) as! PhotoDetailViewController
        photoDetailVC.photo = photo
        return photoDetailVC
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
     
   override func viewDidLoad() {
       super.viewDidLoad()
       scrollView.minimumZoomScale = 1.0
       scrollView.maximumZoomScale = 6.0
       photoImageView.image = photo
       photoImageView.contentMode = .scaleAspectFit
       scrollView.delegate = self
       scrollView.showsVerticalScrollIndicator = false
       scrollView.showsHorizontalScrollIndicator = false
       scrollView.alwaysBounceVertical = false
       scrollView.alwaysBounceHorizontal = false
   }
    
    @IBAction func didPressX() {
        dismiss(animated: true)
    }
}

extension PhotoDetailViewController: UIScrollViewDelegate {
    
     func viewForZooming(in scrollView: UIScrollView) -> UIView? {
         return photoImageView
     }
    
}

