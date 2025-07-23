import Foundation
import ARKit
import ShazamKit
import WeatherKit

/**
        This protcol defines the coarse structure of the execution units for particular information retrieval tasks.
 */
protocol WorkflowHandler {
    var nextWorkflowHandler: WorkflowHandler? { get set }
    var description: String { get set }
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void)
    func getHandlerCount() -> Int
}

extension WorkflowHandler {
    func getHandlerCount() -> Int {
        return 1
    }
}

enum WorkflowResult {
    case success(Any)
    case failure(String)
}

extension WorkflowResult {
    var image: UIImage? {
        if case .success(let data) = self, let img = data as? UIImage {
            return img
        }
        return nil
    }
    
    var saleItems: [SaleItem]? {
        if case .success(let data) = self, let items = data as? [SaleItem] {
            return items
        }
        return nil
    }
    
    var text: String? {
        if case .success(let data) = self, let text = data as? String {
            return text
        }
        return nil
    }

    var error: String? {
        if case .failure(let msg) = self {
            return msg
        }
        return nil
    }
    
    var detailedText: [String]? {
        if case .success(let data) = self, let detailedText = data as? [String] {
            return detailedText
        }
        return nil
    }
    
    var url: URL? {
        if case .success(let string) = self, let url = string as? URL {
            return url
        }
        return nil
    }
    
    var coordinates: CLLocationCoordinate2D? {
        if case .success(let any) = self, let coordinates = any as? CLLocationCoordinate2D {
            return coordinates
        }
        return nil
    }
    
    var location: Location? {
        if case .success(let any) = self, let location = any as? Location {
            return location
        }
        return nil
    }
    
    var googleLensObject: GoogleLensObject? {
        if case .success(let any) = self, let googleLensObject = any as? GoogleLensObject {
            return googleLensObject
        }
        return nil
    }
    
    var matchedMusic: SHMatchedMediaItem? {
        if case .success(let any) = self, let matchedMusic = any as? SHMatchedMediaItem {
            return matchedMusic
        }
        return nil
    }
    
    var forecast: Weather? {
        if case .success(let any) = self, let forecast = any as? Weather {
            return forecast
        }
        return nil
    }
    
    var webObject: WebObject? {
        if case .success(let any) = self, let webObject = any as? WebObject {
            return webObject
        }
        return nil
    }
    
    var dateObject: DateObject? {
        if case .success(let any) = self, let dateObject = any as? DateObject {
            return dateObject
        }
        return nil
    }
}

struct Location {
    let coordinates: CLLocationCoordinate2D
    let adress: String
    let city: String
}
