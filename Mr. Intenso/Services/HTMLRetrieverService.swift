import Foundation
import CoreGraphics
import UIKit

/**
    This Service is used to fetch HTML content from any page. Since retrieving html sources is a rather prominent use case.
 */
final class HTMLRetrieverService {
    static let shared = HTMLRetrieverService()
    
    /**
     Fetch HTML asynchronously using async/await
     */
    private func fetchHTML(of url: URL) async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "HTMLConversionError", code: -1, userInfo: ["msg": "Error retrieving html for \(url.absoluteString)"])
        }
        return html
    }
    
    /**
            Fetching the html using a completion handler.
     
            USAGE: HTMLRetrieverService.fetchHTML(for: url) { html in
                if let html = html {
                    -- ACCESS HTML HERE
                } else {
                    --ERROR
                }
            }
     */
    func fetchHTML(for url: URL, completion: @escaping (String?) -> Void) {
        Task {
            do {
                let html = try await fetchHTML(of: url)
                completion(html)
            } catch {
                print("HTMLRetrieverService: Error fetching html: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    /**
            This method is responsible to download a given source from an url. This image will not be downloaded, but saved as an CGImage, which is useful for the Vision framework.
     */
    func fetchImage(from url: URL, completion: @escaping (CGImage?) -> Void) {
        Task {
            do {
                let cgImage = try await fetchImage(of: url)
                completion(cgImage)
            } catch {
                print("HTMLRetrieverService: Error fetching image: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    private func fetchImage(of url: URL) async throws -> CGImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let uiimage = UIImage(data: data), let cgImage = uiimage.cgImage else {
            throw NSError(domain: "HTMLRetrieverService", code: -1, userInfo: ["msg": "Failed to fetch image: \(url.absoluteString)"])
        }
        return cgImage
    }
    
    func sendDebugLog(_ message: String) {
        guard let url = URL(string: "https://myurl.com/log") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = message.data(using: .utf8)
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send log: \(error)")
            } else {
                print("Log sent: \(message)")
            }
        }
        task.resume()
    }
}
