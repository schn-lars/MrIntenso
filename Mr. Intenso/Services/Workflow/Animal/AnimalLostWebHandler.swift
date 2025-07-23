import Foundation

class AnimalLostWebHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    let animals = ["cat" : "katzen", "dog" : "hunde", "bird" : "v%C3%B6gel"]
    
    var description: String = TranslationUnit.getMessage(for: .ANIMAL_LOST_TITLE) ?? "Lost Animals"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        guard let animal = input as? String, animals.keys.contains(animal) else {
            print("AnimalLostWebHandler: This animal is not suited to be called for being lost.")
            completion(.failure("This is not an animal which is detected for being lost."))
            return
        }
        
        let urlString = "https://www.stmz.ch/de/vermisstmeldungen/\(animals[animal] ?? animal)"
        guard let url = URL(string: urlString) else {
            completion(.failure("Invalind URL-format."))
            return
        }
        completion(.success(url))
    }
}
