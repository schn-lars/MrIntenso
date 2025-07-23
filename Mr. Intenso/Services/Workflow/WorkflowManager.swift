import Foundation

/**
 
        This protocol is used as container for tasks which can be executed.
        Some tasks are of serial nature, whereas others might even be parallelizable.
        This is inspired by the fork/join-pattern. (https://en.wikipedia.org/wiki/Fork%E2%80%93join_model)
 
 */

protocol WorkflowManager {
    var next: WorkflowManager? { get set }
    
    func processObject(information object: ObjectInformation, completion: @escaping (ObjectInformation) -> Void) // Changes are applied to the object itself
    
    func getHandlerCount() -> Int // This function is needed to give the user an indication on how far along processing things are
    
}
