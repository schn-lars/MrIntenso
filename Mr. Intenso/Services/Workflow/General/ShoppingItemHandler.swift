import Foundation
import SwiftUI

class ShoppingItemHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    let apikey: String
    
    init(nextWorkflowHandler: (any WorkflowHandler)? = nil, apikey: String) {
        self.nextWorkflowHandler = nextWorkflowHandler
        self.apikey = apikey
    }
    
    var description: String = "Shopping"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        guard let pagetoken = input as? String,
        pagetoken != ""
            else {
            print("ShoppingItemHandler: Given input is not of type String or empty. \(type(of: input))")
            completion(.failure("Given input is not of type String"))
            return
        }
        
        guard let language = UserDefaults.standard.string(forKey: UserDefaultsKeys.LANGUAGE.rawValue) else {
            print("ShoppingItemHandler: No language set, falling back to English.")
            completion(.failure("ShoppingItemHandler: Error retrieving language"))
            return
        }
        
        guard let url = URL(string: "https://serpapi.com/search.json?engine=google_lens&page_token=\(pagetoken)&api_key=\(apikey)&country=ch&hl=\(language == "ENG" ? "en" : "de")") else {
            print("ShoppingItemHandler: Invalid URL")
            completion(.failure("ShoppingItemHandler: Invalid url"))
            return
        }
        
        // https://stackoverflow.com/questions/31077989/how-do-i-perform-get-and-post-requests-in-swift
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    if let data = data,
                       let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                       let errorMessage = errorDict["error"] {
                        print("ShoppingItemHandler: Server returned error - \(errorMessage)")
                        completion(.failure(errorMessage))
                        return
                    } else {
                        completion(.failure("Unexpected server error with status code: \(httpResponse.statusCode)"))
                        return
                    }
                }
            }
            
            guard let data = data else {
                print("ShoppingItemHandler: No data returned")
                completion(.failure("No data returned."))
                return
            }
            
            do {
                guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    completion(.failure("Internal Error parsing JSON."))
                    print("ShoppingItemHandler: Error parsing JSON")
                    return
                }
                //let results = jsonResponse["shopping_results"] as? [[String: Any]]
                print("ShoppingItemHandler: Completed fetching of shopping items.")
                print(jsonResponse)
                
                completion(.failure("undpoa"))
            } catch let error {
                print(error.localizedDescription)
                completion(.failure("Internal Error: \(error.localizedDescription)"))
            }
        }
        task.resume()
    }
}
