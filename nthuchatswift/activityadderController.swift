import Firebase
//import UITextView_Placeholder
//import IQKeyboardManagerSwift
import UIKit
import Eureka
import CoreLocation
import ViewRow
import GoogleMaps

class activityadderController: FormViewController, UINavigationControllerDelegate,UITextViewDelegate{
    var titleLabel: String!
    var initLocation = CLLocationCoordinate2D(latitude: 24.793167, longitude: 120.9925318)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.titleLabel
        print("adder: ", self.titleLabel)
        
        form +++ Section("基本資料")
            <<< TextRow("title"){ row in
                row.title = "名稱"
                row.add(rule: RuleRequired())
                row.placeholder = "例如：校長與你有約"
                row.validationOptions = .validatesOnDemand
            }
            +++ Section("時間")
            <<< DateTimeInlineRow("starttime"){
                $0.title = "開始日期時間"
                $0.value = Date()
            }
            <<< DateTimeInlineRow("endtime"){
                $0.title = "結束日期時間"
                $0.value = Date()
            }
            +++ Section("地點")
            <<< LocationRow("location"){
                $0.title = "GPS位置"
                $0.value = CLLocation(latitude: 24.793167, longitude: 120.9925318)
                }.onChange { (row) in
                    if let newGPSLocation = row.value {
                        //print("newGPS0: ",newGPSLocation.coordinate ,"\n")
                        //  Alter the contents of the view in some way...
                        if let resultRow = self.form.rowBy(tag: "activitymap") as? ViewRow<GMSMapView>,
                            let resultView = resultRow.view {
                            resultView.clear()
                            
                            let camera = GMSCameraPosition.camera(withTarget: (self.form.rowBy(tag: "location") as? LocationRow)?.value?.coordinate ?? self.initLocation, zoom: 18.0)
                            resultView.camera = camera
                            
                            let marker = GMSMarker()
                            marker.position = newGPSLocation.coordinate
                            marker.map = resultView
                            marker.icon = GMSMarker.markerImage(with: .blue)
                            //print("newGPS: ",row.value!.coordinate, "\n")
                        }
                    }
                }
            
            <<< ViewRow<GMSMapView>("activitymap") { (row) in
                //row.title = "My View Title" // optional
                }
                .cellSetup { (cell, row) in
                    //  Construct the view for the cell
                    //cell.view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
                    //cell.view?.backgroundColor = UIColor.orange
                    cell.view = GMSMapView(frame: CGRect(x: 0, y: 0, width: 100, height: UIDevice.current.userInterfaceIdiom == .pad ? 250 : 190))
                    
                    cell.viewLeftMargin = 5.0
                    cell.viewRightMargin = 5.0
                    
                    let camera = GMSCameraPosition.camera(withTarget: (self.form.rowBy(tag: "location") as? LocationRow)?.value?.coordinate ?? self.initLocation, zoom: 18.0)
                    cell.view!.camera = camera
                    
                    let marker = GMSMarker()
                    marker.position = (self.form.rowBy(tag: "location") as? LocationRow)?.value?.coordinate ?? self.initLocation
                    marker.map = cell.view
                    marker.icon = GMSMarker.markerImage(with: .blue)
                    
                    cell.view!.settings.scrollGestures = false
                    cell.view!.settings.tiltGestures = false
                    cell.view!.settings.rotateGestures = false
                    cell.view!.settings.zoomGestures = false
                    
                }.cellUpdate { cell, row in
                    /*self.marker.position = (self.form.rowBy(tag: "location") as? LocationRow)?.value?.coordinate ?? self.initLocation
                    self.marker.map = cell.view*/
                }
            
            +++ Section("附註")
            <<< TextAreaRow("description") {
                $0.placeholder = "可以補充一下活動資訊"
                $0.add(rule: RuleRequired())
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
                $0.validationOptions = .validatesOnDemand
            }
        
            +++ Section()
            <<< ButtonRow() { (row: ButtonRow) -> Void in
                row.title = "Submit"
                }
                .cellSetup() {cell, row in
                    cell.backgroundColor = UIColor.red
                    cell.tintColor = UIColor.white
                }
                .onCellSelection { [weak self] (cell, row) in
                    self?.showAlert()
            }
        // Enables smooth scrolling on navigation to off-screen rows
        animateScroll = true
        // Leaves 20pt of space between the keyboard and the highlighted row after scrolling to an off screen row
        rowKeyboardSpacing = 20
        
    }
    
    @IBAction func showAlert() {
        if (form.validate() == []){
            let titlemessage = ((self.form.rowBy(tag: "title") as? TextRow)?.value)
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd hh:mm:ss"
            let start = df.string(from: ((self.form.rowBy(tag: "starttime") as? DateTimeInlineRow)?.value)!)
            let end = df.string(from: ((self.form.rowBy(tag: "endtime") as? DateTimeInlineRow)?.value)!)
            let timemessage = "\n" + start + "\n" + end + "\n"
            let locationmessage = "\(((self.form.rowBy(tag: "location") as? LocationRow)?.value)!.coordinate.latitude)" + ","+"\(((self.form.rowBy(tag: "location") as? LocationRow)?.value)!.coordinate.longitude)" + "\n"
            let textareamessage = ((self.form.rowBy(tag: "description") as? TextAreaRow)?.value)
            
            let alertController = UIAlertController(title: "準備提交以下資料:", message: titlemessage! + timemessage + locationmessage + textareamessage!, preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            present(alertController, animated: true)
        }
        else{
            let alertController = UIAlertController(title: "404 Not Found", message: "你有空白欄位還沒填寫", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            present(alertController, animated: true)
        }
    }
}
