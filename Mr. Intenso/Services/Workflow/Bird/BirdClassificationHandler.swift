import Foundation
import SwiftUI

class BirdClassificationHandler: WorkflowHandler {
    
    var description: String = TranslationUnit.getMessage(for: .BIRD_CLASSIFICATION_TITLE) ?? "Species"
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    /**
     https://stackoverflow.com/questions/31077989/how-do-i-perform-get-and-post-requests-in-swift
     */
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        guard let image = input as? UIImage else {
            print("\(#function): Cannot cast input to UIImage!")
            completion(.failure("Cannot cast input to UIImage!"))
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Could not convert image to data.")
            completion(.failure("Could not convert image to data."))
            return
        }
        
        // https://stackoverflow.com/questions/31077989/how-do-i-perform-get-and-post-requests-in-swift
        
        let url = URL(string: "https://myurl.com/classify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"bird.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
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
                print("No data returned")
                completion(.failure("No data returned."))
                return
            }
            
            do {
                guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
                    completion(.failure("Internal Error parsing JSON."))
                    return
                }
                if let name = jsonResponse["birdName"] as? String {
                    // This is the case when we got a hit in our database
                    print("\(#function): The retrieved scientific name is: \(name)")
                    if UserDefaults.standard.getLanguage() == "ENG" {
                        completion(.success([name, "The retrieved scientific name is: \(name)"]))
                    } else {
                        completion(.success([name, "Der wissenschaftliche Name dieses Vogels ist: \(name)"]))
                    }
                } else if let name = jsonResponse["label"] {
                    // This is just the label returned by the classifier, without having an entry in the database
                    print("\(#function): The retrieved name is: \(name)")
                    if UserDefaults.standard.getLanguage() == "ENG" {
                        completion(.success([name, "The retrieved name is: \(name)"]))
                    } else {
                        completion(.success([name, "Der Name dieses Vogels ist: \(name)"]))
                    }
                } else {
                    print("Data maybe corrupted or in wrong format")
                    completion(.failure("Data maybe corrupted or in wrong format."))
                }
            } catch let error {
                print(error.localizedDescription)
                completion(.failure("Internal Error: \(error.localizedDescription)"))
            }
        }
        task.resume()
    }
}
