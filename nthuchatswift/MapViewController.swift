import UIKit
import Firebase
import SideMenu
import CoreData
import GoogleMaps
import CoreLocation
import Floaty

class MapViewController: UIViewController, GMSMapViewDelegate,UINavigationControllerDelegate, UITextViewDelegate, UISideMenuNavigationControllerDelegate,CLLocationManagerDelegate{
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var floaty: Floaty!
    
    var locationManager = CLLocationManager()
    var titleLabel: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.title = self.titleLabel
        //print("title: ",self.titleLabel)
        self.navigationItem.leftBarButtonItem?.title = ""
        self.navigationItem.title = "探索"
        
        Floaty.global.rtlMode = false
        floaty.buttonColor = UIColor(red: 123/255, green: 171/255, blue: 247/255, alpha: 1.0)
        floaty.addItem("新增「朋友」", icon: UIImage(named: "icons8-user_group_man_man")!, handler: { item in
            self.performSegue(withIdentifier: "activityadder",
                         sender: "新增朋友"
            )
            self.floaty.close()
        })
        floaty.addItem("新增「社交」活動", icon: UIImage(named: "icons8-bar")!, handler: { item in
            self.performSegue(withIdentifier: "activityadder",
                              sender: "新增社交活動"
            )
            self.floaty.close()
        })
        floaty.addItem("新增「娛樂」活動", icon: UIImage(named: "icons8-carousel")!, handler: { item in
            self.performSegue(withIdentifier: "activityadder",
                              sender: "新增娛樂活動"
            )
            self.floaty.close()
        })
        floaty.addItem("新增「學習」活動", icon: UIImage(named: "icons8-books")!, handler: { item in
            self.performSegue(withIdentifier: "activityadder",
                              sender: "新增學習活動"
            )
            self.floaty.close()
        })
        floaty.addItem("新增「啟發」活動", icon: UIImage(named: "icons8-light_on")!, handler: { item in
            self.performSegue(withIdentifier: "activityadder",
                              sender: "新增啟發活動"
            )
            self.floaty.close()
        })
    
        self.view.addSubview(floaty)
        
        let camera = GMSCameraPosition.camera(withLatitude: 24.7942042,longitude: 120.9923411, zoom: 16.0)
        mapView.camera = camera
        //mapView.mapType = .terrain
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 24.7947253, longitude: 120.9910429)
        marker.map = mapView
        marker.title = "校本部"
        marker.snippet = "清華"
        marker.icon = GMSMarker.markerImage(with: .blue)
        
        mapView.delegate = self
        mapView.settings.compassButton = true
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        //Location Manager code to fetch current location
        self.locationManager.startUpdatingLocation()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //if let course_table = sender as? String{
            if (segue.identifier == "activityadder") {
                let activityadderController: activityadderController = segue.destination as! activityadderController
                activityadderController.titleLabel = sender as! String
            }
        //}
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker){
        print("show me view")
    }
    
    //Location Manager delegates
    private func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        
        let camera = GMSCameraPosition.camera(withLatitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!, zoom: 17.0)
        
        self.mapView?.animate(to: camera)
        
        //Finally stop updating location otherwise it will come again and again in this delegate
        self.locationManager.stopUpdatingLocation()
        
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
