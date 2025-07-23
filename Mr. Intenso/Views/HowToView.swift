import Foundation
import SwiftUI
import WebKit

//https://medium.com/@jakir/showing-pdf-in-swiftui-using-pdfkit-and-webkit-931a7aafff79

struct HowToView: View {
    let pdfURL: URL
    
    var body: some View {
        HowToViewRepresentable(url: pdfURL)
    }
}

import PDFKit

struct HowToViewRepresentable: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: self.url)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // No updates needed
    }
}
