import Foundation

protocol ParallelWorkflowManager: WorkflowManager {
    var parallelJobs: [WorkflowHandler] { get set }
    
    //func processImage(information object: ObjectInformation)
}

extension ParallelWorkflowManager {
    func getHandlerCount() -> Int {
        return parallelJobs.count + (next?.getHandlerCount() ?? 0)
    }
}
