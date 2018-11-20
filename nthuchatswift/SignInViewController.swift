import UIKit

import Firebase
import TextFieldEffects
import CoreData
import SwiftSoup

struct ilmsResults: Decodable{
    private enum CodingKeys: String, CodingKey { case ret = "ret"}
    let ret : ppp
}

struct ppp: Decodable{
    private enum CodingKeys: String, CodingKey{
        case status = "status"
        case email = "email"
        case name = "name"
        case divname = "divName"
        case divcode = "divCode"
    }
    let status : String
    let email : String
    let name : String
    let divname : String
    let divcode : String
}


@objc(SignInViewController)
class SignInViewController: UIViewController{
    @IBOutlet weak var loader_indicator: UIActivityIndicatorView!
    @IBOutlet weak var pw_input: HoshiTextField!
    @IBOutlet weak var id_input: HoshiTextField!
    var handle: AuthStateDidChangeListenerHandle?
    override func viewDidLoad() {
        super.viewDidLoad()
        handle = Auth.auth().addStateDidChangeListener(){(auth, user) in
            if (user != nil && user?.displayName != nil) {
                MeasurementHelper.sendLoginEvent()
                self.performSegue(withIdentifier: Constants.Segues.SignInToChat, sender: nil)
                self.loader_indicator.stopAnimating()
            }
        }
        self.loader_indicator.hidesWhenStopped = true
        
    }
    
    deinit{
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func showMsg(_ message: String){
        OperationQueue.main.addOperation{
            let alertController = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
            let cancel = UIAlertAction(title: "確定", style: .default, handler: nil)
            alertController.addAction(cancel)
            self.present(alertController, animated: true, completion: nil)
            self.loader_indicator.stopAnimating()
        }
    }
    
    @IBAction func SignInClick(_ sender: Any) {
        self.loader_indicator.startAnimating()
        if (self.id_input.text == "" || self.pw_input.text == ""){
            self.showMsg("請輸入帳號跟密碼")
        }
        else{
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{return}
            let managedContext = appDelegate.persistentContainer.viewContext
            let userEntity = NSEntityDescription.entity(forEntityName: "UserInfo", in: managedContext)
            let user_data = NSManagedObject(entity: userEntity!, insertInto: managedContext)
            let postString = "account="+self.id_input.text!+"&password="+self.pw_input.text!
            if let posturl = URL(string: "http://lms.nthu.edu.tw/sys/lib/ajax/login_submit.php"){
                var postrequest = URLRequest(url: posturl)
                postrequest.httpMethod = "POST"
                postrequest.httpBody = postString.data(using: .utf8)
                let task = URLSession.shared.dataTask(with: postrequest) { data, response, error in
                    guard let ripdata = data, error == nil else {
                        // check for fundamental networking error
                        print("signin1 error=\(String(describing: error))\n")
                        print("signin1 User Sigin failed")
                        self.showMsg("你密碼錯太多次了，iLMS表示請隔1分鐘後重試")
                        return
                    }
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        // check for http errors
                        print("signin1 statusCode should be 200, but is \(httpStatus.statusCode)\n")
                        print("signin1 response = \(String(describing: response))\n")
                        self.showMsg("登入發生錯誤，請重試")
                    }
                    //let responseString = String(data: ripdata, encoding: .utf8)
                    //print("responseString = \(String(describing: responseString))")
                    let decoder = JSONDecoder()
                    do{
                        let json = try decoder.decode(ilmsResults.self, from: ripdata)
                        print("signin1 login status:",json.ret.status)
                        if (json.ret.status == "true"){
                            user_data.setValue(json.ret.divname, forKey: "divName")
                            do{
                                try managedContext.save()
                            }catch let error as NSError{
                                print("signin1 Could not save.\(error), \(error.userInfo)")
                            }
                                    
                            Auth.auth().createUser(withEmail: json.ret.email, password: json.ret.name + "_ilmschat"){(user, error) in
                                if (error == nil){
                                    print("signin1 User created")
                                    let randomnum = String(Int(arc4random_uniform(12)+1))
                                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                                    changeRequest?.displayName = "機器人87號"
                                    changeRequest?.photoURL = URL(string: "https://nthuchat.com/images/user"+randomnum+".jpg")
                                    changeRequest?.commitChanges{(error) in
                                        print(error as Any)
                                    }
                                    self.find_course(URLSession.shared, user: user_data)
                                Database.database().reference().child("users").child((Auth.auth().currentUser?.uid)!).setValue(["name":json.ret.name,"div":json.ret.divname])
                                    self.loader_indicator.stopAnimating()
                                }else{
                                    print("signin1 User error create")
                                    print(error as Any)
                                    Auth.auth().signIn(withEmail: json.ret.email, password: json.ret.name + "_ilmschat"){(user, error) in
                                        if (error == nil){
                                            print("signin1 User signin success")
                                            self.find_course(URLSession.shared, user: user_data)
                                            self.loader_indicator.stopAnimating()
                                        }else{
                                            print("signin1 User firebase login failed")
                                            //self.showMsg("請輸入正確的帳號密碼")
                                        }
                                    }
                                }
                            }
                        }else if (json.ret.status == "false"){
                            print("signin1 User Password failed")
                            //self.showMsg("登入錯誤，請重試另外的組合")
                        }
                    }catch{
                        print("signin1 error to convert string to json")
                        //print(error)
                        self.showMsg("你密碼輸入錯誤喔")
                        return
                    }
                }
                task.resume()
        }
        }
    }
    
    func find_course(_ session:URLSession, user:NSManagedObject){
        
        let request_home = URLRequest(url: URL(string: "http://lms.nthu.edu.tw/home.php")!)
        let task2 = session.dataTask(with: request_home) { data, response, error in
            guard let coursedata = data, error == nil else {
                // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("home_response = \(String(describing: response))")
            }
            do{
                let responseString = String(data: coursedata, encoding: .utf8)
                let doc: Document = try SwiftSoup.parse(responseString!)
                let titles: Elements = try! doc.select("div.mnuItem>a")
                var title_name = ""
                for i in 0..<titles.size()-1 {
                    var titlename = try! titles.get(i).text()
                    titlename = titlename.replacingOccurrences(of: "[A-Za-z0-9() &,-:\"]*", with: "",options: .regularExpression)
                    //print("course: " + titlename)
                    title_name = title_name + titlename + "@"
                }
                print("course: "+title_name)
                user.setValue(title_name, forKey: "classes")
            }catch{
                print("course error: \(error)")
            }
            //print("home_responseString = \(String(describing: responseString))")
        }
        task2.resume()
        self.performSegue(withIdentifier: Constants.Segues.SignInToChat, sender: nil)
    }
}

