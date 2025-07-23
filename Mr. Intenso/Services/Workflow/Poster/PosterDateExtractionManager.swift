import Foundation

// I thought about putting it together with PosterTextExtractionManager, but this would be a bandaid-fix

class PosterDateExtractionManager: ParallelWorkflowManager {
    var parallelJobs: [any WorkflowHandler] = []
    
    var next: (any WorkflowManager)?
    
    func processObject(information object: ObjectInformation, completion: @escaping (ObjectInformation) -> Void) {
        print("PosterDateExtractionManager: Start...")
        
        
        let dispatchGroup = DispatchGroup()
        for job in parallelJobs {
            dispatchGroup.enter()
            
            job.process(object) { resultObject in
                if let dateObject = resultObject.dateObject {
                    print("PosterDataExtractionManager: Extracted date")
                    object.addObjectDescription(new: dateObject) {
                        DispatchQueue.main.async {
                            print("PosterDateExtractionManager: Incrementing [FINISHED]")
                            object.incrementProcessedCounter()
                        }
                        dispatchGroup.leave()
                    }
                } else if let weather = resultObject.forecast {
                    print("PosterDataExtractionManager: Retrieved destination-based weather!")
                    WeatherObject.create(with: weather, title: job.description) { objectDescription in
                        object.addObjectDescription(new: objectDescription) {
                            DispatchQueue.main.async {
                                print("PosterDateExtractionManager: Incrementing [FINISHED]")
                                object.incrementProcessedCounter()
                            }
                            dispatchGroup.leave()
                        }
                    }
                } else {
                    print("PosterDataExtractionManager: Unexpected return type.")
                    DispatchQueue.main.async {
                        print("PosterDataExtractionManager: Incrementing [UNKNOWN]")
                        object.incrementProcessedCounter()
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if let next = self.next {
                next.processObject(information: object, completion: completion)
            } else {
                completion(object)
            }
        }
    }
    
    init(parallelJobs: [any WorkflowHandler], next: (any WorkflowManager)? = nil) {
        self.parallelJobs = parallelJobs
        self.next = next
    }
}
