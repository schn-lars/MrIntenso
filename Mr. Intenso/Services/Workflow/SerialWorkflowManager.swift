import Foundation

protocol SerialWorkflowManager: WorkflowManager {
    var head: WorkflowHandler? { get set }
    
    //func processImage(information object: ObjectInformation)
}

extension SerialWorkflowManager {
    func getHandlerCount() -> Int {
        return (next?.getHandlerCount() ?? 0) + (head?.getHandlerCount() ?? 0)
    }
}
