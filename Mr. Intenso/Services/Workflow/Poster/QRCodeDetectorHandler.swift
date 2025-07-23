import Foundation
import SwiftUI

class QRCodeDetectorHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    var description: String = "QR-Code"
    
    
    /**
            This method accepts an image as input and returns an URL ideally.
     */
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        guard input is UIImage else {
            print("QRCodeDetectorHandler: Given input is not of type UIImage. (\(type(of: input)))")
            completion(.failure("Wrong input type!"))
            return
        }
        
        // https://stackoverflow.com/questions/38298488/how-can-you-scan-a-uiimage-for-a-qr-code-using-swift
        
        guard let ciImage = CIImage(image: input as! UIImage) else {
            print("QRCodeDetectorHandler: Could not create CIImage.")
            completion(.failure("Could not create CIIamge."))
            return
        }
        
        guard let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: nil,
            options: [CIDetectorAccuracy : CIDetectorAccuracyHigh]
        ) else {
            print("Detector not intialized")
            completion(.failure("Error initializing detector."))
            return
        }
        
        let features = detector.features(in: ciImage)
        let qrCodeFeatures = features.compactMap { $0 as? CIQRCodeFeature }
        guard let qrCode = qrCodeFeatures.first?.messageString else {
            print("No QR code found in the image")
            completion(.failure("No QR code found in the image."))
            return
        }
        print("Retrived QR-Code: \(qrCode)")
        if let url = URL(string: qrCode) {
            print("Successfully converted string to url.")
            completion(.success(url))
            return
        } else {
            print("Could not convert to URL, but returning string now.")
            completion(.success(qrCode))
        }
    }
}
