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
                postview.translatesAutoresizingMaskIntoConstraints = false
                
                view.addSubview(postview)
                
                NSLayoutConstraint.activate([
                    postview.topAnchor.constraint(equalTo: view.topAnchor, constant: 300),
                    postview.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
                    postview.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -30),
                    postview.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
                ])
                postview.configurePost(post: post, bubbleTrianglePosition: .bottom)

            } catch {
                
            }
        }
    }
    
    func loadin() {

    }

}
