import Foundation

class PersonJokeHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    var description: String = TranslationUnit.getMessage(for: .PERSON_CONVERSATION_TITLE) ?? "Conversation-Starter"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        let url = URL(string: "https://myurl.com/joke")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(getLanguageDescriptor())\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(UserDefaults.standard.string(forKey: UserDefaultsKeys.JOKE.rawValue) ?? "en")\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)

        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, request, error in
            if let error = error {
                print("Error took place \(error)")
                completion(.failure(error.localizedDescription))
                return
            }
            
            if let httpResponse = request as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    if let data = data,
                       let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                       let errorMessage = errorDict["error"] {
                        print("\(#function): Server returned error - \(errorMessage)")
                        completion(.failure(errorMessage))
                        return
                    } else {
                        completion(.failure("Unexpected server error with status code: \(httpResponse.statusCode)"))
                        return
                    }
                }
            }
            
            guard let data = data else {
                print("No data returned by server")
                completion(.failure("No data returned by server."))
                return
            }
            
            do {
                guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
                    print("JokeHandler: Internal Error parsing JSON.")
                    completion(.failure("Internal Error parsing JSON."))
                    return
                }
                if let joke = jsonResponse["joke"] as? String {
                    print("JokeHandler: Returning joke: \(joke)")
                    completion(.success(joke))
                    return
                } else {
                    print("JokeHandler: Internal Error parsing JSON (wrong params).")
                    completion(.failure("If you see this, then the server did not return a valid JSON object."))
                    return
                }
            } catch {
                print("JokeHandler: Internal Error parsing JSON.")
                completion(.failure("Internal Error parsing JSON."))
                return
            }
        }
        task.resume()
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
