import Foundation
import SwiftUI

class PosterTextExtractionHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    var description: String = "Text-Extractor"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        guard let image = input as? UIImage else {
            print("PosterTextExtractionHandler: No image available.")
            completion(.failure("No image available."))
            return
        }
        image.extractText { result in
            if let result = result {
                completion(.success(result))
            } else {
                completion(.failure("No text has been extracted!"))
            }
        }
    }
}
