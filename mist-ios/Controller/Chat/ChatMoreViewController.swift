//
//  ChatMoreViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import Foundation

protocol ChatMoreDelegate {
    func handleSuccessfulBlock()
}

class ChatMoreViewController: CustomSheetViewController {
    
    override var canBecomeFirstResponder: Bool {
        get { return true }
    }
        
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var blockButton: UIButton!
    
    var delegate: ChatMoreDelegate!
    var sangdaebangId: Int!
    
    class func create(sangdaebangId: Int, delegate: ChatMoreDelegate) -> ChatMoreViewController {
        let moreVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ChatMore) as! ChatMoreViewController
        moreVC.loadViewIfNeeded() //doesnt work without this function call
        moreVC.sangdaebangId = sangdaebangId
        moreVC.delegate = delegate
        return moreVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.layer.cornerRadius = 5
        setupSheet(prefersGrabberVisible: false,
                   detents: [._detent(withIdentifier: "s", constant: 160)],
                   largestUndimmedDetentIdentifier: nil)
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func blockButton(_ sender: UIButton) {
        CustomSwiftMessages.showBlockPrompt { [self] didBlock in
            if didBlock {
                Task {
                    do {
                        blockButton.loadingIndicator(true)
                        try await BlockService.singleton.blockUser(sangdaebangId)
                        blockButton.loadingIndicator(false)
                        DispatchQueue.main.async {
                            self.dismiss(animated: true)
                            self.delegate.handleSuccessfulBlock()
                        }
                    } catch {
                        CustomSwiftMessages.displayError(error)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.becomeFirstResponder() //prevents keyboard from popping up
                }
            }
        }
    }
    
    @IBAction func weMetButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
