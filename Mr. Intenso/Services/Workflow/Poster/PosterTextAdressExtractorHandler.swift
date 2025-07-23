import Foundation
import MapKit

class PosterTextAdressExtractorHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    var description: String = "Location"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        guard let text = input as? String else {
            print("PosterTextLocationExtractorHandler: Wrong Input.")
            completion(.failure("Wrong Input."))
            return
        }
        print("Running in App Extension: \(Bundle.main.bundlePath.hasSuffix(".appex"))")
        // our goal is to extract any location contained in the input
        // the problem is, that adresses are not really Regex-able
        
        // Preprocessing query:
        let wordList = text.wordList
        let zip_codes = wordList.filter({ $0.count == 4 && $0.allSatisfy({ $0.isNumber }) })
        var streets = wordList.filter({ isStreet($0) })
        streets.append(contentsOf: getStreetCandidates(word: text))
        let numbers = wordList.filter { word in word.contains { $0.isNumber } }
        
        // I think not removing words from raw_text is better to not lose spacial information
        // maybe add cities here as well
        let payload = [
            "raw_text": text,
            "preprocessed": [
                "zip_codes": zip_codes,
                "streets": streets,
                "numbers": numbers,
                "cities": []
            ]
        ] as [String : Any]
        print("PosterTextAdressExtractorHandler: \(payload)")
        guard let url = URL(string: "https://myurl.com/location") else {
            print("PosterTextAdressExtractionHandler: URL is nil")
            completion(.failure("URL is nil."))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("PosterTextAdressextractorHandler: Failed to serialize payload")
            completion(.failure("Failed to serialize payload"))
            return
        }
        print("PosterTextAdressExtractorHandler: About to perform request")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                print("FetchChanges: No data returned")
                completion(.failure("No data returned!"))
                return
            }
            
            
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                if let errorMessage = json?["error"] as? String {
                    print("PosterTextAdressExtractorHandler: Error: \(errorMessage)")
                    completion(.failure(errorMessage))
                    return
                }
                print("PosterTextAdressExtractorHandler: Retrieving coordinates")
                if let message = json?["message"] as? String,
                   let x = json?["x"] as? Double,
                   let y = json?["y"] as? Double,
                   let adress = json?["address"] as? String,
                   let city = json?["name"] as? String {
                    print("PosterTextAdressExtractorHandler: \(message) with coordinates \(x), \(y)")
                    let coordinates = CLLocationCoordinate2D(latitude: x, longitude: y)
                    completion(.success(Location(coordinates: coordinates, adress: adress, city: city)))
                } else {
                    print("PosterTextAdressExtractorHandler: Missing or invalid data: \(json)")
                    completion(.failure("Missing or invalid data"))
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                completion(.failure("Unknown error"))
                return
            }
        }
        .resume()
    }
    
    private func isStreet(_ word: String) -> Bool {
        let streetChunks = ["strasse", "str.", "weg", "platz", "gasse"]
        return streetChunks.contains { chunk in
            word.lowercased().contains(chunk)
        }
    }
    
    private func getStreetCandidates(word: String) -> [String] {
        let wordList = word.wordList
        if wordList.isEmpty { return [] }
        var resultList: Set<String> = []
        for i in 1..<wordList.count {
            let current = wordList[i]
            let previous = wordList[i - 1]
            // Adding strings which are before a string containng a number and itself not containing a number
            // those are potential streets
            if current.contains(where: { $0.isNumber }) && !previous.contains(where: { $0.isNumber }) {
                resultList.insert(previous)
            }
            
            // Mittlere Strasse (Current = Strasse, Previous = Mittlere)
            if isStreet(current)
                && !previous.contains(where: { $0.isNumber })
                && !current.contains(where: { $0.isNumber }) {
                let current = current.lowercased().replacingOccurrences(of: "str.", with: "strasse")
                
                resultList.insert(
                    (previous.appending(current))
                    .lowercased().filter { char in
                        char.isLetter
                    })
            }
        }
        return Array(resultList)
    }
}
