import Foundation

class AnimalResourcesManager: ParallelWorkflowManager {
    var parallelJobs: [any WorkflowHandler]
    
    var next: (any WorkflowManager)?
    
    init(parallelJobs: [any WorkflowHandler], next: (any WorkflowManager)? = nil) {
        self.parallelJobs = parallelJobs
        self.next = next
    }
    
    func processObject(information object: ObjectInformation, completion: @escaping (ObjectInformation) -> Void) {
        let dispatchGroup = DispatchGroup()
        for job in parallelJobs {
            dispatchGroup.enter()
            job.process(object.object) { resultObject in
                defer {
                    DispatchQueue.main.async {
                        print("AnimalResourceManager: Incrementing [FINISHED]")
                        object.incrementProcessedCounter()
                    }
                    
                    dispatchGroup.leave()
                }
                
                if let url = resultObject.url {
                    print("AnimalResourceManager: Fetched \(url)")
                    let webObject = WebObject(title: job.description, url: url, description: "This is the website for lost \(object.object).")
                    object.addObjectDescription(new: webObject) {}
                }
            }
        }
            
        
        dispatchGroup.notify(queue: .main) {
            print("AnimalResourceManager: All parallel jobs finished.")
            if let next = self.next {
                next.processObject(information: object, completion: completion)
            } else {
                completion(object)
            }
        }
    }
}
