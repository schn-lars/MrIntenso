import Foundation

struct ImageUploadHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    var description: String = "Upload"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        guard UserDefaults.standard.getReverseSearchSetting() else {
            print("ImageUploadHandler: Reverse search is disabled.")
            completion(.failure("ImageUploadHandler: Reverse search is disabled."))
            return
        }
        
        guard let object = input as? ObjectInformation else {
            print("ImageUploadHandler: Input is not an ObjectInformation.")
            completion(.failure("ImageUploadHandler: Input is not an ObjectInformation."))
            return
        }
        
        guard let imageData = object.image?.jpegData(compressionQuality: 0.3) else {
            print("ImageUploadHandler: Could not create image data!")
            completion(.failure("Could not create image data!"))
            return
        }
        
        guard let url = URL(string: "https://myurl.com/upload") else {
            print("ImageUploadHandler: Invalid url")
            completion(.failure("Invalid url"))
            return
        }
        
        let payload: [String: Any] = [
            "img" : imageData.base64EncodedString(),
            "id" : object.id.uuidString
        ]
        
        var uploadRequest = URLRequest(url: url)
        uploadRequest.httpMethod = "POST"
        uploadRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("ImageUploadHandler: About to perform request")
        
        do {
            uploadRequest.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("ImageUploadHandler: Unable to serialize JSON.")
            completion(.failure("Unable to serialize JSON."))
            return
        }
        
        print("ImageUploadHandler: Sending request to server...")
        
        URLSession.shared.dataTask(with: uploadRequest) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    if let data,
                    let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                       let errorMessage = errorDict["error"] {
                        print("\(#function): Server returned error - \(errorMessage)")
                        completion(.failure("Server returned error - \(errorMessage)"))
                        return
                    }
                } else {
                    guard let data = data else {
                        print("ImageUploadHandler: No data returned from server.")
                        completion(.failure("ImageUploadHandler: No data returned from server."))
                        return
                    }
                    
                    guard let response = try? JSONSerialization.jsonObject(with: data) as? [String : String],
                          let url = response["url"] else {
                        print("ImageUploadHandler: Error parsing JSON.")
                        completion(.failure("ImageUploadHandler: Error parsing JSON."))
                        return
                    }
                    print("ImageUploadHandler: Image uploaded successfully.")
                    let payload: [String : String] = [
                        "object" : object.object,
                        "url" : url
                    ]
                    nextWorkflowHandler?.process(payload, completion: completion)
                }
            }
        }
        .resume()
    }
}
