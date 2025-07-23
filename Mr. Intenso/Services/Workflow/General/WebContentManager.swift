import Foundation

class WebContentManager: SerialWorkflowManager {
    var head: (any WorkflowHandler)?
    
    var next: (any WorkflowManager)?
    
    func processObject(information object: ObjectInformation, completion: @escaping (ObjectInformation) -> Void) {
        guard let head = head else {
            print("WebContentManager: No head")
            DispatchQueue.main.async {
                print("WebContentManager: Incrementing [NO HEAD]")
                object.incrementProcessedCounter()
            }
            completion(object)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        head.process(object.object) { resultObject in
            defer {
                DispatchQueue.main.async {
                    print("WebContentManager: Incrementing [FINISHED]")
                    object.incrementProcessedCounter()
                }
                dispatchGroup.leave()
            }
            if let webObject = resultObject.webObject {
                print("WebContentManager: Retrieved URL")
                object.addObjectDescription(new: webObject) {}
            } else {
                print("WebContentManager: Did not find a suitable URL")
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("ShoppingManager: End")
            if let next = self.next {
                next.processObject(information: object, completion: completion)
            } else {
                completion(object)
            }
        }
    }
}
