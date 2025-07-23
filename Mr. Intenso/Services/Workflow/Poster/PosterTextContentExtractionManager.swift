import Foundation

class PosterTextContentExtractionManager: ParallelWorkflowManager {
    var parallelJobs: [any WorkflowHandler]
    
    var next: (any WorkflowManager)?
    
    init(parallelJobs: [any WorkflowHandler], next: (any WorkflowManager)? = nil) {
        self.parallelJobs = parallelJobs
        self.next = next
    }
    
    func processObject(information object: ObjectInformation, completion: @escaping (ObjectInformation) -> Void) {
        guard let intermediateTextObject = object.detailedDescription.first(where: { $0 is IntermeditateTextObject }), let intermediateText = intermediateTextObject.description else {
            print("PosterTextContentExtractionManager: No IntermediateTextObject has been found.")
            if let next = self.next {
                print("PosterTextContentExtractionManager: Calling next manager..")
                next.processObject(information: object, completion: completion)
            } else {
                completion(object)
            }
            return
        }
        
        let dispatchGroup = DispatchGroup()
        for job in self.parallelJobs {
            dispatchGroup.enter()
            // website extraction and location extraction
            job.process(intermediateText) { output in
                DispatchQueue.main.async {
                    if let url = output.url {
                        let webObject = WebObject(title: job.description, url: url)
                        object.addObjectDescription(new: webObject) {
                            DispatchQueue.main.async {
                                print("PosterTextContentExtractionManager: Incrementing [FINISHED]")
                                object.incrementProcessedCounter()
                            }
                            dispatchGroup.leave()
                        }
                    } else if let location = output.location {
                        let navigationObject = NavigationObject(
                            destination: location,
                            description: "")
                        let locationObject = LocationObject(location: location)
                        object.addObjectDescription(new: locationObject) {
                            DispatchQueue.main.async {
                                print("PosterTextContentExtractionManager: Incrementing [FINISHED]")
                                object.incrementProcessedCounter()
                            }
                            dispatchGroup.leave()
                        }
                        object.addObjectDescription(new: navigationObject) {}
                    } else {
                        DispatchQueue.main.async {
                            print("PosterTextContentExtractionManager: Incrementing [UNKNOWN]")
                            object.incrementProcessedCounter()
                        }
                        dispatchGroup.leave()
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("PosterTextContentExtractionManager: All jobs completed!")
            if let next = self.next {
                print("PosterTextContentExtractionManager: Calling next manager..")
                next.processObject(information: object, completion: completion)
            } else {
                completion(object)
            }
        }
    }
}
