import UIKit
import Firebase
import Crashlytics
import SDWebImage
import SideMenu
import CoreData


class friendsViewController:UIViewController, UINavigationControllerDelegate,UITextViewDelegate,UISideMenuNavigationControllerDelegate{
    var titleLabel: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.title = self.titleLabel
        self.navigationItem.leftBarButtonItem?.title = ""
        self.navigationItem.title = "朋友"
    }
    
    @IBAction func signOutScreen() {
        let firebaseAuth = Auth.auth()
        do{
            try firebaseAuth.signOut()
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{return}
            let managedContext = appDelegate.persistentContainer.viewContext
            
            let userFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "UserInfo")
            //let request = NSBatchDeleteRequest(fetchRequest: userFetch)
            do{
                if let userFetchResult = try? managedContext.fetch(userFetch){
                    for result in userFetchResult{
                        managedContext.delete(result as! NSManagedObject)
                    }
                }
                //try managedContext.execute(request)
                try managedContext.save()
                print("User Signout sucess")
                dismiss(animated: true, completion: nil)
            }catch{
                print("CoreData delete error")
                //dismiss(animated: true, completion: nil)
            }
        }catch let signOutError as NSError{
            print("Error sign out :\(signOutError.localizedDescription)")
        }
    }
}
