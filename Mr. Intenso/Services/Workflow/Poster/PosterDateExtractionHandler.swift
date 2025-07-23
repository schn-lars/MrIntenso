import Foundation

class PosterDateExtractionHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    var description: String = TranslationUnit.getMessage(for: .POSTER_TITLE_DATE) ?? "Date"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        print("PosterDateExtractionHandler: Starting...")
        guard let objectInfo = input as? ObjectInformation else {
            print("PosterDateExtractionHandler: Requires an objectinformation as input. Got \(type(of: input)) instead.")
            completion(.failure("Requires an objectinformation as input. Got \(type(of: input)) instead."))
            return
        }
        
        guard let intermediateTextObject = objectInfo.detailedDescription.first(where: { $0 is IntermeditateTextObject }), let intermediateText = intermediateTextObject.description else {
            print("PosterDateExtractionHandler: Missing intermediateText for this objectinformation")
            completion(.failure("Missing intermediateText for this objectinformation"))
            return
        }
        print("PosterDateExtractionHandler: Found intermediate text")
        // Do we have a location to it?
        let locationObject = objectInfo.detailedDescription.first(where: { $0 is LocationObject }) as? LocationObject
        print("PosterDateExtractionHandler: Checked location \(locationObject == nil)")
        guard let url = URL(string: "https://myurl.com/date") else {
            print("PosterDateExtractionHandler: Could not create the URL.")
            completion(.failure("PosterDateExtractionHandler: Could not create the URL."))
            return
        }
        //let text = "Ich muss diese arbeit heute abgeben. Nächstes Jahr werde ich wieder arbeiten. September 10 - 12"
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: ["text": intermediateText], options: [])
        } catch {
            print("PosterDateExtractionHandler: Error creating JSON \(error.localizedDescription)")
            completion(.failure("Error creatinng JSON"))
            return
        }
        
        print("Sending...")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    if let data,
                    let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                       let errorMessage = errorDict["error"] {
                        print("PosterDateExtractionHandler: Server returned error - \(errorMessage)")
                        completion(.failure("Server returned error \(errorMessage)"))
                        return
                    }
                } else {
                    print("PosterDateExtractionHandler: Received...")
                    guard let data = data else {
                        print("PosterDateExtractionHandler: Data is nil")
                        completion(.failure("Data is nil"))
                        return
                    }
                    
                    if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                        let dates = jsonResponse["dates"] as? [String]
                        {
                        print("PosterDateExtractionHandler: Received \(dates)")
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd/MM/yyyy"
                        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                        
                        var suggestedDates: [EventObject] = []
                        for dateString in dates {
                            // String of format dd/MM/yyyy
                            if let date = dateFormatter.date(from: dateString) {
                                if date < Date() {
                                    print("PosterDateExtractionHandler: \(dateString) is in the past")
                                    continue
                                }
                                
                                let eventObject = EventObject(
                                    start: date,
                                    location: locationObject?.location
                                )
                                suggestedDates.append(eventObject)
                            } else {
                                print("Invalid date string: \(dateString)")
                            }
                        }
                        
                        print("PosterDateExtractionHandler: Returning \(suggestedDates.count) suggested dates")
                        completion(.success(
                            DateObject(
                                title: TranslationUnit.getMessage(for: .DATE_TITLE) ?? "Calendar",
                                suggestedEvents: suggestedDates
                            )
                        ))
                        return
                    } else {
                        print("PosterDateExtractionHandler: JSON serialization failed")
                        completion(.failure("JSON-Serialization failed"))
                        return
                    }
                }
            }
        }
        .resume()
    }
}
