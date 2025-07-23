import Foundation

class ShoppingManager: SerialWorkflowManager {
    var head: (any WorkflowHandler)?
    
    var next: (any WorkflowManager)?
    
    func processObject(information object: ObjectInformation, completion: @escaping (ObjectInformation) -> Void) {
        guard let googleLensObject = object.detailedDescription.first(where: { $0 is GoogleLensObject }) as? GoogleLensObject else {
            print("ShoppingManager: We do not have googleLensObject.")
            DispatchQueue.main.async {
                print("ShoppingManager: Incrementing [NO GOOGLELENS]")
                object.incrementProcessedCounter()
            }
            if let next = self.next {
                next.processObject(information: object, completion: completion)
            } else {
                completion(object)
            }
            return
        }
        
        guard let head = head else {
            print("ShoppingManager: No head")
            DispatchQueue.main.async {
                print("ShoppingManager: Incrementing [NO HEAD]")
                object.incrementProcessedCounter()
            }
            if let next = self.next {
                next.processObject(information: object, completion: completion)
            } else {
                completion(object)
            }
            return
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        head.process(googleLensObject.productsToken) { resultObject in
            defer {
                DispatchQueue.main.async {
                    print("ShoppingManager: Incrementing [FINISHED]")
                    object.incrementProcessedCounter()
                }
                dispatchGroup.leave()
            }
            
            print(resultObject)
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
