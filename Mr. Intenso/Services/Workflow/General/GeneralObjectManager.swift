import Foundation

class GeneralObjectManager: ParallelWorkflowManager {
    var next: (any WorkflowManager)?
    
    var parallelJobs: [any WorkflowHandler]
    
    func processObject(information object: ObjectInformation, completion: @escaping (ObjectInformation) -> Void) {
        let dispatchGroup = DispatchGroup()
        for job in parallelJobs {
            dispatchGroup.enter()
            
            job.process(object) { resultObject in
                defer {
                    DispatchQueue.main.async {
                        print("GeneralObjectManager: Incrementing [FINISHED]")
                        object.incrementProcessedCounter()
                    }
                    print("GeneralObjectManager: \(job.description) completed")
                    dispatchGroup.leave()
                }
                
                if var saleItems = resultObject.saleItems {
                    for i in saleItems.indices {
                        saleItems[i].setItemType(object.object)
                    }
                    print("GeneralObjectManager: \(saleItems.count) saleItems retrieved")
                    object.addObjectDescription(new: ShoppingObject(saleItems: saleItems)) {}
                } else if let googleLensObject = resultObject.googleLensObject {
                    print("GeneralObjectManager: Google Lens object retrieved.")
                    object.addObjectDescription(new: googleLensObject) {}
                } else if let mediaItem = resultObject.matchedMusic {
                    object.addObjectDescription(new: ShazamObject(mediaItem: mediaItem, title: job.description)) {}
                } else if let forecast = resultObject.forecast {
                    WeatherObject.create(with: forecast, title: job.description) { objectDescription in
                        object.addObjectDescription(new: objectDescription) {}
                    }
                } else if let webObject = resultObject.webObject {
                    object.addObjectDescription(new: webObject) {}
                } else {
                    print("GeneralObjectManager: \(type(of: resultObject)) was retrieved. Ignoring it.")
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("GeneralObjectManager: All jobs completed")
            if self.next != nil {
                self.next?.processObject(information: object, completion: completion)
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
