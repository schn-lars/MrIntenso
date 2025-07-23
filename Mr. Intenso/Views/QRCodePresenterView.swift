import Foundation
import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodePresenterView: View {
    let objectInformation: ObjectInformation
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var hasShared: Bool? = nil
    
    var body: some View {
        VStack(alignment: .center) {
            if let hasShared = hasShared {
                if hasShared {
                    Text(TranslationUnit.getMessage(for: .SHARE_SCAN) ?? "Share this information by letting a friend scan it!")
                        .font(.system(size: 22))
                        .foregroundColor(Color.black)
                        .multilineTextAlignment(.center)
                    Image(uiImage: generateQRCode(from: objectInformation.id.uuidString))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text(TranslationUnit.getMessage(for: .SHARE_FAILED) ?? "Unable to share the object!")
                        .font(.system(size: 22))
                        .foregroundColor(Color.black)
                        .multilineTextAlignment(.center)
                }
            } else {
                Text(TranslationUnit.getMessage(for: .SHARE_LOADING) ?? "Sharing the object...")
                    .font(.system(size: 22))
                    .foregroundColor(Color.black)
                    .multilineTextAlignment(.center)
                ProgressView()
                    .foregroundColor(Color.black)
            }
        }
        .onAppear {
            appViewModel.shareRequest(objectInformation: objectInformation) { status in
                print("QRCodePresenterView: Sharing completed: \(status)")
                DispatchQueue.main.async {
                    self.hasShared = status
                }
            }
        }
    }
    
    func generateQRCode(from uuidString: String) -> UIImage {
        filter.message = Data(uuidString.utf8)
        
        if let output = filter.outputImage {
            if let cgImage = context.createCGImage(output, from: output.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
