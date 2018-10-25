import Photos
import UIKit

import Firebase
import Crashlytics
import SDWebImage
import UITextView_Placeholder
import IQKeyboardManagerSwift
import SideMenu
import CoreData

class ChannelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,UITextViewDelegate, UINavigationControllerDelegate, UISideMenuNavigationControllerDelegate{
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var indicator_loader: UIActivityIndicatorView!
    
    // Instance variables
    @IBOutlet weak var textField: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var clientTable: UITableView!
    @IBOutlet weak var heightconst: NSLayoutConstraint!
    
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var messages: [DataSnapshot]! = []
    var messageKeys: [String]! = []
    var msglength: NSNumber = 10
    let textViewMaxHeight: CGFloat = 120
    let textViewMinHeight: CGFloat = 40
    fileprivate var _refHandle: DatabaseHandle!
    
    var remoteConfig: RemoteConfig!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.endEditing(true)
        textField.delegate = self
        indicator_loader.startAnimating()
        
        let color = UIColor(red: 0/255, green: 131/255, blue: 193/255, alpha: 1.0).cgColor
        self.textField.layer.borderColor = color
        self.textField.layer.borderWidth = 1.0
        self.textField.layer.cornerRadius = 17.0

        self.textField.layer.masksToBounds = false
        self.textField.layer.shadowColor = UIColor.black.cgColor
        self.textField.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        self.textField.layer.shadowOpacity = 0.5
        self.textField.layer.shadowRadius = 5
        
        self.textField.placeholder = "Message Here..."
        self.textField.placeholderColor = UIColor.lightGray
        
        self.sendButton.layer.cornerRadius = 22
        self.sendButton.layer.masksToBounds = false
        self.sendButton.layer.shadowColor = UIColor.black.cgColor
        self.sendButton.layer.shadowRadius = 5
        self.sendButton.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        self.sendButton.layer.shadowOpacity = 0.5
        
        //clientTable.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleHideKeyboard)))
        clientTable.keyboardDismissMode = .interactive
        indicator_loader.hidesWhenStopped = true

        configureDatabase()
        configureRemoteConfig()
        fetchConfig()
        
        setupSideMenu()
        
        IQKeyboardManager.shared.enable = true
        
