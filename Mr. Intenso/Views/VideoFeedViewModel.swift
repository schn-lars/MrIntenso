/**
 
        MARK: This view-model is heavily spicked with code of: https://github.com/MaciDE/YOLOv8-seg-iOS
        I have modified it to match my desires.
 
 
 */

import Combine
import PhotosUI
import SwiftUI
import Vision
import Reachability

// MARK: ContentViewModel
class VideoFeedViewModel: ObservableObject, CameraViewControllerDelegate {
    @Published var detectedMasks: YOLOResult? = nil
    @Published var detectedPosters: YOLOResult? = nil
    @Published var isFrozen: Bool = false
    @Published var metadataLocation: CLLocation? = nil
    
    let reachability = try! Reachability()
    
    // Layers
    @Published var mainLayer = CALayer()
    @Published var maskLayer: CALayer?
    @Published var postersLayer: CALayer?
    @Published var pickedImage: UIImage?
    @Published var groupedPatchNodes: [PatchNoteSection] = []
    @Published var showPatchNotes: Bool = false
    
    @Published var videoFeed: VideoFeed
    
    var cancellables = Set<AnyCancellable>()
    
    // Those are variables needed inside the VideoFeedView
    @Published var baseLegendItems: [(key: String, color: UIColor)] = []
    @Published var posterLegendItems: [(key: String, color: UIColor)] = []
    @Published var legendItems: [(key: String, color: UIColor)] = []
    @Published var message: String? = nil
    @Published var uiImage: UIImage?
    
    @MainActor @Published var processing: Bool = false
    
    @Published var combinedMaskImage: UIImage?
    
    @Published var isReady: Bool = false

    private var baseModelReady = false
    private var posterModelReady = false
    private var fetchedChanges: Bool = false
    
    var settings: Settings!
    let messageCenter: MessageCenter
    
    init(settings: Settings, messageCenter: MessageCenter = .shared) {
        self.messageCenter = messageCenter
        self.settings = settings
        self.videoFeed = VideoFeed()
        self.videoFeed.delegate = self
        setupModel()
        setupMaskLayer()
        setupPosterskLayer()
        Publishers.CombineLatest($baseLegendItems, $posterLegendItems)
            .map { base, poster in
                let combined = base + poster
                let combinedDict = Dictionary(uniqueKeysWithValues: combined)
                return combinedDict
                    .sorted { $0.key < $1.key }
                    .map { (key, color) in (key: key, color: color) }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.legendItems, on: self)
            .store(in: &cancellables)
    }
    
    private func checkReadiness() {
        if baseModelReady && posterModelReady {
            DispatchQueue.main.async {
                self.isReady = true
                print("Now ready!")
            }
        }
    }
    
    private func setupModel() {
        func handleBaseSuccess(predictor: Predictor) {
            predictor.configure(settings: settings, type: .base)
            self.videoFeed.predictor = predictor
            self.baseModelReady = true
            checkReadiness()
            print("Set base-predictor!")
        }
        
        func handlePostersSuccess(predictor: Predictor) {
            predictor.configure(settings: settings, type: .posters)
            self.videoFeed.posterPredictor = predictor
            self.posterModelReady = true
            checkReadiness()
            print("Set poster-predictor!")
        }
        
        func handleFailure(error: Error) {
            fatalError("Failed to load model: \(error)")
        }
        
        // Base model
        var modelURL: URL?
        let lowercasedBasePath = "yolo11n-seg" // yolo11x-seg
        let fileManager = FileManager.default

        if lowercasedBasePath.hasSuffix(".mlmodel") || lowercasedBasePath.hasSuffix(".mlpackage")
          || lowercasedBasePath.hasSuffix(".mlmodelc")
        {
          let possibleURL = URL(fileURLWithPath: lowercasedBasePath)
          if fileManager.fileExists(atPath: possibleURL.path) {
            modelURL = possibleURL
          }
        } else {
          if let compiledURL = Bundle.main.url(forResource: lowercasedBasePath, withExtension: "mlmodelc")
          {
            modelURL = compiledURL
          } else if let packageURL = Bundle.main.url(
            forResource: lowercasedBasePath, withExtension: "mlpackage")
          {
            modelURL = packageURL
          }
        }
        
        guard let unwrappedBaseModelURL = modelURL else {
          let error = PredictorError.modelFileNotFound
          fatalError(error.localizedDescription)
        }
        
        // Posters Model
        var postersModelURL: URL?
        let lowercasedPostersPath = "posters11" // yolo11x-seg

        if lowercasedPostersPath.hasSuffix(".mlmodel") || lowercasedPostersPath.hasSuffix(".mlpackage")
          || lowercasedPostersPath.hasSuffix(".mlmodelc")
        {
          let possibleURL = URL(fileURLWithPath: lowercasedPostersPath)
          if fileManager.fileExists(atPath: possibleURL.path) {
            modelURL = possibleURL
          }
        } else {
          if let compiledURL = Bundle.main.url(forResource: lowercasedPostersPath, withExtension: "mlmodelc")
          {
            modelURL = compiledURL
          } else if let packageURL = Bundle.main.url(
            forResource: lowercasedPostersPath, withExtension: "mlpackage")
          {
            modelURL = packageURL
          }
        }

        guard let unwrappedPostersModelURL = modelURL else {
          let error = PredictorError.modelFileNotFound
          fatalError(error.localizedDescription)
        }
        
        Segmenter.create(unwrappedModelURL: unwrappedBaseModelURL, isRealTime: true) {
            [weak self] result in
            switch result {
            case .success(let predictor):
                handleBaseSuccess(predictor: predictor)
            case .failure(let error):
                handleFailure(error: error)
            }
        }
        
        Segmenter.create(unwrappedModelURL: unwrappedPostersModelURL, isRealTime: true) {
            [weak self] result in
            switch result {
            case .success(let predictor):
                handlePostersSuccess(predictor: predictor)
            case .failure(let error):
                handleFailure(error: error)
            }
        }
    }
    
    
    
