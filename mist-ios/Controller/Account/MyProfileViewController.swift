//
//  MyProfileViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/29.
//

import UIKit

//TODO: badges
//https://github.com/jogendra/BadgeHub

class MyProfileViewController: UIViewController {
    
    @IBOutlet weak var backBarButton: UIBarButtonItem!
    @IBOutlet weak var friendsBarButton: UIBarButtonItem!
    @IBOutlet weak var settingsBarButton: UIBarButtonItem!
    @IBOutlet weak var postsUISegmentedControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        //check UISegmentedControl+Twitter file
        postsUISegmentedControl.setupSegment()

    }
    
    // MARK: - UserInteraction
    
    @IBAction func onBackButtonPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func settingsButtonDidtapped(_ sender: UIBarButtonItem) {
        print("presenting")
        //TODO: change from push to full screen show
        let vc = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Settings)
//        vc.modalPresentationStyle = .fullScreen
//        self.present(vc, animated: true, completion: nil)
        self.show(vc, sender: self)
    }
    
    // MARK: - ViewUpdates
    
    @IBAction func segmentedControlValueDidChanged(_ sender: UISegmentedControl) {
        postsUISegmentedControl.changeUnderlinePosition()
        if sender.selectedSegmentIndex == 0 {
            print("0")
        }
    }
    
}
