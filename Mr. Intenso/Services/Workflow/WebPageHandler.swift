import Foundation

/**
        This class is used to create an URL which can potentially contain information about the given input's object.
 */
class WebPageHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    var description: String = "Website"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        if let searchTerm = input as? String {
            // f.e. https://en.wikipedia.org/wiki/House_sparrow
            // TODO: maybe case distinction based on the class
            print("WebPageHandler: Starting")
            let urlString = "https://\(getLanguageDescriptor()).wikipedia.org/wiki/\(searchTerm)"
            if let url = URL(string: urlString) {
                completion(.success(url))
            } else {
                completion(.failure("Error creating URL."))
            }
        }
    }
    
    private func getLanguageDescriptor() -> String {
        let language: String = UserDefaults.standard.string(forKey: "Language") ?? ""
        print("getLanguageDescription: Language is now \(language)")
        switch language {
        case "ENG":
            return "en"
        case "GER":
            return "de"
        default:
            fatalError(#function + ": Unsupported language \(language)")
        }
    }
}
