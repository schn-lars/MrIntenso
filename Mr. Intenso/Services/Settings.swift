import Foundation
import SwiftUICore
import Reachability

// https://medium.com/@w.raviraj/mastering-generics-in-swift-advanced-concepts-and-examples-85d5cfe11dca

/**
 
        This class is an observable wrapper which allows us to listen for changes for particular values.
        Make sure, that every variable within UserDefaultsKeys is present here.
 
 */

class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var autoDownload: Bool {
        didSet {
            UserDefaults.standard.set(autoDownload, forKey: UserDefaultsKeys.AUTO_DOWNLOAD.rawValue)
        }
    }
    
    @Published var useReverseSearch: Bool {
        didSet {
            UserDefaults.standard.set(useReverseSearch, forKey: UserDefaultsKeys.REVERSE_SEARCH.rawValue)
        }
    }
    
    @Published var language: String {
        didSet {
            UserDefaults.standard.set(language, forKey: UserDefaultsKeys.LANGUAGE.rawValue)
        }
    }
    
    @Published var iou: Float {
        didSet {
            UserDefaults.standard.set(iou, forKey: UserDefaultsKeys.IOU_THRESHOLD.rawValue)
        }
    }
    
    @Published var segmentation: Float {
        didSet {
            UserDefaults.standard.set(segmentation, forKey: UserDefaultsKeys.SEGMENTATION_THRESHOLD.rawValue)
        }
    }
    
    @Published var joke: String {
        didSet {
            UserDefaults.standard.set(joke, forKey: UserDefaultsKeys.JOKE.rawValue)
        }
    }
    
    @Published var commitHash: String {
        didSet {
            UserDefaults.standard.set(commitHash, forKey: "commitHash")
        }
    }
    
    @Published var apiKey: String?
    
    private func fetchApiKey() {
        let reachability = try! Reachability()
        reachability.whenUnreachable = { _ in
            print("You do not have internet access.")
            return
        }

        guard let url = URL(string: "https://myurl.com/apikey") else {
            print("FetchChanges: URL is nil")
            return
        }
        
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
                    return
                }
                
                if let apiKey = jsonResponse?["apikey"] as? String {
                    DispatchQueue.main.async {
                        self.apiKey = apiKey
                        print("APIKEY initialized!")
                    }
                } else {
                    print("Unexpected response format")
                }
            } catch {
                print("Settings: JSON decoding error:", error)
            }
        }
        .resume()
    }
    
    var description: String {
        return "Settings: autoDownload=\(autoDownload), language=\(language), iou=\(iou), segmentation=\(segmentation), joke=\(joke)"
    }
    
    init() {
        autoDownload = UserDefaults.standard.getValue(for: .AUTO_DOWNLOAD) as! Bool
        language = UserDefaults.standard.getValue(for: .LANGUAGE) as! String
        iou = UserDefaults.standard.getValue(for: .IOU_THRESHOLD) as! Float
        segmentation = UserDefaults.standard.getValue(for: .SEGMENTATION_THRESHOLD) as! Float
        joke = UserDefaults.standard.getValue(for: .JOKE) as! String
        useReverseSearch = UserDefaults.standard.getValue(for: .REVERSE_SEARCH) as! Bool
        commitHash = UserDefaults.standard.getCommitHash()
        fetchApiKey()
        print(description)
    } 
}


// https://stackoverflow.com/questions/31203241/how-can-i-use-userdefaults-in-swift

// MARK: UserDefaults

/**
 
        This extension of the UserDefaults allows us to persistenly store the user's settings in a key-value manner.
        Doing this is significantly easier than using CoreData in order to store user's settings.
        The only thing we have to keep in mind though, is that we must not store confidential information in it.
 
 */

extension UserDefaults {
    func initializeDefaults() {
        UserDefaultsKeys.allCases.forEach {
            if object(forKey: $0.rawValue) == nil {
                _ = getValue(for: $0)
            } else {
                print("Already initialized \($0.rawValue): \(getValue(for: $0))")
                return
            }
        }
        print("Commit-Hash: \(getCommitHash())")
    }
    
    func setNewValue(for key: UserDefaultsKeys, new value: Any) {
        switch key {
        case .AUTO_DOWNLOAD:
            setAutoDownload(value as! Bool)
        case .IOU_THRESHOLD:
            setIOUThreshold(value as! Float)
        case .SEGMENTATION_THRESHOLD:
            setSegmentationThreshold(value as! Float)
        case .LANGUAGE:
            setLanguage(value as! String)
        case .JOKE:
            setJokeSetting(value as! String)
        case .REVERSE_SEARCH:
            setReverseSearchSetting(value as! Bool)
        }
    }
    
