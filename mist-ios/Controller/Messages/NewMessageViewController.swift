//
//  DmViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/12.
//

import UIKit

class NewMessageViewController: UIViewController {

    @IBOutlet weak var moreButton: UIBarButtonItem!
    @IBOutlet weak var authorProfilePic: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authorProfilePic.image = blurEffect(image: authorProfilePic.image!)
        
        
        //from map view controller
        
//        let cell = Bundle.main.loadNibNamed(Constants.SBID.Cell.Post, owner: self, options: nil)?[0] as! PostCell
//        if let mapModalPost = post {
//            cell.configurePostCell(post: mapModalPost, parent: self, bubbleArrowPosition: .bottom)
//        }
//
//        let postView = cell.contentView
//        if let newPostView = postView {
//            newPostView.translatesAutoresizingMaskIntoConstraints = false //allows programmatic settings of constraints
//            view.addSubview(newPostView)
//            let constraints = [
////                newPostView.topAnchor.constraint(equalTo: dateSliderOuterView.bottomAnchor, constant: 0),
//                newPostView.centerYAnchor.constraint(equalTo: mapView.centerYAnchor, constant: -50),
//                newPostView.rightAnchor.constraint(equalTo: mapView.rightAnchor, constant: 0),
//                newPostView.leftAnchor.constraint(equalTo: mapView.leftAnchor, constant: 0),
//            ]
//            NSLayoutConstraint.activate(constraints)
//            newPostView.alpha = 0
//            newPostView.isHidden = true
//
//            //TODO: adjust fadeIn time based on how long the fly will take
//            newPostView.fadeIn()
//        }
        
    }

    @IBAction func xButtonDidPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
    
    @IBAction func sendButtonDidPressed(_ sender: UIBarButtonItem) {
        
    }
}

var context = CIContext(options: nil)

func blurEffect(image: UIImage) -> UIImage {

    let currentFilter = CIFilter(name: "CIGaussianBlur")
    let beginImage = CIImage(image: image)
    currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
    currentFilter!.setValue(300, forKey: kCIInputRadiusKey)

    let cropFilter = CIFilter(name: "CICrop")
    cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
    cropFilter!.setValue(CIVector(cgRect: beginImage!.extent), forKey: "inputRectangle")

    let output = cropFilter!.outputImage
    let cgimg = context.createCGImage(output!, from: output!.extent)
    let processedImage = UIImage(cgImage: cgimg!)
    return processedImage
}
