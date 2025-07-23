import Foundation
import ShazamKit
import AVKit

struct MusicRecognitionHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    var description: String = TranslationUnit.getMessage(for: .SHAZAM_TITLE) ?? "Music"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        // input does not matter
        print("MusicRecognitionHandler started")
        
        let shazam = Shazam()
        shazam.onMatch = { mediaItem in
            if let item = mediaItem {
                print("Matched: \(item.title ?? "Unknown") by \(item.artist ?? "Unknown")")
                completion(.success(item))
            } else {
                print("No match found.")
                completion(.failure("MusicRecognitionHandler: Could not recognize music."))
            }
        }
        shazam.listen()
    }
}
