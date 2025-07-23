import Foundation

class TestSerialManager: SerialWorkflowManager {
    var head: (any WorkflowHandler)?
    
    var next: (any WorkflowManager)?
    
    let handler =  PersonJokeHandler()
    
    func processObject(information object: ObjectInformation, completion: @escaping (ObjectInformation) -> Void) {
        switch object.object {
        case "person":
            handler.process(1) { output in
                if let joke = output.text {
                    let jokeObject = SpecificationObject(title: TranslationUnit.getMessage(for: .PERSON_CONVERSATION_TITLE) ?? "Covnversation-Starter", specification: "joke", description: joke)
                    object.addObjectDescription(new: jokeObject) {
                        completion(object)
                    }
                } else if let error = output.error {
                    completion(object)
                }
            }
        default:
            // Do nothing
            completion(object)
        }
    }
}
