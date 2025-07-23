import Foundation
import ARKit    

class BirdDatabaseHandler: WorkflowHandler {
    var description: String = TranslationUnit.getMessage(for: .BIRD_OCCURRENCES_TITLE) ?? "Occurrences"
    var locationManager: LocationManager
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        guard let birdName = input as? String else {
            print("\(#function): birdName is not a valid input!")
            completion(.failure("BirdName is not a valid input!"))
            return
        }
        // https://stackoverflow.com/questions/31077989/how-do-i-perform-get-and-post-requests-in-swift
        
        let url = URL(string: "https://myurl.com/birdplot")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        
        let userLocation = locationManager.location

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(birdName)\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"latitude\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userLocation?.coordinate.latitude ?? 0.0)\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"longitude\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userLocation?.coordinate.longitude ?? 0.0)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(UserDefaults.standard.string(forKey: UserDefaultsKeys.LANGUAGE.rawValue) ?? "ENG")\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("\(#function): Error \(error.localizedDescription)")
                completion(.failure(error.localizedDescription))
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
                print("\(#function): No data has been returned!")
                completion(.failure("No data is available for this bird."))
                return
            }
            
            guard let image = UIImage(data: data) else {
                print("\(#function): Decoding image went wrong.")
                completion(.failure("Image decoding went wrong."))
                return
            }
            completion(.success(image))
        }
        task.resume()
    }
}
