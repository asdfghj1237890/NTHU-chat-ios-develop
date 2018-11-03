import UIKit
import Firebase
import CoreData

import AVFoundation

class QrcodeScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate{
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    var usersref: DatabaseReference!
    
    @IBOutlet weak var messageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 取得 AVCaptureDevice 類別的實體來初始化一個device物件，並提供video
        // 作為媒體型態參數
        
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        // 使用前面的 device 物件取得 AVCaptureDeviceInput 類別的實體
        do{
            let input: AnyObject! = try AVCaptureDeviceInput(device: captureDevice!)
            // 初始化 captureSession 物件
            captureSession = AVCaptureSession()
            // 在capture session 設定輸入裝置
            captureSession?.addInput(input as! AVCaptureInput)
            
            // 初始化 AVCaptureMetadataOutput 物件並將其設定作為擷取session的輸出裝置
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // 設定代理並使用預設的調度佇列來執行回呼（call back）
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            // 初始化影像預覽層，並將其加為 viewPreview 視圖層的子層
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            // 開始影像擷取
            captureSession?.startRunning()
            
            // 將訊息標籤移到最上層視圖
            view.bringSubviewToFront(messageLabel)
            
            // 初始化 QR Code Frame 來突顯 QR code
            qrCodeFrameView = UIView()
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.cyan.cgColor
                qrCodeFrameView.layer.borderWidth = 5
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
            }
        }catch{
            return
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // 檢查  metadataObjects 陣列為非空值，它至少需包含一個物件
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No QR code is detected"
            return
        }
        
        // 取得元資料（metadata）物件
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // 倘若發現的元資料與 QR code 元資料相同，便更新狀態標籤的文字並設定邊界
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if (metadataObj.stringValue != nil) && (!(metadataObj.stringValue?.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .newlines).isEmpty)!) {
                messageLabel.text = metadataObj.stringValue
                usersref = Database.database().reference().child("users")
                
                usersref.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.hasChild((Auth.auth().currentUser?.uid)!) && snapshot.hasChild(metadataObj.stringValue!.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "#", with: "").replacingOccurrences(of: "$", with: "").replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")){
                        var ref0,ref1 :DatabaseReference!
                        ref0 = self.usersref.child((Auth.auth().currentUser?.uid)!).child("friends")
                        ref1 = self.usersref.child(metadataObj.stringValue!).child("friends")
                        
                        ref0.observeSingleEvent(of: .value, with: { (snapshot) in
                            if (!snapshot.exists()) {
                                let df = DateFormatter()
                                df.dateFormat = "yyyy-MM-dd hh:mm:ss"
                                let adddate = df.string(from: Date())
                                let mdata = ["Added Time": adddate]
                                ref0.child(metadataObj.stringValue!).setValue(mdata)
                            }
                        }) { (error) in
                            print(error.localizedDescription)
                        }
                        
                        ref1.observeSingleEvent(of: .value, with: { (snapshot) in
                            if (!snapshot.exists()) {
                                let df = DateFormatter()
                                df.dateFormat = "yyyy-MM-dd hh:mm:ss"
                                let adddate = df.string(from: Date())
                                let mdata = ["Added Time": adddate]
                                ref1.child((Auth.auth().currentUser?.uid)!).setValue(mdata)
                                self.showAlert(flag: true)
                            }
                        }) { (error) in
                            print(error.localizedDescription)
                        }
                        
                    }else{
                        //self.showAlert(flag: false)
                        return
                    }
                }){ (error) in
                    //self.showAlert(flag: false)
                    return
                }
            }
        }
    }
    
    
    @IBAction func showAlert(flag: Bool) {
        if (flag == true){
            let alertController = UIAlertController(title: "成功增加朋友了", message: "你再也不是個邊緣人了", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler:{[weak alertController] (_) in
                self.performSegue(withIdentifier: "backtoQR",sender: nil)
                }
            )
            alertController.addAction(defaultAction)
            present(alertController, animated: true)
        }else{
            let alertController = UIAlertController(title: "你不要跟他做朋友", message: "他不是這邊的宅宅啦", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler:{[weak alertController] (_) in
                self.performSegue(withIdentifier: "backtoQR",sender: nil)
                }
            )
            alertController.addAction(defaultAction)
            present(alertController, animated: true)
        }
        
    }
}
