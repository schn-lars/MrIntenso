import Foundation
import SwiftUI

class PosterTextWebsiteExtractorHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    var description: String = TranslationUnit.getMessage(for: .POSTER_TITLE_TEXT) ?? "Website"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        guard let text = input as? String else {
            print("PosterTextWebsiteExtractorHandler: input must be a String")
            completion(.failure("PosterTextWebsiteExtractorHandler: input must be a String"))
            return
        }
        
        let textList = text.wordList
        
        // if it starts with "www." then it is very likely a website
        // i assume that this is a valid website. Nobody writes a website on a poster like that: www.xyz (without domain)
        let websiteCandidates = textList.filter { $0.contains("www.") }
        for candidate in websiteCandidates {
            // We want to check if there is a promising candidate, by checking if website is reachable
            //https://stackoverflow.com/questions/9616914/checking-reachability-against-a-specific-page-in-a-url/9617166#9617166
            
            if let url = URL(string: candidate) {
                isReachable(url: url) { status in
                    if status {
                        completion(.success(url))
                    }
                }
            }
        }
        
        // here we need to make this website a valid one, as it is common to write just youtube.com instead of the entire funny thing
        let domains = [".com", ".org", ".net", ".edu", ".ch", ".de"]
        let domainCandidates = textList.filter { word in
            domains.contains(where: { word.contains($0) }) // probably better than .hasSuffix
        }
        for candidate in domainCandidates {
            var candidate = candidate
            if !candidate.starts(with: "www.") {
                candidate.append(contentsOf: "www.")
            }
            
            if let url = URL(string: candidate) {
                isReachable(url: url) { status in
                    if status {
                        completion(.success(url))
                    }
                }
            }
        }
        print("Unable to extract any website from the text.")
        completion(.failure("Unable to extract any website from the text."))
    }
    
    private func isReachable(url: URL, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(true)
                }
            } else {
                print("PosterExtractorHandler: Could not reach URL for \(url.absoluteString)")
                completion(false)
            }
        }
        task.resume()
    }
}
