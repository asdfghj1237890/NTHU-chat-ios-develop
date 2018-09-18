import Photos
import UIKit

import Firebase
import GoogleMobileAds
import Crashlytics
import SDWebImage
import UITextView_Placeholder
import IQKeyboardManagerSwift

import SideMenu
import CoreData



class itemViewController: UIViewController , UITableViewDataSource, UITableViewDelegate,UITextViewDelegate, UINavigationControllerDelegate, UISideMenuNavigationControllerDelegate{
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var itemCountLabel: UILabel!
    @IBOutlet weak var itemSendButton: UIButton!
    @IBOutlet weak var itemTextView: UITextView!
    @IBOutlet weak var indicator_loader: UIActivityIndicatorView!
    @IBOutlet weak var itemTable: UITableView!
    var titleLabel: String!
    @IBOutlet weak var banner: GADBannerView!
    @IBOutlet weak var heightconst: NSLayoutConstraint!
    
    var numberOfPosts: Int = 15
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var messages: [DataSnapshot]! = []
    var msglength: NSNumber = 10
    let textViewMaxHeight: CGFloat = 120
    let textViewMinHeight: CGFloat = 40
    fileprivate var _refHandle: DatabaseHandle!
    var fetchingNow = false
    var remoteConfig: RemoteConfig!
    var channel_title = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itemTable.delegate = self
        itemTextView.delegate = self
        
        self.title = self.titleLabel
        self.navigationItem.leftBarButtonItem?.title = ""
        
        indicator_loader.startAnimating()
        indicator_loader.hidesWhenStopped = true
        
        let color = UIColor(red: 0/255, green: 131/255, blue: 193/255, alpha: 1.0).cgColor
        self.itemTextView.layer.borderColor = color
        self.itemTextView.layer.borderWidth = 1.0
        self.itemTextView.layer.cornerRadius = 17.0
        
        self.itemTextView.layer.masksToBounds = false
        self.itemTextView.layer.shadowColor = UIColor.black.cgColor
        self.itemTextView.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        self.itemTextView.layer.shadowOpacity = 0.5
        self.itemTextView.layer.shadowRadius = 5
        
        self.itemTextView.placeholder = "Message Here..."
        self.itemTextView.placeholderColor = UIColor.lightGray
        
        self.itemSendButton.layer.cornerRadius = 22
        self.itemSendButton.layer.masksToBounds = false
        self.itemSendButton.layer.shadowColor = UIColor.black.cgColor
        self.itemSendButton.layer.shadowRadius = 5
        self.itemSendButton.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        self.itemSendButton.layer.shadowOpacity = 0.5
        
        //itemTable.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleHideKeyboard)))
        itemTable.keyboardDismissMode = .interactive
        
