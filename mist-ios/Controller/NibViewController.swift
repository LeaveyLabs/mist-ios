//
//  NibViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/04.
//

import UIKit

class NibViewController: UIViewController {

    var postview: PostView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            do {
                postview = PostView()
                let post = try await PostAPI.fetchPosts()[0]
                postview.configurePost(post: post, bubbleTrianglePosition: .bottom)
                
                postview.configurePost(post: post, bubbleTrianglePosition: .bottom)
                postview.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(postview)
                
                //OHHHH SHIT IS IT NOT THE TAP GESTURE RECOGNIZER OF ... THE ANNOTAITON VIEW
                //ITS THIS ADD SUBVIEW CODE^^^^^^^ THTTSTHE PROBLEM
                
                NSLayoutConstraint.activate([
                    postview.topAnchor.constraint(equalTo: view.topAnchor, constant: -100),
                    postview.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -30),
                    postview.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.54, constant: 0),
                    postview.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
                ])
            } catch {
                
            }
        }
    }
    
    func loadin() {

    }

}
