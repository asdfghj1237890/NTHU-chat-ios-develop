import UIKit
import Firebase
import CoreData


class QrcodeController: UIViewController{
    @IBOutlet weak var qrcodeView: UIImageView!
    var qrcodeImage: CIImage!
    let data = Auth.auth().currentUser?.uid.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)
    let filter = CIFilter(name: "CIQRCodeGenerator")
    override func viewDidLoad() {
        super.viewDidLoad()
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("Q", forKey: "inputCorrectionLevel")
        
        qrcodeImage = filter?.outputImage
        
        //fix unclear after generated image
        let scaleX = qrcodeView.frame.size.width/qrcodeImage.extent.size.width
        let scaleY = qrcodeView.frame.size.height/qrcodeImage.extent.size.height
        let transformedImage = qrcodeImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        qrcodeView.image = UIImage(ciImage: transformedImage)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