        handle = Auth.auth().addStateDidChangeListener(){(auth, user) in
            if user == nil {
                MeasurementHelper.sendLoginEvent()
                //self.performSegue(withIdentifier: Constants.Segues.ChatToSignIn, sender: nil)
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        if (IQKeyboardManager.shared.keyboardShowing){
            self.view.endEditing(true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //self.clientTable.scrollToRow(at: IndexPath(row: self.messages.count-1, section: 0), at: .bottom, animated: false)
        //IQKeyboardManager.sharedManager().enable = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //IQKeyboardManager.sharedManager().enable = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //IQKeyboardManager.sharedManager().enable = true
    }
    
    func sideMenuWillAppear(menu: UISideMenuNavigationController, animated: Bool) {
        print("SideMenu Appearing! (animated: \(animated))")
        IQKeyboardManager.shared.enable = false
    }
    
    func sideMenuDidAppear(menu: UISideMenuNavigationController, animated: Bool) {
        print("SideMenu Appeared! (animated: \(animated))")
    }
    
    func sideMenuWillDisappear(menu: UISideMenuNavigationController, animated: Bool) {
        print("SideMenu Disappearing! (animated: \(animated))")
    }
    
    func sideMenuDidDisappear(menu: UISideMenuNavigationController, animated: Bool) {
        print("SideMenu Disappeared! (animated: \(animated))")
        IQKeyboardManager.shared.enable = true
        self.view.endEditing(true)
    }
    
    deinit {
        if let refHandle = _refHandle {
            self.ref.child("messages").removeObserver(withHandle: refHandle)
            //self.ref.child("messages").keepSynced(true)
        }
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    var startKey: String!
    var dragdirection: Int!; // 0 is down, 1 is up
    
    func configureDatabase() {
        ref = Database.database().reference()
        //Listen for new messages in the Firebase database
        /*_refHandle = self.ref.child("messages").observe(.childAdded, with: {[weak self] (snapshot) -> Void in
            guard let strongSelf = self else {return}
            strongSelf.messages.append(snapshot)
            let scroll_action :(Bool) -> Void = {_ in
                strongSelf.clientTable.scrollToRow(at: IndexPath(row: strongSelf.messages.count-1, section: 0), at: .bottom, animated: true)
            }
            if #available(iOS 11.0, *) {
                strongSelf.clientTable.performBatchUpdates({
                    strongSelf.clientTable.insertRows(at: [IndexPath(row: strongSelf.messages.count-1, section: 0)], with: .automatic)
                }, completion: scroll_action)
            } else {
                strongSelf.clientTable.beginUpdates()
                strongSelf.clientTable.insertRows(at: [IndexPath(row: strongSelf.messages.count-1, section: 0)], with: .automatic)
                strongSelf.clientTable.endUpdates()
                strongSelf.clientTable.scrollToRow(at: IndexPath(row: strongSelf.messages.count-1, section: 0), at: .bottom, animated: true)
            }

            strongSelf.indicator_loader.stopAnimating()
        })*/
        if (startKey == nil){
            print("firebasetest_startkey: ",self.startKey)
            _refHandle = self.ref.child("messages").queryOrderedByKey().queryLimited(toLast: 30).observe(.value){(snapshot) in
                guard let children = snapshot.children.allObjects.first as? DataSnapshot else{return}
                if (snapshot.childrenCount > 0){
                    print("firebasetest_snapshotcount: ",snapshot.childrenCount)
                    for child in snapshot.children.allObjects as! [DataSnapshot]{
                        if(!(self.messageKeys.contains((child as AnyObject).key))){
                            self.messages.append(child)
                            self.messageKeys.append(child.key)
                            self.clientTable.insertRows(at: [IndexPath(row: self.messages.count-1, section: 0)], with: .automatic)
                        }
                    }
                    self.startKey = children.key
                    print("firebasetest_startkey_again: ",self.startKey)
                    print("firebasetest_messagecount: ",self.messages.count)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                        self.clientTable.scrollToRow(at: IndexPath(row: self.messages.count-1, section: 0), at: .bottom, animated: true)
                        self.indicator_loader.stopAnimating()
                    }
                }
            }
        }else if (dragdirection == 0 && startKey != nil){
            //going up
            print("firebasetest1_startkey: ",self.startKey)
            _refHandle = self.ref.child("messages").queryOrderedByKey().queryEnding(atValue: self.startKey).queryLimited(toLast: 10).observe(.value){(snapshot) in
                guard let children = snapshot.children.allObjects.first as? DataSnapshot else{return}
                if (snapshot.childrenCount > 0 ){
                    print("firebasetest1_childrencount: ",snapshot.childrenCount)
                    UIView.setAnimationsEnabled(false)
                    //self.itemTable.beginUpdates()
                    for child in snapshot.children.reversed(){
                        if ((child as AnyObject).key != self.startKey &&
                            !(self.messageKeys.contains((child as AnyObject).key))){
                            self.messages.insert(child as! DataSnapshot, at:0)
                            self.messageKeys.append((child as AnyObject).key)
                            self.clientTable.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                        }
                    }
                    UIView.setAnimationsEnabled(true)
                    //self.itemTable.endUpdates()
                    //self.itemTable.reloadData()
                    self.startKey = children.key
                    print("firebasetest1_startkey_again: ",self.startKey)
                    print("firebasetest1_messagecount: ",self.messages.count)
                    /*if (self.messages.count > 20 && snapshot.childrenCount != 1){
                     self.itemTable.scrollToRow(at: IndexPath(row: 19, section: 0), at: .bottom, animated: true)
                     }else if(snapshot.childrenCount == 1){
                     self.itemTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                     }else{
                     self.itemTable.scrollToRow(at: IndexPath(row: self.messages.count-1, section: 0), at: .bottom, animated: true)
                     }*/
                }
            }
        }
    }
    
    //func scrollViewDidScroll(_ scrollView: UIScrollView){
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool){
        let currentOffset = scrollView.contentOffset.y
        let frameheight = scrollView.frame.size.height
        let contentheight = scrollView.contentSize.height
        
        print("firebasetest currentoffset: ", currentOffset)
        print("firebasetest frameheight: ", frameheight)
        print("firebasetest contentheight: ", contentheight)
        
        if ((currentOffset + frameheight) >= contentheight) {
            print("firebasetest: going down!!!!")
            dragdirection = 1
            self.configureDatabase()
            
        }else if( currentOffset <= (contentheight * 9/100)){
            print("firebasetest: going up!!!!")
            dragdirection = 0
            self.configureDatabase()
        }
    }
    
    /*@objc func handleHideKeyboard(){
        self.textField.resignFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }*/
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didSendMessage(_ sender: UIButton) {
        //_ = textFieldShouldReturn(textField)
        _ = send_event(textField)
    }
    
    func send_event(_ textField: UITextView) -> Bool {
        guard var text = textField.text else { return true }
        textField.text = ""
        view.endEditing(true)
        if (text.contains("\n")){
            text = text.trimmingCharacters(in: CharacterSet.newlines)
            text = text.replacingOccurrences(of: "\n", with: " ")
            if (text.count > 0){
                let data = [Constants.MessageFields.text: text]
                sendMessage(withData: data)
                return true
            }else{
                showAlert(withTitle: "Error", message: "不要只傳送空白／換行")
                self.heightconst.constant = textViewMinHeight
                return false
            }
        }else{
            text = text.trimmingCharacters(in: CharacterSet.whitespaces)
            if (text.count > 0){
                let data = [Constants.MessageFields.text: text]
                sendMessage(withData: data)
                return true
            }else{
                showAlert(withTitle: "Error", message: "不要只傳送空白／換行")
                self.heightconst.constant = textViewMinHeight
                return false
            }
        }
    }
    
    func sendMessage(withData data: [String: String]) {
        var mdata = data
        mdata[Constants.MessageFields.name] = Auth.auth().currentUser?.displayName
        if var photoURL = Auth.auth().currentUser?.photoURL?.absoluteString {
            if photoURL.contains(".."){
                photoURL = "https://nthuchat.com" + photoURL.replacingOccurrences(of: "..", with: "")
            }
            mdata[Constants.MessageFields.photoURL] = photoURL
            mdata[Constants.MessageFields.uid] = Auth.auth().currentUser?.uid
        }
        
        //Push data to Firebase Database
        self.ref.child("messages").childByAutoId().setValue(mdata)
        self.countLabel.text = "0/"+String(describing: self.msglength.intValue)
        self.heightconst.constant = textViewMinHeight
        self.textField.isScrollEnabled = false
    }

    
    func configureRemoteConfig() {
        remoteConfig = RemoteConfig.remoteConfig()
        let remoteConfigSettings = RemoteConfigSettings(developerModeEnabled: true)
        remoteConfig.configSettings = remoteConfigSettings
    }
    
    func fetchConfig() {
        var expirationDuration: TimeInterval = 3600
        
        if self.remoteConfig.configSettings.isDeveloperModeEnabled{
            expirationDuration = 0
        }
        
        remoteConfig.fetch(withExpirationDuration: expirationDuration){ [weak self] (status, error) in
            if status == .success{
                print("Config fetched!")
                guard let strongSelf = self else {return}
                strongSelf.remoteConfig.activateFetched()
                let friendlyMsgLength = strongSelf.remoteConfig["friendly_msg_length"]
                if friendlyMsgLength.source != .static {
                    strongSelf.msglength = friendlyMsgLength.numberValue!
                    print("Friendly msg length config :\(strongSelf.msglength)")
                    strongSelf.countLabel.text = "0/"+String(describing: strongSelf.msglength.intValue)
                }
            }else{
                print("Config not fetched")
                if let error = error {
                    print("Error \(error)")
                }
            }
        }
    }
    
    fileprivate func setupSideMenu() {
        // Define the menus
        let menuLeftNavigationController = storyboard!.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as! UISideMenuNavigationController
        
        // Enable gestures. The left and/or right menus must be set up above for these to work.
        // Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
        SideMenuManager.default.menuAddPanGestureToPresent(toView: self.navigationController!.navigationBar)
        SideMenuManager.default.menuAddScreenEdgePanGesturesToPresent(toView: self.navigationController!.view)
        //SideMenuManager.default.menuAnimationFadeStrength = 50
        SideMenuManager.default.menuShadowOpacity = 100
        SideMenuManager.default.menuAnimationPresentDuration = 0.25
        SideMenuManager.default.menuAnimationDismissDuration = 0.25
        SideMenuManager.default.menuAnimationCompleteGestureDuration = 0.25
        //SideMenuManager.default.menuAnimationBackgroundColor = UIColor(patternImage: UIImage(named: "background")!)
        //SideMenuManager.default.menuAnimationBackgroundColor = UIColor(red: 52/255, green: 73/255, blue: 94/255, alpha: 1.0)
        SideMenuManager.default.menuLeftNavigationController = menuLeftNavigationController
        SideMenuManager.default.menuFadeStatusBar = false
        let fullScreenSize = UIScreen.main.bounds.size
        SideMenuManager.default.menuWidth = fullScreenSize.width * 0.8
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let text_content = textField.text else { return true }
        let newLength = text_content.count + text.count - range.length
        let counter_value = self.msglength.intValue
        self.countLabel.text = String(describing: newLength) + "/" + String(describing: counter_value)
        return newLength <= counter_value // Bool
    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        //let fieldfixMaxHeight = textField.heightAnchor.constraint(equalToConstant: self.textViewMaxHeight)
        //let fieldfixMinHeight = textField.heightAnchor.constraint(greaterThanOrEqualToConstant: self.textViewMinHeight)
        let contentSize = textField.sizeThatFits(textField.bounds.size)
        
        if contentSize.height >= self.textViewMaxHeight
        {
            textField.isScrollEnabled = true
            print("MAX true", textField.contentSize.height, textField.frame.size.height, self.backView.frame.size.height)
        }
        else
        {
            if (contentSize.height < self.backView.frame.size.height){
                //textField.frame.size.height = contentSize.height
                self.heightconst.constant = contentSize.height
            }
            textField.isScrollEnabled = false
            print("MAX false", textField.contentSize.height, textField.frame.size.height, self.backView.frame.size.height)
        }
    }
    
    // UITableViewDataSource protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue cell
        let other_id = String(describing: ClientCell.self)
        let my_id = String(describing: MyCell.self)
        let other_cell = self.clientTable.dequeueReusableCell(withIdentifier: other_id, for: indexPath) as! ClientCell
        let my_cell = self.clientTable.dequeueReusableCell(withIdentifier: my_id, for: indexPath) as! MyCell
        //Unpack Message from Firebase DataSnapshot
        let messageSnapshot = self.messages[indexPath.row]
        guard let message = messageSnapshot.value as? [String: String] else {
            return other_cell
        }
        let name = message[Constants.MessageFields.name] ?? ""
        let text = message[Constants.MessageFields.text] ?? ""
        let user_id = message[Constants.MessageFields.uid] ?? ""
        if (user_id != Auth.auth().currentUser?.uid){
            other_cell.nameLabel.text = name
            other_cell.messageLabel.text = text
            //cell.textLabel?.text = name + ": " + text
            other_cell.iconImageView?.image = UIImage(named: "ic_account_circle")
            if let photoURL = message[Constants.MessageFields.photoURL], let URL = URL (string: photoURL)
                //, let data = try? Data(contentsOf: URL){
            {
                print(photoURL)
                //cell.iconImageView.image = UIImage(data: data)
                other_cell.iconImageView.sd_setImage(with: URL, placeholderImage: UIImage(named: "placeholder.png"))
            }
            other_cell.isUserInteractionEnabled = false
            return other_cell
        }else{
            my_cell.nameLabel.text = name
            my_cell.messageLabel.text = text
            //cell.textLabel?.text = name + ": " + text
            my_cell.iconImageView?.image = UIImage(named: "ic_account_circle")
            if let photoURL = message[Constants.MessageFields.photoURL], let URL = URL (string: photoURL)
                //, let data = try? Data(contentsOf: URL){
            {
                print(photoURL)
                //cell.iconImageView.image = UIImage(data: data)
                my_cell.iconImageView.sd_setImage(with: URL, placeholderImage: UIImage(named: "placeholder.png"))
            }
            my_cell.isUserInteractionEnabled = false
            return my_cell
        }
        
    }
    
    @IBAction func menuClick(){
        self.view.endEditing(true)
    }
    
    @IBAction func signOutScreen() {
        let firebaseAuth = Auth.auth()
        do{
            try firebaseAuth.signOut()
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{return}
            let managedContext = appDelegate.persistentContainer.viewContext
            
            let userFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "UserInfo")
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
    func showAlert(withTitle title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title,
                                          message: message, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
}
