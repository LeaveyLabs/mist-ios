//
//  NibViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/04.
//

import UIKit

class NibViewController: UIViewController {

    @IBOutlet weak var postview: PostView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            do {
                let post = try await PostAPI.fetchPosts()[0]
                postview.configurePost(post: post, bubbleTrianglePosition: .bottom)
            } catch {
                
            }
        }

    }

}
