import Foundation
import Vision
import SwiftSoup

/**
 https://colinchswift.github.io/2023-10-23/11-21-18-411862-implementing-face-recognition-and-identification-with-the-vision-framework-and-photokit/
 */

/**
    We did not further pursue this option. Although it did show potential for the "Person"-usecase.
 */

class FaceIdentificationHandler: WorkflowHandler {
    var description: String = "Face-Identification"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        completion(.failure("NOT IMPLEMENTED"))
    }
    
    
    func process(_ input: Any) -> Any {
        return 1
    }
    
    
    var nextWorkflowHandler: (any WorkflowHandler)?
    private var suspects: [VNFaceObservation: String] = [:]
    
    private let faceDetectionRequest = VNDetectFaceRectanglesRequest { result, error in
        guard let observations = result.results as? [VNFaceObservation] else {
            print("FaceIdentificationHandler: No faces were extracted!")
            return
        }
        for observation in observations {
            print("Face: \(observation.description)")
        }
    }
    
    
    init(nextWorkflowHandler: (any WorkflowHandler)? = nil) {
        self.nextWorkflowHandler = nextWorkflowHandler
        initializeFacePrints()
    }
    
    func processImage(objectInformation: ObjectInformation) {
        guard let image = objectInformation.image else {
            print("FaceIdentificationHandler: image is nil.")
            return
        }
        
        let request = VNDetectFaceLandmarksRequest { request, error in
            if error != nil {
                print("FaceIdentificationHandler: Error requesting face detection on processed image.")
                return
            }
            
            guard let results = request.results as? [VNFaceObservation], let face = results.first else {
                print("FaceIdentificationHandler: No face detected!")
                return
            }
            if let bestMatch = self.findMatchingFace(for: face) {
                print("Identified person: \(bestMatch)")
                //objectInformation.addObjectDescription(new: FaceRecognitionObject(name: bestMatch.0, confidence: bestMatch.1)) 
            } else {
                print("No match found.")
                return
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Error in FaceIdentificationHandler: \(error.localizedDescription)")
        }
    }
    
    private func findMatchingFace(for face: VNFaceObservation) -> (String, Float)? {
        guard let faceLandmarks = face.landmarks?.allPoints?.normalizedPoints else { return nil }
        
        for (k, v) in suspects {
            guard let suspectLandmarks = k.landmarks?.allPoints?.normalizedPoints else { continue }
            let distance = euclideanDistance(face1: suspectLandmarks, face2: faceLandmarks)
            if distance < Constants.FACE_SIMILARITY_THRESHOLD_DEFAULT {
                return (v, distance)
            }
        }
        return nil
    }
    
    private func euclideanDistance(face1 points1: [CGPoint], face2 points2: [CGPoint]) -> Float {
        guard points1.count == points2.count else { return .greatestFiniteMagnitude }
        
        var totalDistance: Float = 0.0
        for i in 0..<points1.count {
            let dx = Float(points1[i].x - points2[i].x)
            let dy = Float(points1[i].y - points2[i].y)
            totalDistance += sqrt(dx * dx + dy * dy)
        }
        return totalDistance / Float(points1.count) // Normalize
    }
    
    private func initializeFacePrints() {
        // This function will have to call the DBIS webpage to retrieve the pictures for certain personelle
        
        guard let dbisTeamPage = URL(string: "https://url-to-faces.com/team/") else { return }
        
        HTMLRetrieverService.shared.fetchHTML(for: dbisTeamPage) { teamHtml in
            if let html = teamHtml {
                do {
                    let document = try SwiftSoup.parse(html)
                    print(document) // TODO: retrieve all the people (name and link)
                    // TODO: append "/foto.jpg" to the link as this is our image we want
                    let nameLinks: [(String, URL)] = []
                    
                    // For all people fetch the html and if there is an image, get it
                    for (name, link) in nameLinks {
                        HTMLRetrieverService.shared.fetchImage(from: link) { cgImage in
                            if let cgImage = cgImage {
                                let faceIdentificationRequest = VNDetectFaceLandmarksRequest { request, error in
                                    if error != nil {
                                        print("FaceIdentificationHandler: Error when trying to create landmarks for \(name)")
                                        return
                                    }
                                    
                                    guard let result = request.results?.first as? VNFaceObservation else {
                                        print("FaceIdentificationHandler: Error creating landmarks for \(name)")
                                        return
                                    }
                                    self.suspects.updateValue(name, forKey: result)
                                }
                                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                                do {
                                    try handler.perform([faceIdentificationRequest])
                                } catch {
                                    print("FaceIdentificationHandler: Error detecting DBIS face: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                } catch {
                    print("Error retrieving names from DBIS-webpage.")
                }
            } else {
                print("FaceIdentificationHandler: Error retrieving DBIS-Team Page.")
                return
            }
        }
    }
}
