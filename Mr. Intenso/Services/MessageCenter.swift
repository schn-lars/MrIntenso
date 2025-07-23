import Foundation

/**
    This document contains our attempt to have a central messaging unit which aimed to have a responsive environment between user and application.
 */

class MessageCenter: ObservableObject {
    @Published var message: String?
    @Published var errorMessage: String?
    @Published var alertMessage: String?
    
    static let shared = MessageCenter()
    
    func showMessage(_ message: String) {
        DispatchQueue.main.async {
            self.message = message
        }
    }
    
    func showErrorMessage(_ errorMessage: String) {
        print("MessageCenter: Changing error message to \(errorMessage)")
        DispatchQueue.main.async {
            self.errorMessage = errorMessage
        }
    }
    
    func showAlertMessage(_ message: String) {
        DispatchQueue.main.async {
            self.alertMessage = message
        }
    }
    
    func clearMessage() {
        DispatchQueue.main.async {
            self.message = nil
        }
    }
    
    func clearErrorMessage() {
        DispatchQueue.main.async {
            self.errorMessage = nil
        }
    }
    
    func clearAll() {
        print("MessageCenter: Clearing all messages")
        DispatchQueue.main.async {
            self.message = nil
            self.alertMessage = nil
            self.errorMessage = nil
        }
    }
    
    func displayMessage(for message: String, delay seconds: Double? = nil) {
        DispatchQueue.main.async {
            self.message = message
            if let seconds = seconds {
                self.autoDismissMessage(after: seconds)
            }
        }
    }
    
    private func autoDismissMessage(after seconds: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.message = nil
        }
    }
}
