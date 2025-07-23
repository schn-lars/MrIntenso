import SwiftUI
import AVFoundation
import Vision
import Photos

@MainActor // Now everything is done automatically on the main thread
protocol CameraViewControllerDelegate: AnyObject {
    func onPredict(result: YOLOResult, type: PredictorType)
    func onInferenceTime(speed: Double, fps: Double)
    func setPickedImage(_ image: UIImage)
}

struct CameraViewRepresentable: UIViewControllerRepresentable {
    @EnvironmentObject var viewModel: VideoFeedViewModel
    @EnvironmentObject var settings: Settings
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let controller = viewModel.videoFeed
        controller.delegate = viewModel
        controller.settings = settings // inject settings into class
        
        controller.setUp(
            sessionPreset: .hd1280x720,
            position: .back,
            orientation: UIDevice.current.orientation
        ) { success in
            if success {
                controller.start()
            } else {
                fatalError("Camera-Setup has failed. This no good.")
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

func getBestCaptureDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice {
  if UserDefaults.standard.bool(forKey: "use_telephoto"),
    let device = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: position)
  {
    return device
  } else if let device = AVCaptureDevice.default(
    .builtInDualCamera, for: .video, position: position)
  {
    return device
  } else if let device = AVCaptureDevice.default(
    .builtInWideAngleCamera, for: .video, position: position)
  {
    return device
  } else {
    fatalError("Missing expected back camera device.")
  }
}


class VideoFeed: UIViewController {
    weak var delegate: CameraViewControllerDelegate?
    
    private var captureSession = AVCaptureSession()
    private var captureDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let cameraQueue = DispatchQueue(label: "com.intenso.cameraQueue")
    
    private let predictorQueue = DispatchQueue(label: "com.intenso.predictorQueue", qos: .userInitiated)
    private let posterPredictorQueue = DispatchQueue(label: "com.intenso.posterPredictorQueue", qos: .userInitiated)

    var previewLayer = AVCaptureVideoPreviewLayer()
    var predictor: Predictor!
    var posterPredictor: Predictor!
    var baseResult: YOLOResult?
    
    private var currentBuffer: CVPixelBuffer?
    private var frameSizeCaptured: Bool = false
    var longSide: CGFloat = 3
    var shortSide: CGFloat = 4
    
    var settings: Settings!
    private var staticImageLayer = CALayer()
    private var isShowingPickedImage: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        staticImageLayer.contentsGravity = .resizeAspect
        staticImageLayer.masksToBounds = true
        staticImageLayer.frame = view.bounds
        view.layer.insertSublayer(staticImageLayer, above: previewLayer)
        
        if let mainLayer = (delegate as? VideoFeedViewModel)?.mainLayer {
            view.layer.addSublayer(mainLayer)
            mainLayer.bounds = view.bounds
            print("Add mainlayer to view")
        }
    }
    
    private func aspectFitFrame(for imageBounds: CGRect, in containerBounds: CGRect) -> CGRect {
        let imageAspect = imageBounds.width / imageBounds.height
        let containerAspect = containerBounds.width / containerBounds.height

        var targetFrame = containerBounds
        if imageAspect > containerAspect {
            // Image is wider than the container
            let height = containerBounds.width / imageAspect
            targetFrame.origin.y += (containerBounds.height - height) / 2
            targetFrame.size.height = height
        } else {
            // Image is taller than the container
            let width = containerBounds.height * imageAspect
            targetFrame.origin.x += (containerBounds.width - width) / 2
            targetFrame.size.width = width
        }
        return targetFrame
    }
    
    /**
            This method sets layout options. Keep in mind, that we needed to add the segmenation layers to it aswell.
            The *mainLayer* is the container holding the other layers.
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        staticImageLayer.frame = view.bounds
        staticImageLayer.contentsGravity = .resizeAspect

        let containerBounds = view.bounds
        var imageSize: CGSize = containerBounds.size
        
        if isShowingPickedImage {
            let cgImage = staticImageLayer.contents as! CGImage
            imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        }

        let imageFrame = aspectFitFrame(for: CGRect(origin: .zero, size: imageSize), in: containerBounds)

        if let mainLayer = (delegate as? VideoFeedViewModel)?.mainLayer {
            mainLayer.frame = imageFrame
            mainLayer.setNeedsDisplay()
        }
    }
    
    /**
        This method is basically onCreate in Android. We can add boolean (initialBoot) which lets us display something when starting the app.
        Think about clippy for example. We could initiate this process from here.
     */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setUp(
      sessionPreset: AVCaptureSession.Preset = .hd1280x720,
      position: AVCaptureDevice.Position,
      orientation: UIDeviceOrientation,
      completion: @escaping (Bool) -> Void
    ) {
      cameraQueue.async {
        let success = self.setUpCamera(
          sessionPreset: sessionPreset, position: position, orientation: orientation)
        DispatchQueue.main.async {
          completion(success)
        }
      }
    }
    
    /**
            This sets up the camera's functionalities needed to work.
     */
    func setUpCamera(
      sessionPreset: AVCaptureSession.Preset, position: AVCaptureDevice.Position,
      orientation: UIDeviceOrientation
    ) -> Bool {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = sessionPreset

        captureDevice = getBestCaptureDevice(position: position)
        videoInput = try! AVCaptureDeviceInput(device: captureDevice!)

        if videoInput == nil {
            fatalError("Could not initialize Video-Input. This sucks.")
        }
        
        if captureSession.canAddInput(videoInput!) {
            captureSession.addInput(videoInput!)
        }
        var videoOrientaion = AVCaptureVideoOrientation.portrait
        switch orientation {
        case .portrait:
            videoOrientaion = .portrait
        case .landscapeLeft:
            videoOrientaion = .landscapeRight
        case .landscapeRight:
            videoOrientaion = .landscapeLeft
        default:
            videoOrientaion = .portrait
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resize
        previewLayer.connection?.videoOrientation = videoOrientaion
        self.previewLayer = previewLayer
        DispatchQueue.main.async {
            self.view.layer.insertSublayer(self.previewLayer, at: 0)
            self.previewLayer.frame = self.view.bounds
        }

        let settings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput!.videoSettings = settings
        videoOutput!.alwaysDiscardsLateVideoFrames = true
        videoOutput!.setSampleBufferDelegate(self, queue: cameraQueue)
        if captureSession.canAddOutput(videoOutput!) {
            captureSession.addOutput(videoOutput!)
        }
        
      // We want the buffers to be in portrait orientation otherwise they are
      // rotated by 90 degrees. Need to set this _after_ addOutput()!
      // let curDeviceOrientation = UIDevice.current.orientation
      let connection = videoOutput!.connection(with: AVMediaType.video)
      connection?.videoOrientation = videoOrientaion
      if position == .front {
        connection?.isVideoMirrored = true
      }

      // Configure captureDevice
      do {
        try captureDevice!.lockForConfiguration()
      } catch {
        print("device configuration not working")
      }
      // captureDevice.setFocusModeLocked(lensPosition: 1.0, completionHandler: { (time) -> Void in })
      if captureDevice!.isFocusModeSupported(AVCaptureDevice.FocusMode.continuousAutoFocus),
        captureDevice!.isFocusPointOfInterestSupported
      {
        captureDevice!.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
        captureDevice!.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
      }
      captureDevice!.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
      captureDevice!.unlockForConfiguration()

      captureSession.commitConfiguration()
      return true
    }

    func start() {
        DispatchQueue.main.async {
            print("Restarting live camera feed...")

            self.staticImageLayer.contents = nil
            self.staticImageLayer.isHidden = true
            self.isShowingPickedImage = false
            self.previewLayer.isHidden = false

            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()

            if !self.captureSession.isRunning {
                DispatchQueue.global().async {
                    self.captureSession.startRunning()
                }
            }
        }
    }

    func stop() {
        if captureSession.isRunning {
            DispatchQueue.global().async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    /**
            This code block is taken from the YOLO ios-app,
     */
    private func runFrameInference(_ sampleBuffer: CMSampleBuffer) {
        guard let predictor = self.predictor else {
            print("Failed to run inference: predictor is nil")
            return
        }
        
        guard let posterPredictor = self.posterPredictor else {
            print("Failed to run inference: posterPredictor is nil")
            return
        }
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            currentBuffer = pixelBuffer
            if !frameSizeCaptured {
                let frameWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
                let frameHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
                longSide = max(frameWidth, frameHeight)
                shortSide = min(frameWidth, frameHeight)
                frameSizeCaptured = true
            }
            // Chaining both active models
            predictorQueue.async {
                predictor.predict(sampleBuffer: sampleBuffer, onResultsListener: self, onInferenceTime: self)
            }
            posterPredictorQueue.async {
                posterPredictor.predict(sampleBuffer: sampleBuffer, onResultsListener: self, onInferenceTime: self)
            }
        }
    }
    
    /**
        This method saves an image to the camera roll. We are not selecting the controls as part of the photo captured.
        https://stackoverflow.com/questions/39631256/request-permission-for-camera-and-library-in-ios-10-info-plist
     */
    func saveCurrentImageToCameraRoll() {
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({ status in
                if status != .authorized {
                    print("Negative authorization status for camera roll!")
                    return
                }
            })
        }
        if photos != .authorized {
            // TODO: maybe add alert here
            print("No access to the camera roll has been granted!")
            return
        }
        
        DispatchQueue.main.async {
            guard let lastFrame = self.getLastFrameAsImage() else {
                print("Failed to save image: last frame is nil")
                return
            }

            let renderer = UIGraphicsImageRenderer(size: self.view.bounds.size)
            let image = renderer.image { context in
                let imageRect: CGRect

                if self.isShowingPickedImage {
                    print("Saving in picked image")
                    context.cgContext.setFillColor(UIColor.black.cgColor)
                    context.cgContext.fill(CGRect(origin: .zero, size: self.view.bounds.size))

                    imageRect = AVMakeRect(aspectRatio: lastFrame.size, insideRect: self.view.bounds)
                    lastFrame.draw(in: imageRect)

                    context.cgContext.translateBy(x: imageRect.origin.x, y: imageRect.origin.y)
                } else {
                    print("Saving in video image")
                    lastFrame.draw(in: CGRect(origin: .zero, size: self.view.bounds.size))
                }

                if let mainLayer = (self.delegate as? VideoFeedViewModel)?.mainLayer {
                    mainLayer.render(in: context.cgContext)
                }
            }

            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
    
    func getLastFrameAsImage() -> UIImage? {
        guard let pixelBuffer = currentBuffer else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

extension VideoFeed: AVCaptureVideoDataOutputSampleBufferDelegate {
    /**
        This function is being called every time a frame is captured.
     */
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        runFrameInference(sampleBuffer)
    }
}

extension VideoFeed: ResultsListener, InferenceTimeListener {
    func on(result: YOLOResult, type: PredictorType) {
        self.delegate?.onPredict(result: result, type: type)
    }
    
    func on(inferenceTime: Double, fpsRate: Double) {
        self.delegate?.onInferenceTime(speed: inferenceTime, fps: fpsRate)
    }
}

extension VideoFeed: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func presentImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true, completion: nil)

        guard let image = info[.originalImage] as? UIImage else {
            print("No image found")
            start()
            return
        }
        
        if let asset = info[.phAsset] as? PHAsset, let location = asset.location {
            print("Image location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            (delegate as? VideoFeedViewModel)?.metadataLocation = CLLocation(
                latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        } else {
            print("No location metadata found in selected image.")
        }
        
        let fixedImage = image.fixOrientation()
        
        guard let resizedImage = fixedImage.resizeImage(to: CGSize(width: 720, height: 1280)) else {
            print("Resize failed")
            return
        }
        
        // Convert UIImage to CVPixelBuffer
        guard let pixelBuffer = resizedImage.toPixelBuffer() else {
            print("Could not convert UIImage to CVPixelBuffer")
            start()
            return
        }
        
        guard let sampleBuffer = pixelBuffer.createSampleBufferFrom() else {
            print("Could not create CMSampleBuffer from CVPixelBuffer")
            start()
            return
        }
        
        isShowingPickedImage = true

        let cgImage = resizedImage.cgImage ?? CIContext().createCGImage(CIImage(image: resizedImage)!, from: CIImage(image: resizedImage)!.extent)
        staticImageLayer.contents = cgImage
        staticImageLayer.isHidden = false
        previewLayer.isHidden = true
        
        DispatchQueue.main.async { // force re-draw
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
        print("Running inference for picked image now...")
        self.runFrameInference(sampleBuffer)
    }
}
