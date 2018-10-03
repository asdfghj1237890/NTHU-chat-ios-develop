import UIKit
import Firebase
import SideMenu
import CoreData
import GoogleMaps

class MapViewController: UIViewController, GMSMapViewDelegate,UINavigationControllerDelegate, UITextViewDelegate, UISideMenuNavigationControllerDelegate{
    @IBOutlet weak var mapView: GMSMapView!
    var titleLabel: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.title = self.titleLabel
        //print("title: ",self.titleLabel)
        self.navigationItem.leftBarButtonItem?.title = ""
        self.navigationItem.title = "探索"
        
        let camera = GMSCameraPosition.camera(withLatitude: 24.7947253,longitude: 120.9910429, zoom: 17.0)
        mapView.camera = camera
        //mapView.mapType = .terrain
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 24.7947253, longitude: 120.9910429)
        marker.map = mapView
        marker.title = "校本部"
        marker.snippet = "清華"
        marker.icon = GMSMarker.markerImage(with: .blue)
        
        mapView.delegate = self
        mapView.settings.myLocationButton = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker){
        print("show me view")
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