    func getValue(for key: UserDefaultsKeys) -> Any {
        switch key {
        case .AUTO_DOWNLOAD:
            return getAutoDownload()
        case .IOU_THRESHOLD:
            return getIOUThreshold()
        case .SEGMENTATION_THRESHOLD:
            return getSegmentationThreshold()
        case .LANGUAGE:
            return getLanguage()
        case .JOKE:
            return getJokeSetting()
        case .REVERSE_SEARCH:
            return getReverseSearchSetting()
        }
    }
    
    func setLanguage(_ value: String) {
        set(value, forKey: UserDefaultsKeys.LANGUAGE.rawValue)
    }
    
    func getLanguage() -> String {
        guard let _ = string(forKey: UserDefaultsKeys.LANGUAGE.rawValue) else {
            setLanguage(Constants.LANGUAGE_DEFAULT)
            return Constants.LANGUAGE_DEFAULT
        }
        return string(forKey: UserDefaultsKeys.LANGUAGE.rawValue)!
    }
    
    func setCommitHash(_ value: String) {
        set(value, forKey: "commitHash")
    }
    
    func getCommitHash() -> String {
        guard let _ = string(forKey: "commitHash") else {
            setCommitHash("fdd0fb3e2bc1f2bd8e840fe598b88d01ef131443")
            return ""
        }
        return string(forKey: "commitHash")!
    }
    
    
    func setSegmentationThreshold(_ value: Float) {
        set(value, forKey: UserDefaultsKeys.SEGMENTATION_THRESHOLD.rawValue)
    }
    
    func getSegmentationThreshold() -> Float {
        guard let segment = UserDefaults.standard.object(forKey: UserDefaultsKeys.SEGMENTATION_THRESHOLD.rawValue) else {
            setSegmentationThreshold(Constants.SEGMENTATION_THRESHOLD_DEFAULT)
            return Constants.SEGMENTATION_THRESHOLD_DEFAULT
        }
        return segment as! Float
    }
    
    func setIOUThreshold(_ value: Float) {
        set(value, forKey: UserDefaultsKeys.IOU_THRESHOLD.rawValue)
    }
    
    func getIOUThreshold() -> Float {
        guard let iou = UserDefaults.standard.object(forKey: UserDefaultsKeys.IOU_THRESHOLD.rawValue) else {
            setIOUThreshold(Constants.IOU_THRESHOLD_DEFAULT)
            return Constants.IOU_THRESHOLD_DEFAULT
        }
        return iou as! Float
    }
    
    func setAutoDownload(_ value: Bool) {
        set(value, forKey: UserDefaultsKeys.AUTO_DOWNLOAD.rawValue)
    }
    
    func getAutoDownload() -> Bool {
        guard let download = UserDefaults.standard.object(forKey: UserDefaultsKeys.AUTO_DOWNLOAD.rawValue) else {
            setAutoDownload(Constants.AUTO_SAVE_DEFAULT)
            return Constants.AUTO_SAVE_DEFAULT
        }
        return download as! Bool
    }
    
    func setJokeSetting(_ value: String) {
        set(value, forKey: UserDefaultsKeys.JOKE.rawValue)
    }
    
    func getJokeSetting() -> String {
        guard let joke = UserDefaults.standard.object(forKey: UserDefaultsKeys.JOKE.rawValue) else {
            setJokeSetting(Constants.JOKE_DEFAULT)
            return Constants.JOKE_DEFAULT
        }
        return joke as! String
    }
    
    func setReverseSearchSetting(_ value: Bool) {
        set(value, forKey: UserDefaultsKeys.REVERSE_SEARCH.rawValue)
    }
    
    func getReverseSearchSetting() -> Bool {
        guard let reverseSearch = UserDefaults.standard.object(forKey: UserDefaultsKeys.REVERSE_SEARCH.rawValue) else {
            setReverseSearchSetting(true)
            return true
        }
        return reverseSearch as! Bool
    }
}

/**
 
        Those are all variables which the user is able to change,
        as well as the String indicating the Title which is shown in the UI.
 
 */

// https://stackoverflow.com/questions/24061584/looping-through-enum-values-in-swift
enum UserDefaultsKeys: String, CaseIterable {
    case SEGMENTATION_THRESHOLD = "Segmentation-Threshold"
    case IOU_THRESHOLD = "IOU-Threadhold"
    case AUTO_DOWNLOAD = "Auto Download"
    case LANGUAGE = "Language"
    case JOKE = "Joke Setting"
    case REVERSE_SEARCH = "Reverse Search"
}
