import Foundation
import ARKit

class BirdInformationRetrievalManager: ParallelWorkflowManager {
    var parallelJobs: [any WorkflowHandler] = []
    
    var next: (any WorkflowManager)?
    
    init(parallelJobs: [any WorkflowHandler], next: (any WorkflowManager)? = nil) {
        self.parallelJobs = parallelJobs
        self.next = next
    }
    
    func processObject(information object: ObjectInformation, completion: @escaping (ObjectInformation) -> Void) {
        guard let spec = object.detailedDescription.first(where: { $0 is SpecificationObject }) as? SpecificationObject else {
            print("BirdInformationRetrievalManager: No bird name found")
            completion(object)
            return
        }
        let specification = spec.specification ?? ""
        let dispatchGroup = DispatchGroup()
        
        for job in parallelJobs {
            dispatchGroup.enter()
            job.process(specification) { output in
                defer {
                    DispatchQueue.main.async {
                        print("BirdInformationREtrievalManager: Incremmenting [FINISHED]")
                        object.incrementProcessedCounter()
                    }
                    dispatchGroup.leave()
                }
                if let image = output.image {
                    let imageObject = ImageObject(title: job.description, image: image)
                    object.addObjectDescription(new: imageObject) {}
                } else if let url = output.url {
                    let webObject = WebObject(title: job.description, url: url)
                    object.addObjectDescription(new: webObject) {}
                } else if let error = output.error {
                    let errorObject: any ObjectDescriptionBase
                    if job is WebPageHandler {
                        errorObject = WebObject(title: job.description, errorMessage: error)
                    } else {
                        errorObject = ImageObject(title: job.description, errorMessage: error)
                    }
                    object.addObjectDescription(new: errorObject) {}
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("BirdInformationRetrievalManager: All parallel jobs finished.")
            if let next = self.next {
                next.processObject(information: object, completion: completion)
            } else {
                completion(object)
            }
        }
    }
}
