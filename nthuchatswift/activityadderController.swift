import Firebase
import UITextView_Placeholder
import IQKeyboardManagerSwift
import UIKit

class activityadderController: UIViewController,UINavigationControllerDelegate,UITextViewDelegate{
    var titleLabel: String!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.titleLabel
        print("adder: ", self.titleLabel)
    }
}
