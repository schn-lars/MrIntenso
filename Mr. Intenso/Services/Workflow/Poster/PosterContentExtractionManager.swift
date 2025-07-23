import Foundation

class PosterContentExtractionManager: ParallelWorkflowManager {
    var parallelJobs: [any WorkflowHandler]
    
    var next: (any WorkflowManager)?
    
    init(parallelJobs: [any WorkflowHandler], next: (any WorkflowManager)? = nil) {
        self.parallelJobs = parallelJobs
        self.next = next
    }
    
    func processObject(information object: ObjectInformation, completion: @escaping (ObjectInformation) -> Void) {
        guard let image = object.image else {
            print("PosterContentExtractionManager: No image found for object \(object.id)")
            completion(object)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        for job in parallelJobs {
            dispatchGroup.enter()
            job.process(image) { resultObject in
                if let url = resultObject.url {
                    let urlObject = WebObject(title: job.description, url: url)
                    object.addObjectDescription(new: urlObject) {
                        DispatchQueue.main.async {
                            print("PosterContentExtractionManager: Incrementing [FINISHED \(job.description)]")
                            object.incrementProcessedCounter()
                            dispatchGroup.leave()
                        }
                    }
                } else if let text = resultObject.text {
                    print("PosterContentExtractionManager: Intermediate text found for \(job.description)")
                    let textObject = IntermeditateTextObject(description: text)
                    object.addObjectDescription(new: textObject) {
                        DispatchQueue.main.async {
                            print("PosterContentExtractionManager: Incrementing [FINISHED \(job.description)]")
                            object.incrementProcessedCounter()
                            dispatchGroup.leave()
                        }
                    }
                } else {
                    print("PosterContentExtractionManager: No result found for \(job.description)")
                    DispatchQueue.main.async {
                        object.incrementProcessedCounter()
                        dispatchGroup.leave()
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("PosterContentExtractionManager: All parallel jobs finished.")
            if let next = self.next {
                next.processObject(information: object, completion: completion)
            } else {
                completion(object)
            }
        }
    }
}
