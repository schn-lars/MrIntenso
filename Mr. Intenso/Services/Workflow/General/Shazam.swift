import Foundation
import ShazamKit
import AVKit

// https://ichi.pro/de/erkunden-von-shazamkit-mit-swiftui-in-ios-15-96183592803409
// https://github.com/SwapnanilDhol/Shazam-Kit-Tutorial/blob/main/shazamkittest/View-Model/ContentViewModel.swift

class Shazam: NSObject, ObservableObject, SHSessionDelegate {
    private let session = SHSession()
    private let audioEngine = AVAudioEngine()
    
    @Published var isListening: Bool = false
    var onMatch: ((SHMatchedMediaItem?) -> Void)?
    
    override init() {
        super.init()
        session.delegate = self
    }
    
    func listen() {
        guard !audioEngine.isRunning else {
            audioEngine.stop()
            DispatchQueue.main.async {
                self.isListening = false
            }
            return
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        
        AVAudioApplication.requestRecordPermission { granted in
            self.startListeningIfGranted(granted, session: audioSession)
        }
    }
    
    private func startListeningIfGranted(_ granted: Bool, session: AVAudioSession) {
        guard granted else {
            print("No microphone access.")
            DispatchQueue.main.async {
                self.onMatch?(nil) // Notify handler of failure
            }
            return
        }
        
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup error: \(error.localizedDescription)")
            return
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            buffer, _ in
            self.session.matchStreamingBuffer(buffer, at: nil)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
            }
        } catch {
            print("Audio engine start failed: \(error.localizedDescription)")
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        DispatchQueue.main.async {
            self.isListening = false
        }
    }
}

extension Shazam {
    func session(_ session: SHSession, didFind match: SHMatch) {
        stopListening()
        let mediaItem = match.mediaItems.first
        DispatchQueue.main.async {
            self.onMatch?(mediaItem)
        }
    }
    
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: (any Error)?) {
        stopListening()
        DispatchQueue.main.async {
            self.onMatch?(nil)
        }
    }
}
