import Foundation
import SwiftUI

class BirdClassificationManager: SerialWorkflowManager {
    var head: (any WorkflowHandler)? = BirdClassificationHandler()
    
    var next: (any WorkflowManager)?
    
    func processObject(information object: ObjectInformation, completion: @escaping (ObjectInformation) -> Void) {
        guard let input = object.image else {
            completion(object)
            return
        }
        
        guard let head = head else {
            print("BirdClassificationManager: No head")
            completion(object)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        //https://stackoverflow.com/questions/41203095/using-dispatchgroup-in-swift-3-to-perform-a-task
        dispatchGroup.enter()
        print("BirdClassificationManager: Start")
        head.process(input) { result in
            defer {
                DispatchQueue.main.async {
                    print("BirdClassificationManager: Incremmenting [FINISHED]")
                    object.incrementProcessedCounter()
                }
                dispatchGroup.leave()
            }
            if let name_desc = result.detailedText {
                let specificationObject = SpecificationObject(
                    title: self.head?.description ?? "",
                    specification: name_desc.first ?? "If you see this: Run.",
                    description: name_desc.last
                )
                object.addObjectDescription(new: specificationObject) {}
            } else if let error = result.error {
                let specificationErrorObject = SpecificationObject(title: self.head?.description ?? "Specification Error", errorMessage: error)
                object.addObjectDescription(new: specificationErrorObject) {}
                print("Added new SpecificationErrorObject.")
            } else {
                print("\(#function): Error adding new description")
            }
        }
        dispatchGroup.notify(queue: .main) {
            print("BirdClassificationManager: End")
            if let next = self.next {
                let hasSpec = object.detailedDescription.contains(where: { $0 is SpecificationObject })
                print("Contains SpecificationObject before forwarding:", hasSpec)
                next.processObject(information: object, completion: completion)
            } else {
                completion(object)
            }
        }
    }
}