    /**
        This method sets up the mask layer.
     */
    private func setupMaskLayer() {
        if maskLayer != nil { return }
        let layer = CALayer()
        layer.frame = UIScreen.main.bounds // might not be initialized yet
        layer.opacity = 0.5
        layer.name = "MaskLayer"
        
        mainLayer.addSublayer(layer)
        self.maskLayer = layer
    }
    
    /**
        This method sets up the mask layer.
     */
    private func setupPosterskLayer() {
        if postersLayer != nil { return }
        let layer = CALayer()
        layer.frame = UIScreen.main.bounds // might not be initialized yet
        layer.opacity = 0.5
        layer.name = "PostersLayer"
        
        mainLayer.addSublayer(layer)
        self.postersLayer = layer
    }
    
    /**
     https://stackoverflow.com/questions/42997462/convert-cmsamplebuffer-to-uiimage
     */
    func convert(cmage: CIImage) -> UIImage {
         let context = CIContext(options: nil)
        let cgImage = context.createCGImage(cmage, from: cmage.extent)!
        let image = UIImage(cgImage: cgImage)
         return image
    }
    
    /**
            This mehod displays a message above the camera-button. If a delay is given, the message will disappear after that amount of time.
            Otherwise it will stay until changed by another function call.
     */
    func displayMessage(for message: String, delay seconds: Double? = nil) {
        self.message = message
        if let seconds = seconds {
            autoDismissMessage(after: seconds)
        }
    }
    
