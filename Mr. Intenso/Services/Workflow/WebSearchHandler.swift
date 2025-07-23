import Foundation
import SwiftSoup

/**
        This class is responsible to fetch data from online which can can be added to the ObjectInformations
 */
class WebSearchHandler: WorkflowHandler {
    var description: String = "Website"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        completion(.failure("NOT IMPLEMENTED"))
    }
    
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    init(nextWorkflowHandler: (any WorkflowHandler)? = nil) {
        self.nextWorkflowHandler = nextWorkflowHandler
    }
    
    func process(_ input: Any) -> Any {
        // TODO
        return 1
    }
}