        if (self.titleLabel == "全校"){
            channel_title = "messages"
        }else{
            channel_title = self.titleLabel!
            ref = Database.database().reference()
            ref.child(channel_title).observeSingleEvent(of: .value, with: { (snapshot) in
                if (!snapshot.exists()) {
                    var mdata = [Constants.MessageFields.text: "你可以成為第一個發言的人喔!"]
                    mdata[Constants.MessageFields.name] = "NTHU Chat"
                    mdata[Constants.MessageFields.photoURL] = "https://nthuchat.com/images/user1.jpg"
                    mdata[Constants.MessageFields.uid] = "999999"
                    self.ref.child(self.channel_title).childByAutoId().setValue(mdata)
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        
        loadAd()
        configureDatabase()
        configureRemoteConfig()
        fetchConfig()
        
        if (IQKeyboardManager.sharedManager().keyboardShowing){
            self.view.endEditing(true)
        }
    }

    /*@objc func handleHideKeyboard(){
        self.itemTextView.resignFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }*/
    
    func sideMenuWillAppear(menu: UISideMenuNavigationController, animated: Bool) {
        print("SideMenu Appearing! (animated: \(animated))")
        IQKeyboardManager.sharedManager().enable = false
    }
    
    func sideMenuDidAppear(menu: UISideMenuNavigationController, animated: Bool) {
        print("SideMenu Appeared! (animated: \(animated))")
    }
    
    func sideMenuWillDisappear(menu: UISideMenuNavigationController, animated: Bool) {
        print("SideMenu Disappearing! (animated: \(animated))")
    }
    
    func sideMenuDidDisappear(menu: UISideMenuNavigationController, animated: Bool) {
        print("SideMenu Disappeared! (animated: \(animated))")
        IQKeyboardManager.sharedManager().enable = true
        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didSendMessage(_ sender: UIButton) {
        //_ = textFieldShouldReturn(textField)
        _ = send_event(itemTextView)
    }
    
    func loadAd() {
        self.banner.adUnitID = kBannerAdUnitID
        self.banner.rootViewController = self
        self.banner.load(GADRequest())
    }
    
    deinit {
        if let refHandle = _refHandle {
            self.ref.child(channel_title).removeObserver(withHandle: refHandle)
            //self.ref.child("messages").keepSynced(true)
        }
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func configureDatabase() {
        ref = Database.database().reference()
        //original version
        //Listen for new messages in the Firebase database
        _refHandle = self.ref.child(channel_title).observe(.childAdded, with: {[weak self] (snapshot) -> Void in
            guard let strongSelf = self else {return}
            strongSelf.messages.append(snapshot)
            let scroll_action :(Bool) -> Void = {_ in
                strongSelf.itemTable.scrollToRow(at: IndexPath(row: strongSelf.messages.count-1, section: 0), at: .bottom, animated: true)
            }
            if #available(iOS 11.0, *) {
                strongSelf.itemTable.performBatchUpdates({
                    strongSelf.itemTable.insertRows(at: [IndexPath(row: strongSelf.messages.count-1, section: 0)], with: .automatic)
                }, completion: scroll_action)
            } else {
                strongSelf.itemTable.beginUpdates()
                strongSelf.itemTable.insertRows(at: [IndexPath(row: strongSelf.messages.count-1, section: 0)], with: .automatic)
                strongSelf.itemTable.endUpdates()
                strongSelf.itemTable.scrollToRow(at: IndexPath(row: strongSelf.messages.count-1, section: 0), at: .bottom, animated: true)
            }
            strongSelf.indicator_loader.stopAnimating()
        })
        //new edit version
        /*_refHandle = self.ref.child(channel_title).queryOrderedByValue().queryLimited(toLast: UInt(numberOfPosts)).observe(.childAdded, with: {[weak self] (snapshot) -> Void in
            guard let strongSelf = self else {return}
            strongSelf.messages.append(snapshot)
            let scroll_action :(Bool) -> Void = {_ in
                strongSelf.itemTable.scrollToRow(at: IndexPath(row: strongSelf.messages.count-1, section: 0), at: .bottom, animated: true)
            }
            if #available(iOS 11.0, *) {
                strongSelf.itemTable.performBatchUpdates({
                    strongSelf.itemTable.insertRows(at: [IndexPath(row: strongSelf.messages.count-1, section: 0)], with: .automatic)
                }, completion: scroll_action)
            } else {
                strongSelf.itemTable.beginUpdates()
                strongSelf.itemTable.insertRows(at: [IndexPath(row: strongSelf.messages.count-1, section: 0)], with: .automatic)
                strongSelf.itemTable.endUpdates()
                strongSelf.itemTable.scrollToRow(at: IndexPath(row: strongSelf.messages.count-1, section: 0), at: .bottom, animated: true)
            }
            strongSelf.indicator_loader.stopAnimating()
            //strongSelf.fetchingNow = false
        })*/
    }
    
    func configureRemoteConfig() {
        remoteConfig = RemoteConfig.remoteConfig()
        let remoteConfigSettings = RemoteConfigSettings(developerModeEnabled: true)
        remoteConfig.configSettings = remoteConfigSettings!
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
                    strongSelf.itemCountLabel.text = "0/"+String(describing: strongSelf.msglength.intValue)
                }
            }else{
                print("Config not fetched")
                if let error = error {
                    print("Error \(error)")
                }
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView){
        guard scrollView.contentOffset.y <= 0 else { return }
        print("scrolling top")
        numberOfPosts += 15
        //configureDatabase()
    }
    
    // UITableViewDataSource protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Dequeue cell
        let other_id = String(describing: Item_ClientCell.self)
        let my_id = String(describing: Item_MyCell.self)
        let other_cell = self.itemTable.dequeueReusableCell(withIdentifier: other_id, for: indexPath) as! Item_ClientCell
        let my_cell = self.itemTable.dequeueReusableCell(withIdentifier: my_id, for: indexPath) as! Item_MyCell
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
        self.ref.child(channel_title).childByAutoId().setValue(mdata)
        self.itemCountLabel.text = "0/"+String(describing: self.msglength.intValue)
        self.heightconst.constant = textViewMinHeight
        self.itemTextView.isScrollEnabled = false
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let text_content = itemTextView.text else { return true }
        let newLength = text_content.count + text.count - range.length
        let counter_value = self.msglength.intValue
        //print(newLength)
        self.itemCountLabel.text = String(describing: newLength) + "/" + String(describing: counter_value)
        return newLength <= counter_value // Bool
    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        //let fieldfixMaxHeight = textField.heightAnchor.constraint(equalToConstant: self.textViewMaxHeight)
        //let fieldfixMinHeight = textField.heightAnchor.constraint(greaterThanOrEqualToConstant: self.textViewMinHeight)
        let contentSize = itemTextView.sizeThatFits(itemTextView.bounds.size)
        
        if contentSize.height >= self.textViewMaxHeight
        {
            itemTextView.isScrollEnabled = true
            print("MAX true", itemTextView.contentSize.height, itemTextView.frame.size.height, self.backView.frame.size.height)
        }
        else
        {
            if (contentSize.height < self.backView.frame.size.height){
                //textField.frame.size.height = contentSize.height
                self.heightconst.constant = contentSize.height
            }
            itemTextView.isScrollEnabled = false
            print("MAX false", itemTextView.contentSize.height, itemTextView.frame.size.height, self.backView.frame.size.height)
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
