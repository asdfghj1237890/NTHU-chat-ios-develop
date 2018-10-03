import Foundation
import UIKit
import Firebase
import SDWebImage
import SideMenu
import IQKeyboardManagerSwift
import CoreData

class MenuViewController: UITableViewController{
    @IBOutlet weak var courseTable: UITableView!
    var courses = [["abc","abc@abc.com"],["探索"],["全校"],[]]
    var information_select:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        courseTable.allowsMultipleSelection = false
        self.view.endEditing(true)
        self.courses[0][0] = (Auth.auth().currentUser?.displayName)!
        
        if (Auth.auth().currentUser?.displayName != nil){
            self.courses[0][0] = (Auth.auth().currentUser?.displayName)!
            self.courses[0][1] = (Auth.auth().currentUser?.email)!
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let managedContext = appDelegate?.persistentContainer.viewContext
            
            let userFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "UserInfo")
            let users = try! managedContext?.fetch(userFetch)
            
            if(users?.first != nil){
                let mainUser:UserInfo = users!.first as! UserInfo
                
                if(mainUser.divName != nil && self.courses[2].count == 1){
                    print("course222: "+mainUser.divName!)
                    self.courses[2].append(mainUser.divName!)
                    
                }
                if (mainUser.classes != nil && self.courses[3].count == 0){
                    print("course111: "+mainUser.classes!)
                    let course:[String.SubSequence] = mainUser.classes!.split(separator: "@")
                    for title in course{
                        self.courses[3].append(String(title))
                    }
                }
            }
            courseTable.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.courses[0][0] = (Auth.auth().currentUser?.displayName)!
        courseTable.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //IQKeyboardManager.sharedManager().enable = true
        if (IQKeyboardManager.shared.keyboardShowing){
            self.view.endEditing(true)
        }
        self.courses[0][0] = (Auth.auth().currentUser?.displayName)!
        courseTable.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //IQKeyboardManager.sharedManager().enable = true
        self.courses[0][0] = (Auth.auth().currentUser?.displayName)!
        courseTable.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return courses[section].count
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return courses.count
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        if (indexPath.section == 0 && indexPath.row == 0){
            information_select = true
            showAlert(withTitle: "Change Name", message: "You can change your displayname !")
        }else if(indexPath.section == 1){
            information_select = false
            performSegue(withIdentifier: "explore",
                         sender: courses[1]
                         )
        }else{
            //dismiss(animated: true, completion: nil)
            information_select = false
            performSegue(withIdentifier: "course_item",
                         sender: courses[(tableView.indexPathForSelectedRow?.section)!][(tableView.indexPathForSelectedRow?.row)!]
                         )
            
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let course_table = sender as? String{
            if (segue.identifier == "course_item") {
                let itemviewController: itemViewController = segue.destination as! itemViewController
                itemviewController.titleLabel = course_table
            }else if(segue.identifier == "explore"){
                let itemviewController1: MapViewController = segue.destination as! MapViewController
                itemviewController1.titleLabel = course_table
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?{
        var title = ""
        if (section == 0){
            title = "資料"
        }else if (section == 1){
            title = "地圖"
        }else if (section == 2){
            title = "大型頻道"
        }else if (section == 3){
            title = "課程頻道"
        }
        return title
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue cell
        let id = String(describing: MenuCell.self)
        let cell = self.courseTable.dequeueReusableCell(withIdentifier: id, for: indexPath) as! MenuCell
        cell.courseLabel.text = courses[indexPath.section][indexPath.row]
        cell.iconImage.image = UIImage(named: "icons8-gender_neutral_user")
        if(indexPath.section == 0){
            if(indexPath.row == 0){
                let myURL = Auth.auth().currentUser?.photoURL
                cell.iconImage.sd_setImage(with: myURL, placeholderImage: UIImage(named: "placeholder.png"))
                
            }
            if(indexPath.row == 1){
                cell.isUserInteractionEnabled = false
                cell.courseLabel.font = UIFont(name: cell.courseLabel.font.fontName, size:13)
                cell.iconImage.image = UIImage(named: "icons8-gender_neutral_user")
            }
        }else if(indexPath.section == 1){
            cell.iconImage.image = UIImage(named: "icons8-marker")
        }else if(indexPath.section == 2){
            cell.iconImage.image = UIImage(named: "icons8-school")
        }else{
            cell.iconImage.image = UIImage(named: "icons8-purchase_order")
        }
        return cell
    }
    
    func showAlert(withTitle title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title,
                                          message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {[weak alert] (_) in
                self.dismiss(animated: true, completion: nil)
            })
            let okAction = UIAlertAction(title: "Confirm", style: .default, handler: {[weak alert] (_) in
                let textField = alert?.textFields![0]
                if let textAlert = textField?.text {
                    print("Text field: \(textAlert)")
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    changeRequest?.displayName = textAlert
                    changeRequest?.commitChanges{(error) in
                        print(error as Any)
                    }
                    self.courses[0][0] = (Auth.auth().currentUser?.displayName)!
                    self.dismiss(animated: true, completion: nil)
                }
            })
            //let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
            //alert.addAction(dismissAction)
            alert.addAction(cancelAction)
            alert.addAction(okAction)
            alert.addTextField(configurationHandler: { (textField: UITextField!) in
                textField.placeholder = Auth.auth().currentUser?.displayName
                textField.font = UIFont(name: "Avenir Next", size:20)
            })
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
