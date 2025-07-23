import Foundation
import SwiftUI

struct ReverseImageSearchHandler: WorkflowHandler {
    let apikey: String
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    var description: String = "Related"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        guard UserDefaults.standard.getReverseSearchSetting() else {
            print("ReverseImageSearchHandler: Reverse search is disabled.")
            completion(.failure("ReverseImageSearchHandler: Reverse search is disabled."))
            return
        }
        
        guard let inputDict = input as? [String : String],
            let imageURL = inputDict["url"],
            let object = inputDict["object"] else {
            print("ReverseImageSearchHandler: input must be String")
            completion(.failure("ReverseImageSearchHandler: input must be String"))
            return
        }
        
        print(inputDict.keys)
        
        guard let language = UserDefaults.standard.string(forKey: UserDefaultsKeys.LANGUAGE.rawValue) else {
            print("ReverseImageSearchHandler: No language set, falling back to English.")
            completion(.failure("ReverseImageSearchHandler: Error retrieving language"))
            return
        }
        
        guard let url = URL(string: "https://serpapi.com/search.json?engine=google_lens&url=\(imageURL)&api_key=\(apikey)&country=ch&hl=\(language == Constants.LANGUAGE_DEFAULT ? "en" : "de")") else {
            completion(.failure("ReverseImageSearchHandler: Invalid url"))
            return
        }
        
        /*guard let url = URL(string: "https://myurl.com/test") else {
            completion(.failure("ReverseImageSearchHandler: Invalid url"))
            return
        }*/
        
        print("ReverseImageSearchHandler: About to create request...")
        
        var reverseRequest = URLRequest(url: url)
        reverseRequest.httpMethod = "GET"
        reverseRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("ReverseImageSearchHandler: Sending request to server...")
        
        URLSession.shared.dataTask(with: reverseRequest) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    if let data,
                    let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                       let errorMessage = errorDict["error"] {
                        print("\(#function): Server returned error - \(errorMessage)")
                        completion(.failure("Server returned error - \(errorMessage)"))
                        return
                    }
                }
            }
            
            guard let data = data else {
                print("ReverseImageSearchHandler: failed to get data")
                completion(.failure("Failed to get data."))
                return
            }
            do {
                if var jsonResponse = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : Any] {
                    print("ReverseImageSearchHandler: Received JSON \(jsonResponse.keys)")
                    jsonResponse.updateValue(object, forKey: "object")
                    nextWorkflowHandler?.process(jsonResponse, completion: completion)
                }
            } catch {
                print("ReverseImageSearchHandler: Error parsing JSON data")
                completion(.failure("Error parsing JSON data."))
                return
            }
        }
        .resume()
    }
}
