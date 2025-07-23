import Foundation
import SwiftUI
import Vision

extension UIImage {
    // https://stackoverflow.com/questions/44462087/how-to-convert-a-uiimage-to-a-cvpixelbuffer
    // https://www.createwithswift.com/uiimage-cvpixelbuffer-converting-an-uiimage-to-a-pixelbuffer/
    func toPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
                       kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
                data: pixelData,
                width: Int(self.size.width),
                height: Int(self.size.height),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                space: rgbColorSpace,
                bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        )

        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
    }
    
    /**
            Normalize input for the model. This is needed if you select a picture manually
     */
    func fixOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return normalizedImage
    }
    
    /**
            Resize a picture to a given dimension (default is dimension of the camerafeed)
     */
    func resizeImage(to targetSize: CGSize = CGSize(width: 1280, height: 720)) -> UIImage? {
        let ogsize = self.size
        let widthRatio  = targetSize.width  / ogsize.width
        let heightRatio = targetSize.height / ogsize.height

        let scale = min(widthRatio, heightRatio)
        let newSize = CGSize(width: ogsize.width * scale,
                             height: ogsize.height * scale)

        // Center the image in the new size
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let newImage = renderer.image { context in
            let x = (targetSize.width - newSize.width) / 2
            let y = (targetSize.height - newSize.height) / 2
            self.draw(in: CGRect(origin: CGPoint(x: x, y: y), size: newSize))
        }

        return newImage
    }
    
    func cropToSquareAndResize(_ targetSize: CGSize) -> UIImage? {
        let imageSize = self.size
        let length = min(imageSize.width, imageSize.height)
        let cropRect = CGRect(
            x: (imageSize.width - length) / 2,
            y: (imageSize.height - length) / 2,
            width: length,
            height: length
        )
        
        guard let cgImage = self.cgImage?.cropping(to: cropRect) else { return nil }
        let croppedImage = UIImage(cgImage: cgImage)
        return croppedImage.hardResize(to: targetSize)
    }
    
    func hardResize(to targetSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func extractText(completion: @escaping (String?) -> Void) {
        guard let image = CIImage(image: self) else {
            completion(nil)
            return
        }

        let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }

            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            let combinedText = recognizedStrings.joined(separator: " ")
            completion(combinedText)
        }
        request.recognitionLevel = .accurate

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error)")
                completion(nil)
            }
        }
    }
}
