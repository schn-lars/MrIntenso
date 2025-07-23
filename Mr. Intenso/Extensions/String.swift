import Foundation
import SwiftUI

extension String {
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: attributes)
        return size.width
    }
    
    // https://stackoverflow.com/questions/27870385/how-can-i-put-each-word-of-a-string-into-an-array-in-swift
    var wordList: [String] {
        return components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
    }
    
}

extension Color {
    init(_ uicolor: UIColor) {
        self.init(uiColor: uicolor)
    }
}