    /**
            This method sets the message back to nil after some time.
     */
    private func autoDismissMessage(after seconds: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.message = nil
        }
    }
    
    func onPredict(result: YOLOResult, type: PredictorType) {
        // show masks on the layer
        switch type {
        case .base:
            DispatchQueue.main.async {
                if let maskImage = result.masks?.combinedMask {
                    guard let maskLayer = self.maskLayer else {
                        print("MaskLayer was nil")
                        self.setupMaskLayer()
                        return
                    }
                    maskLayer.isHidden = false
                    maskLayer.frame = self.mainLayer.bounds
                    maskLayer.contents = maskImage
                    
                    var classColors: [String : UIColor] = [:]
                    for box in result.boxes {
                        if box.conf > self.settings.segmentation {
                            let index = Constants.getClassIdx(from: box.cls) % ultralyticsColors.count
                            classColors[box.cls] = ultralyticsColors[index]
                        }
                    }
                    let sortedClassColors = classColors
                        .sorted { $0.key < $1.key }
                        .map { (key, value) in (key: key, color: value) }
                    self.baseLegendItems = sortedClassColors
                    self.detectedMasks = result
                    self.videoFeed.predictor.isUpdating = false
                } else {
                    self.videoFeed.predictor.isUpdating = false
                }
            }
        case .posters:
            DispatchQueue.main.async {
                if let maskImage = result.masks?.combinedMask {
                    guard let postersLayer = self.postersLayer else {
                        print("PosterLayer was nil")
                        return
                    }
                    postersLayer.isHidden = false
                    postersLayer.frame = self.mainLayer.bounds
                    postersLayer.contents = maskImage
                    
                    var classColors: [String : UIColor] = [:]
                    for box in result.boxes {
                        if box.conf > self.settings.segmentation {
                            let index = 80 % ultralyticsColors.count
                            classColors[box.cls] = ultralyticsColors[index]
                        }
                    }
                    let sortedClassColors = classColors
                        .sorted { $0.key < $1.key }
                        .map { (key, value) in (key: key, color: value) }
                    self.posterLegendItems = sortedClassColors
                    self.detectedPosters = result
                    self.videoFeed.predictor.isUpdating = false
                } else {
                    self.videoFeed.predictor.isUpdating = false
                }
            }
        }
    }
    
    // MARK: UI-Methods
    
    /**
            This method is being called when the user decides to freeze the screen.
     */
    func onFreezeScreen() {
        // TODO: Possibly add option, where we automatically return to the regular videofeed, if no masks are rendered
        self.videoFeed.stop()
        if let msg = TranslationUnit.getMessage(for: .SELECT_MASK) {
            self.messageCenter.displayMessage(for: msg)
        }
    }
    
    /*
        This function is being called, when the user wants to select an object.
        In order to process the selected object, we need to return an ObjectInformation object.
     */
    func clickedMask(at point: CGPoint) -> ObjectInformation? {
        guard let baseResult = detectedMasks, let posterResult = detectedPosters else {
            if let msg = TranslationUnit.getMessage(for: .INVALID_MASK_SELECTION) {
                self.messageCenter.displayMessage(for: msg, delay: 2.0)
            }
            return nil
        }
        
        guard let baseMasks = baseResult.masks, let posterMasks = posterResult.masks else {
            if let msg = TranslationUnit.getMessage(for: .INVALID_MASK_SELECTION) {
                self.messageCenter.displayMessage(for: msg, delay: 2.0)
            }
            return nil
        }
        let imageSize = baseResult.orig_shape // (720, 1280); Dimensions are the same in both results
        let maskSize = CGSize(width: 160, height: 160)

        // Convert from view-space point to image-space point
        let scaleToImageX = imageSize.width / UIScreen.main.bounds.width // .. / 393
        let scaleToImageY = imageSize.height / UIScreen.main.bounds.height // .. / 852
        let imageX = point.x * scaleToImageX
        let imageY = point.y * scaleToImageY

        // Convert from image-space to mask-space (Resizing does not only affect the input but also output)
        let scaleToMaskX = maskSize.width / imageSize.width
        let scaleToMaskY = maskSize.height / imageSize.height
        let x = Int(imageX * scaleToMaskX)
        let y = Int(imageY * scaleToMaskY)
        
        for (index, mask) in baseMasks.masks.enumerated() {
            guard y < mask.count, x < mask[y].count else {
                continue
            }

            let raw = mask[y][x]
            let prob = 1.0 / (1.0 + exp(-raw)) // sigmoid because it's "**** raw" ~ Gordon Ramsey
            if prob > settings.segmentation {
                print("This is a mask! (Instance \(baseResult.boxes[index].cls), Prob: \(prob))")
                let box = baseResult.boxes[index].xywh
                let cls = baseResult.boxes[index].cls
                return createObjectInformation(cls: cls, confidence: prob, boundingBox: box)
            }
        }
        
        // Lars excuses himself. He is aware this is cumbersome. Just go ahead.
        for (index, mask) in posterMasks.masks.enumerated() {
            guard y < mask.count, x < mask[y].count else {
                continue
            }

            let raw = mask[y][x]
            let prob = 1.0 / (1.0 + exp(-raw)) // sigmoid because it's "**** raw" ~ Gordon Ramsey
            if prob > settings.segmentation {
                print("This is a poster! (Instance \(posterResult.boxes[index].cls), Prob: \(prob))")
                let box = posterResult.boxes[index].xywh
                let cls = posterResult.boxes[index].cls
                return createObjectInformation(cls: cls, confidence: prob, boundingBox: box)
            }
        }
        if let msg = TranslationUnit.getMessage(for: .INVALID_MASK_SELECTION) {
            self.messageCenter.displayMessage(for: msg, delay: 2.0)
        }
        return nil
    }
    
    /**
        https://stackoverflow.com/questions/31254435/how-to-select-a-portion-of-an-image-crop-and-save-it-using-swift
     */
    private func createObjectInformation(cls: String, confidence: Float, boundingBox: CGRect) -> ObjectInformation {
        guard let cgImage = videoFeed.getLastFrameAsImage()?.cgImage else {
            fatalError("YOLOResult originalImage is nil.")
        }
        let croppedCG = cgImage.cropping(to: boundingBox)
        let croppedImage = croppedCG.map { UIImage(cgImage: $0) }
        print(metadataLocation != nil ? "CreateObjectInformation: We have location" : "CreateObjectInformation: We do not have location")
        return ObjectInformation(object: cls, confidence: confidence, croppedImage: croppedImage!, location: metadataLocation)
    }
    
    func download() {
        self.videoFeed.saveCurrentImageToCameraRoll()
    }
    
    /**
            This method is being called when the user decides to unfreeze the screen.
     */
    func onUnfreezeScreen() {
        self.pickedImage = nil
        self.metadataLocation = nil
        self.videoFeed.start()
    }
    
    func updateFreeze() {
        isFrozen = !isFrozen
    }
    
    func stopVideo() {
        videoFeed.stop()
    }
    
    func startVideo() {
        videoFeed.start()
    }
    
    func onInferenceTime(speed: Double, fps: Double) {
        // this method is being called to later display the inference time
        if isFrozen { return }
        DispatchQueue.main.async {
            if let msg = TranslationUnit.getMessage(for: .INFERENCE_FPS) {
                self.messageCenter.showMessage(
                    String(format: msg,
                          speed, fps
                          )
                )
            }
        }
    }
    
    func pickImage() {
        isFrozen = true
        videoFeed.stop()
        if let msg = TranslationUnit.getMessage(for: .SELECT_MASK) {
            self.messageCenter.displayMessage(
                for: String(format: msg)
            )
        }
        videoFeed.presentImagePicker()
    }
    
    func setPickedImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.pickedImage = image
        }
    }
    
    /**
            This method is triggered in onAppear of the VideoFeedView.
            It fetches the changes after the given commit hash.
     */
    func fetchChanges() {
        if fetchedChanges { return }
        
        reachability.whenUnreachable = { _ in
            print("You do not have internet access.")
            if let msg = TranslationUnit.getMessage(for: .NO_INTERNET) {
                MessageCenter.shared.displayMessage(for: msg, delay: 2.0)
            }
            return
        }
        
        /*if !Constants.isConnectedToVPN() { // this needs to be removed for user studies when we have a SSH tunnel
            print("You are not connected to the VPN!")
            MessageCenter.shared.displayMessage(for: "VPN is not connected!", delay: 2.0)
            return
        }*/
        
        guard let commitHash = UserDefaults.standard.string(forKey: "commitHash") else {
            print("Commit-Hash is nil")
            return
        }
        guard let url = URL(string: "https://myurl.com/patchnotes/\(commitHash)") else {
            print("FetchChanges: URL is nil")
            return
        }
        
        print("Fetching changes for commit hash: \(commitHash)")
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    if let data,
                    let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                       let errorMessage = errorDict["error"] {
                        print("\(#function): Server returned error - \(errorMessage)")
                        return
                    }
                }
            }
            guard let data = data,
                  error == nil else {
                // TODO: maybe add errormessage
                print("Failed to fetch changes!")
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
                
                if let errorMessage = jsonResponse?["error"] as? String {
                    print("Server error: \(errorMessage)")
                    DispatchQueue.main.async {
                        self.messageCenter.displayMessage(for: errorMessage, delay: 2.0)
                    }
                    return
                }
                
                if let message = jsonResponse?["message"] as? String {
                    print("Server message: \(message)")
                    DispatchQueue.main.async {
                        if let msg = TranslationUnit.getMessage(for: .VERSION_STATUS_OK) {
                            self.messageCenter.displayMessage(for: msg, delay: 2.0)
                        }
                    }
                    return
                }

                
                struct Response: Codable {
                    let commits: [PatchNote]
                }
                
                if let commitsData = jsonResponse?["commits"] {
                    let jsonData = try JSONSerialization.data(withJSONObject: ["commits": commitsData])
                    let decoded = try JSONDecoder().decode(Response.self, from: jsonData)

                    if let latest = decoded.commits.last {
                        UserDefaults.standard.set(latest.hash, forKey: "commitHash")
                        print("New latest hash: \(latest.hash)")
                    }

                    var sections: [PatchNoteSection] = []
                    for note in decoded.commits {
                        if let index = sections.firstIndex(where: { $0.date == note.date }) {
                            sections[index].messages.append(note.message)
                        } else {
                            sections.append(PatchNoteSection(date: note.date, messages: [note.message]))
                        }
                    }
                    sections.reverse()

                    DispatchQueue.main.async {
                        self.groupedPatchNodes = sections
                        self.showPatchNotes = !sections.isEmpty
                        self.fetchedChanges = true
                    }
                } else {
                    print("Unexpected response format")
                }
            } catch {
                print("FetchChanges: JSON decoding error:", error)
            }
        }
        .resume()
    }
}
