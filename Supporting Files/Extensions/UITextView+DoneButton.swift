import UIKit
import CircularProgressView

extension UITextView {
    
    func addNewPostToolbar(target: Any, selector: Selector) {
        
        let toolBar = UIToolbar(frame: CGRect(x: 0.0,
                                              y: 0.0,
                                              width: UIScreen.main.bounds.size.width,
                                              height: 44.0))//1
        toolBar.barTintColor = .white
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)//2
        let barButton = UIBarButtonItem(title: "How do Mists work?", style: .plain, target: target, action: selector)//3
        barButton.tintColor = .lightGray
    
//        let explainButton = UIButton()
//        explainButton.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
//        explainButton.setTitle(" How do mists work?", for: .normal)
//        explainButton.tintColor = .lightGray
//        explainButton.setTitleColor(.lightGray, for: .normal)
//        let explainBarButton = UIBarButtonItem.init(customView: explainButton)
//
        let rectProgressView = CGRect(x: 0, y: 0, width: 30, height: 30)
        let progressView = CircularProgressView(frame: rectProgressView)
        progressView.progress = 0.67
        progressView.trackLineWidth = 3.0
        progressView.trackTintColor = toolBar.barTintColor!
        progressView.progressTintColor = mistUIColor()
        progressView.roundedProgressLineCap = true
        
        let progressLabel = UILabel()
        progressLabel.text = "9"
        progressLabel.font = UIFont(name: Constants.Font.Medium, size: 16)
        progressLabel.textColor = mistUIColor()
        progressLabel.sizeToFit()
        progressView.addSubview(progressLabel)

        let progressCircle = UIBarButtonItem.init(customView: progressView)
        progressLabel.center = CGPoint(x: progressView.bounds.midX, y: progressView.bounds.midY) // Must come after progressView is turned into the UIBarButtonItem

        toolBar.setItems([barButton, flexible, progressCircle], animated: false)//4

        self.inputAccessoryView = toolBar//5
    }
}
