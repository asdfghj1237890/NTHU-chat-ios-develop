import UIKit
import Firebase
import Crashlytics
import SDWebImage
import SideMenu
import CoreData

class friendsViewController:UIViewController, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate,UITextViewDelegate,UISideMenuNavigationControllerDelegate{
    
    var titleLabel: String!
    
    @IBOutlet weak var friendsTable: UITableView!
    fileprivate var _refHandle: DatabaseHandle!
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var friends: [DataSnapshot]! = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.title = self.titleLabel
        self.navigationItem.leftBarButtonItem?.title = ""
        self.navigationItem.title = "朋友"
        
        configureDatabase()
        
        handle = Auth.auth().addStateDidChangeListener(){(auth, user) in
            if user == nil {
                MeasurementHelper.sendLoginEvent()
                //self.performSegue(withIdentifier: Constants.Segues.ChatToSignIn, sender: nil)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    deinit {
        if let refHandle = _refHandle {
            self.ref.child("friends").removeObserver(withHandle: refHandle)
            //self.ref.child("messages").keepSynced(true)
        }
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func configureDatabase() {
        ref = Database.database().reference().child("users").child((Auth.auth().currentUser?.uid)!)
        _refHandle = self.ref.child("friends").observe(.childAdded, with: {[weak self] (snapshot) -> Void in
         guard let strongSelf = self else {return}
         strongSelf.friends.append(snapshot)
         print("friends_configdatabase",strongSelf.friends.count,snapshot)
         strongSelf.friendsTable.beginUpdates()
         strongSelf.friendsTable.insertRows(at: [IndexPath(row: strongSelf.friends.count-1, section: 0)], with: .automatic)
         strongSelf.friendsTable.endUpdates()
        })
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
    
    // UITableViewDataSource protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("friends_rowsinsection",friends.count)
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue cell
        let my_id = String(describing: FriendCell.self)
        let cell = self.friendsTable.dequeueReusableCell(withIdentifier: my_id, for: indexPath) as! FriendCell
        //Unpack Message from Firebase DataSnapshot
        let messageSnapshot = self.friends[indexPath.row]
        guard let friend = messageSnapshot.value as? [String: String] else {return cell}
        let name = friend["name"] ?? ""
        let time = friend["Added Time"] ?? ""
        //print("friends_indexpath",name)
        
        cell.nameLabel.text = name
        cell.timeLabel.text = "結識時間："+time

        cell.isUserInteractionEnabled = true
        return cell
    }
}
