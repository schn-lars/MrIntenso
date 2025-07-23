import Foundation

class WikipediaPageHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    var description: String = "Wikipedia"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        guard let object = input as? ObjectInformation else {
            print("WikipediaPageHandler: requires a objectInformation")
            completion(.failure("WikipediaPageHandler: Wrong Input"))
            return
        }
        
        guard isWikiable(object: object.object) else {
            if let nextWorkflowHandler = nextWorkflowHandler {
                nextWorkflowHandler.process(input, completion: completion)
            } else {
                completion(.failure("WikipediaPageHandler: No Wikiable Result"))
            }
            return
        }
        
        let urlString = "https://\(getLanguageDescriptor()).wikipedia.org/wiki/\(Constants.getTranslatedLanguage(for: object.object))"
        if let url = URL(string: urlString) {
            completion(.success(WebObject(title: description, url: url)))
        } else {
            completion(.failure("Error creating URL."))
        }
    }
    
    private func isWikiable(object: String) -> Bool {
        return [
             "cat",
             "dog",
             "horse",
             "sheep",
             "cow",
             "elephant",
             "bear",
             "zebra",
             "giraffe",
             "frisbee",
             "skis",
             "snowboard",
             "sports ball",
             "skateboard",
             "surfboard",
             "banana",
             "apple",
             "sandwich",
             "orange",
             "broccoli",
             "carrot",
             "hot dog",
             "pizza",
             "donut",
             "cake"
        ].contains(where: { object == $0 })
    }
    
    private func getLanguageDescriptor() -> String {
        let language: String = UserDefaults.standard.getLanguage()
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
