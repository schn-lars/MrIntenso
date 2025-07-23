import Foundation
import SwiftUI
import CoreLocation
import MapKit
import DHash
import ShazamKit
import WeatherKit

/**
 
    This file contains all definitions of all possible description types as well as the overall declaration of how an ObjectInformation looks like.
    Some further definitions and explanations are given in the ObjectDescriptionBase-protocol.
 
 */

class ObjectInformation: Comparable, ObservableObject, Identifiable, Hashable {
    
    init() {}
    
    init(objectInformation: ObjectInformation) {
        self.object = objectInformation.object
        self.coordinates = objectInformation.coordinates
        self.image = objectInformation.image
        self.lastSpotted = Int64(NSDate().timeIntervalSince1970)
        self.confidence = objectInformation.confidence
    }
    
    static func < (lhs: ObjectInformation, rhs: ObjectInformation) -> Bool {
        // Favourite objects should come first
        if lhs.favourite != rhs.favourite {
            return !lhs.favourite
        }
        // Both are or are not favourized, then sort by lastSpotted
        return lhs.lastSpotted < rhs.lastSpotted
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /**
            I consider objects to be equal if they are being labeled the same and are within close proximity of each other.
            Keep in mind, that we rather want to redo InformationRetrieval than fetching it from there. We will most likely encounter situations where
            objects are getting out of scope of the camera more frequently rather objects being moved deliberately just to fuck with the program.
            Then we will just see them as seperate objects.
     
                TODO : Consider adding method which drops duplicates. Then we might want to compare images and certainly not location.
     */
    static func == (lhs: ObjectInformation, rhs: ObjectInformation) -> Bool {
        let distance = CLLocation(latitude: lhs.coordinates.latitude, longitude: lhs.coordinates.longitude)
            .distance(from: CLLocation(latitude: rhs.coordinates.latitude, longitude: rhs.coordinates.longitude))
        // TODO if following statement is wrong, we can add similarity check between the retrieved images of the segmentation
        if let image1 = lhs.image, let image2 = rhs.image {
            let similarImages = (image1).seemsSimilarTo(image2) // default threshold is 5 bits
            return (lhs.object == rhs.object) && (distance < Constants.LOCATION_THRESHOLD) && similarImages
        } else {
            return (lhs.object == rhs.object) && (distance < Constants.LOCATION_THRESHOLD)
        }
    }
    
    var id: UUID = UUID()
    @Published var object: String = ""
    @Published var confidence: Float = 0.0
    @Published var coordinates: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: CLLocationDegrees(), longitude: CLLocationDegrees())
    @Published var lastSpotted: Int64 = Int64(NSDate().timeIntervalSince1970)
    @Published var image: UIImage? = nil
    @Published var favourite: Bool = false
    @Published var shared: Bool = false
    @Published var detailedDescription: [any ObjectDescriptionBase] = []
    @Published var handlerCount: Int? = nil
    @Published var processedHandlers: Int = 0
    @Published var inCache: Bool = false
    
    var description: String {
        return "ObjectInformation(object: \(object), favourite: \(favourite), lastSpotted: \(lastSpotted))"
    }
    
    var sharePayload: [String: Any]? {
        guard let imageData = image?.jpegData(compressionQuality: 0.3) else { return nil }
        let imageBase64 = imageData.base64EncodedString()

        let itemsPayload: [String: [String: Any]] = detailExport

        let jsonObject: [String: Any] = [
            "id": id.uuidString,
            "object": object,
            "confidence": confidence,
            "lat": coordinates.latitude,
            "lon": coordinates.longitude,
            "lastSpotted": lastSpotted,
            "img": imageBase64,
            "items": itemsPayload
        ]

        guard JSONSerialization.isValidJSONObject(jsonObject) else {
            print("Invalid JSON:", jsonObject)
            return nil
        }

        return jsonObject
    }
    
    var detailExport: [String : [String: Any]] {
        var result: [String : [String: Any]] = [:]
        for item in detailedDescription {
            print("Serializing: \(item.type)")
            guard let itemDict = item.toDictionary() else {
                print("Skipping serialization of \(item.title)")
                continue
            }
            let key = "\(item.type)|\(item.title)"
            result[key] = itemDict
        }
        
        return result
    }
    
    static func fromJSON(_ json: [String: Any]) -> ObjectInformation? {
        guard let object = json["object"] as? String,
              let confidence = json["confidence"] as? Float,
              let lat = json["lat"] as? Double,
              let lon = json["lon"] as? Double,
              let lastSpotted = json["lastSpotted"] as? Int64,
              let imgBase64 = json["img"] as? String,
              let imageData = Data(base64Encoded: imgBase64),
              let image = UIImage(data: imageData) else {
            print("Required fields missing or invalid")
            return nil
        }

        let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let obj = ObjectInformation(object: object, confidence: confidence, coordinates: coordinates, lastSpotted: lastSpotted, shared: true, image: image)

        // Parse items
        if let itemsContainer = json["items"] as? [String: [String: Any]] {
            for (key, dict) in itemsContainer {
                let titleType = key.split(separator: "|")
                switch titleType.first {
                case "image":
                    if let imageObj = ImageObject.fromDictionary(dict) {
                        obj.detailedDescription.append(imageObj)
                    }
                case "location":
                    if let loc = LocationObject.fromDictionary(dict) {
                        obj.detailedDescription.append(loc)
                    }
                case "specification":
                    if let spec = SpecificationObject.fromDictionary(dict) {
                        obj.detailedDescription.append(spec)
                    }
                case "web":
                    if let webObject = WebObject.fromDictionary(dict) {
                        obj.detailedDescription.append(webObject)
                     }
                case "destination":
                    if let destination = NavigationObject.fromDictionary(dict) {
                        obj.detailedDescription.append(destination)
                    }
                case "shopping":
                    if var shopping = ShoppingObject.fromDictionary(dict) {
                        shopping.type = obj.object
                        obj.detailedDescription.append(shopping)
                    }
                case "shazam":
                    if let shazam = ShazamObject.fromDictionary(dict) {
                        obj.detailedDescription.append(shazam)
                    }
                case "visual":
                    if let visual = GoogleLensObject.fromDictionary(dict) {
                        obj.detailedDescription.append(visual)
                    }
                case "date":
                    if let date = DateObject.fromDictionary(dict) {
                        obj.detailedDescription.append(date)
                    }
                default:
                    print("Unknown item key: \(key)")
                }
            }
        }
        return obj
    }
    
    init(object name: String, confidence: Float, croppedImage image: UIImage, location: CLLocation? = nil) {
        print("Initializing ObjectInformation... with location? :\(location != nil)")
        self.object = name
        self.confidence = confidence
        self.image = image
        if let location = location {
            self.coordinates = location.coordinate
        }
    }
    
    init(id: UUID, object: String, confidence: Float, coordinates: CLLocationCoordinate2D, lastSpotted: Int64, favorite: Bool, inCache: Bool, shared: Bool, image: UIImage) {
        self.id = id
        self.object = object
        self.confidence = confidence
        self.coordinates = coordinates
        self.lastSpotted = lastSpotted
        self.favourite = favorite
        self.inCache = inCache
        self.shared = shared
        self.image = image
    }
    
    init(object: String, confidence: Float, coordinates: CLLocationCoordinate2D, lastSpotted: Int64, favorite: Bool, inCache: Bool, image: UIImage) {
        self.id = UUID()
        self.object = object
        self.confidence = confidence
        self.coordinates = coordinates
        self.lastSpotted = lastSpotted
        self.favourite = favorite
        self.inCache = inCache
        self.image = image
    }
    
    init(object: String, confidence: Float, coordinates: CLLocationCoordinate2D, lastSpotted: Int64, shared: Bool, image: UIImage) {
        self.id = UUID()
        self.object = object
        self.confidence = confidence
        self.coordinates = coordinates
        self.lastSpotted = lastSpotted
        self.shared = shared
        self.image = image
    }
    
    func addObjectDescription(new object: any ObjectDescriptionBase, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.detailedDescription.append(object)
            print("addObjectDescription: \(self.getDetailedDescription())")
            completion()
        }
    }
    
    func isTheSameObject(_ other: ObjectInformation) -> Bool {
        if self.object != other.object { return false }
        let distance = CLLocation(latitude: self.coordinates.latitude, longitude: self.coordinates.longitude)
            .distance(from: CLLocation(latitude: other.coordinates.latitude, longitude: other.coordinates.longitude))
        
        if distance >= Constants.LOCATION_THRESHOLD { return false }
        if let image1 = self.image, let image2 = other.image {
            if !(image1).seemsSimilarTo(image2, treshold: 1) { return false }
        }
        
        
        // TODO: Check whether detailedDescription is the same. For this we need ObjectBase to be Equatable
        var unmatched = other.detailedDescription
        for info in self.detailedDescription {
            if let index = unmatched.firstIndex(where: { otherInfo in
                type(of: info) == type(of: otherInfo) && info.isEqual(to: otherInfo)
            }) {
                unmatched.remove(at: index)
            } else {
                print("No match found for: \(info.title)")
                return false
            }
        }

        return unmatched.isEmpty
    }
    
    private func getDetailedDescription() -> String {
        return detailedDescription.map { $0.title }.joined(separator: ", ")
    }
    
    func incrementProcessedCounter() {
        self.processedHandlers += 1
    }
    
    func setFavorite() {
        self.favourite = !self.favourite
    }
}

/**
    This protocol is defined for objects which we do not want to save in persistent memory. (Dynamic types)
 */
protocol Skipable {}

/**
    This protocol makes sure, that these objects are not shown in the resulting details view.
 */
protocol Invisible {}

/**
    This protocol is needed as we are returning this type as a base in our workflow.
 */
protocol ObjectDescriptionBase: Identifiable, Comparable {
    var id: UUID { get set }
    var title: String { get set } // this is the string being displayed in the navigation
    var description: String? { get set }
    var errorMessage: String? { get set }
    var type: String { get set }
    
    func render() -> AnyView
    func isEqual(to other: any ObjectDescriptionBase) -> Bool
    func toDictionary() -> [String: Any]? // unless it is not shareable, it returns a JSON-like dictionary
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? // same here, unless its shareable, it will return the matching instance
}

// TODO: remove placeholder sometime
struct PlaceholderObject: ObjectDescriptionBase, Skipable {
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        return nil
    }
    
    func toDictionary() -> [String : Any]? {
        return nil
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        guard let other = other as? PlaceholderObject else { return false }
        return self.title == other.title
    }
    
    static func < (lhs: PlaceholderObject, rhs: PlaceholderObject) -> Bool {
        return lhs.title < rhs.title
    }
    
    var id: UUID = UUID()
    var title: String = "Placeholder"
    var description: String? = nil
    var errorMessage: String? = nil
    var type = "placeholder"
    
    func render() -> AnyView {
        AnyView(
            Text("")
                .foregroundColor(Color.black)
                .font(.system(size: 14))
        )
    }
}

/**
    This object is used to more specialize the retrieved object's class. It can be used to render some sort of specialized description.
 */
struct SpecificationObject: ObjectDescriptionBase {
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        guard let title = dict["title"] as? String,
              let specification = dict["spec"] as? String,
              let description = dict["desc"] as? String else {
            print("Specification from Dictionary failed")
            return nil
        }
        return SpecificationObject(title: title, specification: specification, description: description)
    }
    
    func toDictionary() -> [String : Any]? {
        if let specification = specification,
            let description = description {
            return [
                "title": title,
                "spec": specification,
                "desc": description
            ]
        }
        return nil
        
    }
    
    static func < (lhs: SpecificationObject, rhs: SpecificationObject) -> Bool {
        return false
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        guard let other = other as? SpecificationObject else { return false }
        if self.title != other.title { return false }
        if self.title == "Conversation-Starter" { return true }
        if self.specification != other.specification { return false }
        if self.description != other.description { return false }
        return true
    }
    
    func render() -> AnyView {
        AnyView(
            VStack {
                if errorMessage != nil {
                    Text(errorMessage!)
                        .foregroundColor(Color.black)
                        .font(.system(size: 14))
                } else {
                    Text(description!)
                        .foregroundColor(Color.black)
                        .font(.system(size: 14))
                }
            }
        )
    }
    
    var id: UUID = UUID()
    var title: String
    var errorMessage: String?
    var specification: String?
    var description: String?
    var type = "specification"
    
    init(title: String, specification: String, description: String? = nil) {
        self.title = title
        self.specification = specification
        self.description = description
    }
    
    init (title: String, errorMessage: String?) {
        self.title = title
        self.errorMessage = errorMessage
    }
    
    init(title: String, description: String) {
        self.specification = nil
        self.title = title
        self.description = description
    }
}

struct ImageObject: ObjectDescriptionBase {
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        guard let base64String = dict["img"] as? String,
              let imageData = Data(base64Encoded: base64String),
              let image = UIImage(data: imageData) ,
              let title = dict["title"] as? String
            else {
            print("ImageObject.fromDictionary has failed.")
            return nil
        }
        return ImageObject(title: title, image: image)
    }
    
    func toDictionary() -> [String : Any]? {
        if let image = image?.jpegData(compressionQuality: 0.3) {
            return [
                "title": title,
                "img": image
            ]
        }
        return nil
    }
    
    static func < (lhs: ImageObject, rhs: ImageObject) -> Bool {
        return lhs.title < rhs.title
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        guard let other = other as? ImageObject else { return false }
        if self.title != other.title { return false }
        if !(self.image!).seemsSimilarTo(other.image!, treshold: 1) { return false }
        if self.description != other.description { return false }
        if self.errorMessage != other.errorMessage { return false }
        return true
    }
    
    func render() -> AnyView {
        AnyView(
            VStack(spacing: 5) {
                if errorMessage != nil {
                    Text(errorMessage!)
                        .foregroundColor(Color.black)
                        .font(.system(size: 14))
                } else {
                    if description != nil {
                        Text(description!)
                            .font(.system(size: 14))
                            .foregroundColor(Color.black)
                    }
                    Image(uiImage: image!)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        )
    }
    
    var id: UUID = UUID()
    var title: String
    var errorMessage: String?
    var description: String?
    var image: UIImage?
    var type = "image"
    
    init(title: String, image: UIImage, description: String? = nil) {
        self.image = image
        self.description = description
        self.title = title
    }
    
    init(title: String, errorMessage: String, description: String? = nil) {
        self.title = title
        self.errorMessage = errorMessage
        self.description = description
    }
}

/**
 
    This struct is basically a container for a given URL. It is used to display content from external sources.
 
 */
struct WebObject: ObjectDescriptionBase {
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        guard let title = dict["title"] as? String,
              let stringUrl = dict["url"] as? String,
              let url = URL(string: stringUrl)
            else {
                print("WebObject fromDictionary has failed.")
                return nil
        }
        return WebObject(title: title, url: url)
    }
    
    func toDictionary() -> [String : Any]? {
        if let url = url {
            return [
                "url" : url.absoluteString,
                "title" : title
            ]
        }
        return nil
    }
    
    static func < (lhs: WebObject, rhs: WebObject) -> Bool {
        return false
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        guard let other = other as? WebObject else { return false }
        if self.title != other.title { return false }
        if self.url != other.url { return false }
        if self.description != other.description { return false }
        if self.errorMessage != other.errorMessage { return false }
        return true
    }
    
    var id: UUID = UUID()
    var title: String
    var url: URL?
    var description: String?
    var errorMessage: String?
    var type = "web"
    
    func render() -> AnyView {
        AnyView(WebObjectView(url: url, errorMessage: errorMessage))
    }
    
    init(title: String, url: URL, description: String? = nil) {
        self.title = title
        self.url = url
        self.description = description
    }
    
    init(title: String, errorMessage: String) {
        self.title = title
        self.errorMessage = errorMessage
        self.description = nil
    }
}

struct MapObject: ObjectDescriptionBase, Skipable {
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        return nil
    }
    
    func toDictionary() -> [String : Any]? {
        return nil
    }
    
    static func < (lhs: MapObject, rhs: MapObject) -> Bool {
        return false
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        // This object does not matter at all, as it is being computed everytime. It could lead to unexpected bahavior if implemented differently.
        guard let _ = other as? MapObject else { return false }
        return true
    }
    
    var id: UUID = UUID()
    
    var title: String
    
    var type = "map"
    
    var description: String?
    
    var errorMessage: String?
    
    func render() -> AnyView {
        // here comes the map with annntations and stuff.
        AnyView(
            ObjectMapViewContainer(similarObjects: similarObjects ?? [])
        )
    }
    
    var similarObjects: [ObjectInformation]? = nil
    
    init(
        title: String,
        similarObjects: [ObjectInformation]
    ) {
        self.title = title
        self.similarObjects = similarObjects
    }
}

struct LocationObject: ObjectDescriptionBase {
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        guard let lon = dict["lon"] as? Double,
              let lat = dict["lat"] as? Double,
              let city = dict["city"] as? String,
              let adress = dict["address"] as? String
        else {
            print("LocationObject fromDictionary has failed.")
            return nil
        }
        return LocationObject(location: Location(
            coordinates: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            adress: adress,
            city: city)
        )
    }
    
    func toDictionary() -> [String : Any]? {
        return [
            "lon" : location.coordinates.longitude,
            "lat" : location.coordinates.latitude,
            "city": location.city,
            "address": location.adress
        ]
    }
    
    var id: UUID = UUID()
    var title: String = TranslationUnit.getMessage(for: .LOCATION_TITLE) ?? "Location"
    var description: String?
    var errorMessage: String?
    var type: String = "location"
    var location: Location
    
    func render() -> AnyView {
        AnyView(
            LocationMapViewContainer(location: location)
        )
    }
    
    init(location: Location) {
        self.location = location
    }
    
    init(title: String, errorMessage: String) {
        self.title = title
        self.errorMessage = errorMessage
        self.location = Location(coordinates: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), adress: "", city: "")
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        guard let other = other as? LocationObject else { return false }
        return self.location.coordinates.latitude == other.location.coordinates.latitude && self.location.coordinates.longitude == other.location.coordinates.longitude
    }
    
    static func < (lhs: LocationObject, rhs: LocationObject) -> Bool {
        return false
    }
    
    static func == (lhs: LocationObject, rhs: LocationObject) -> Bool {
        return lhs.location.coordinates.latitude == rhs.location.coordinates.latitude && lhs.location.coordinates.longitude == rhs.location.coordinates.longitude
    }
}

struct NavigationObject: ObjectDescriptionBase {
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        guard let lon = dict["lon"] as? Double,
              let lat = dict["lat"] as? Double,
              let city = dict["city"] as? String,
              let adress = dict["address"] as? String
        else {
            print("NavigationObject fromDictionary has failed.")
            return nil
        }
        return NavigationObject(destination: Location(
            coordinates: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            adress: adress,
            city: city)
        )
    }
    
    func toDictionary() -> [String : Any]? {
        return [
            "lon" : destination.coordinates.longitude,
            "lat" : destination.coordinates.latitude,
            "city": destination.city,
            "address": destination.adress
        ]
    }
    
    var id: UUID = UUID()
    var title: String =  TranslationUnit.getMessage(for: .NAVIGATION_TITLE) ?? "Destination"
    var description: String?
    var errorMessage: String?
    var type: String = "destination"
    var destination: Location
    
    func render() -> AnyView {
        AnyView(
            NavigationMapViewContainer(destination: destination)
        )
    }
    
    init(destination: Location, description: String? = nil) {
        self.destination = destination
        self.description = description
        self.errorMessage = nil
    }
    
    init(title: String, errorMessage: String) {
        self.title = title
        self.errorMessage = errorMessage
        self.destination = Location(coordinates: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), adress: "", city: "")
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        guard let other = other as? NavigationObject else { return false }
        return self.destination.coordinates.latitude == other.destination.coordinates.latitude && self.destination.coordinates.longitude == other.destination.coordinates.longitude
    }
    
    static func < (lhs: NavigationObject, rhs: NavigationObject) -> Bool {
        return false
    }
    
    static func == (lhs: NavigationObject, rhs: NavigationObject) -> Bool {
        return lhs.destination.coordinates.latitude == rhs.destination.coordinates.latitude && lhs.destination.coordinates.longitude == rhs.destination.coordinates.longitude
    }
}

struct ShoppingObject: ObjectDescriptionBase {
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        guard let saleItems = dict["saleItems"] as? [[String: Any]] else {
            print("ShoppingObject: Could not convert from dictionary due to structure.")
            return nil
        }
        
        var newSaleItems: [SaleItem] = []
        for item in saleItems {
            if let thumbnail = item["thumbnail"] as? String,
               let link = item["link"] as? String,
               let price = item["price"] as? Double,
               let currency = item["currency"] as? String,
               let title = item["title"] as? String,
               let itemType = item["itemType"] as? String,
               let timestamp = item["timestamp"] as? Int64,
               let source = item["source"] as? String,
               let sourceIcon = item["sourceIcon"] as? String,
               let ratingValue = item["rating"] as? Double,
               let reviews = item["reviews"] as? Int
            {
                let inStock = item["inStock"] as? Bool
                let sourceIconLink = URL(string: sourceIcon)
                let saleItem = SaleItem(
                    thumbnail: thumbnail,
                    link: link,
                    price: price,
                    currency: currency,
                    title: title,
                    itemType: itemType,
                    timestamp: timestamp,
                    selected: false,
                    source: source,
                    sourceIcon: sourceIconLink,
                    inStock: inStock,
                    rating: ratingValue,
                    reviews: reviews
                )
                newSaleItems.append(saleItem)
            }
        }
        if newSaleItems.isEmpty {
            return nil
        } else {
            return ShoppingObject(saleItems: newSaleItems)
        }
    }
    
    func toDictionary() -> [String : Any]? {
        if saleItems.isEmpty {
            print("ShoppingObject: toDictionary invalid as we dont have sale items.")
            return nil
        }
        
        var saleItemsDict: [[String: Any]] = []
        for item in saleItems {
            var saleItemDict: [String: Any] = [
                "thumbnail" : item.thumbnail,
                "link" : item.link,
                "price": item.price,
                "currency" : item.currency,
                "title": item.title,
                "itemType": item.itemType,
                "timestamp": item.timestamp,
                "source": item.source,
                "sourceIcon": item.sourceIcon?.absoluteString ?? "",
                "rating": item.rating ?? -1.0,
                "reviews": item.reviews ?? -1
            ]
            if let inStock = item.inStock {
                saleItemDict.updateValue(inStock, forKey: "inStock")
            }
            saleItemsDict.append(saleItemDict)
        }
        return ["saleItems" : saleItemsDict]
    }
    
    var id: UUID = UUID()
    var title: String = "Shopping"
    var description: String?
    var errorMessage: String?
    var type: String = "shopping"
    var saleItems: [SaleItem] = []
    
    func render() -> AnyView {
        AnyView(
            ShoppingView(shoppingItems: saleItems)
        )
    }
    
    init(description: String? = nil, errorMessage: String? = nil, saleItems: [SaleItem]) {
        self.description = description
        self.errorMessage = errorMessage
        self.saleItems = saleItems
    }
    
    init(id: UUID, title: String, description: String? = nil, errorMessage: String? = nil, type: String, saleItems: [SaleItem]) {
        self.id = id
        self.title = title
        self.description = description
        self.errorMessage = errorMessage
        self.type = type
        self.saleItems = saleItems
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        return false
    }
    
    static func < (lhs: ShoppingObject, rhs: ShoppingObject) -> Bool {
        return false
    }
    
    static func == (lhs: ShoppingObject, rhs: ShoppingObject) -> Bool {
        return lhs.id == rhs.id
    }
}

struct BasketObject: ObjectDescriptionBase, Skipable {
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        return nil
    }
    
    func toDictionary() -> [String : Any]? {
        return nil
    }
    
    var id: UUID = UUID()
    var title = TranslationUnit.getMessage(for: .BASKET_TITLE) ?? "Shopping Basket"
    var description: String?
    var errorMessage: String?
    var type: String = "comparison"
    let object: String
    
    func render() -> AnyView {
        AnyView(
            BasketComparisonView(object: object)
        )
    }
    
    init(object: String, description: String? = nil, errorMessage: String? = nil) {
        self.description = description
        self.errorMessage = errorMessage
        self.object = object
    }
    
    init(id: UUID, title: String, description: String? = nil, errorMessage: String? = nil, type: String, object: String) {
        self.id = id
        self.title = title
        self.description = description
        self.errorMessage = errorMessage
        self.type = type
        self.object = object
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        return false
    }
    
    static func < (lhs: BasketObject, rhs: BasketObject) -> Bool {
        return false
    }
    
    static func == (lhs: BasketObject, rhs: BasketObject) -> Bool {
        return lhs.id == rhs.id
    }
}

struct QRCodeObject: ObjectDescriptionBase, Skipable {
    var id: UUID = UUID()
    var title: String = "Share"
    var description: String?
    var errorMessage: String?
    var type: String = "share"
    
    let objectInformation: ObjectInformation
    
    func render() -> AnyView {
        AnyView(
            QRCodePresenterView(objectInformation: objectInformation)
        )
    }
    
    init(objectInformation: ObjectInformation   ) {
        self.objectInformation = objectInformation
        self.errorMessage = nil
        self.description = nil
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        return false
    }
    
    func toDictionary() -> [String : Any]? {
        return nil
    }
    
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        return nil
    }
    
    static func < (lhs: QRCodeObject, rhs: QRCodeObject) -> Bool {
        return false
    }
}

struct GoogleLensObject: ObjectDescriptionBase, Skipable {
    var id: UUID = UUID()
    var title: String = "Visual"
    var description: String? = nil
    var errorMessage: String? = nil
    var type: String = "visual"
    
    var visualMatches: [VisualMatch] = []
    var relatedItems: [RelatedItem] = []
    var objectType: String = ""
    var productsToken: String
    
    func render() -> AnyView {
        AnyView(
            GoogleLensResultView(
                relatedContent: relatedItems,
                visualMatches: visualMatches
            )
        )
    }
    
    init(title: String, productsToken: String, description: String? = nil, visualMatches: [VisualMatch], relatedItems: [RelatedItem]) {
        self.title = title
        self.description = description
        self.visualMatches = visualMatches
        self.relatedItems = relatedItems
        self.errorMessage = nil
        self.productsToken = productsToken
    }
    
    init(productsToken: String) {
        self.productsToken = productsToken
    }
    
    mutating func setObjectType(_ objectType: String) {
        self.objectType = objectType
    }
    
    mutating func addRelatedItem(_ item: RelatedItem) {
        self.relatedItems.append(item)
    }
    
    mutating func addVisualMatch(_ item: VisualMatch) {
        self.visualMatches.append(item)
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        return false
    }
    
    static func == (lhs: GoogleLensObject, rhs: GoogleLensObject) -> Bool {
        return lhs.id == rhs.id
    }
    
    func toDictionary() -> [String : Any]? {
        var result: [String : Any] = [:]
        if !visualMatches.isEmpty {
            var visuals: [[String: Any]] = []
            for visual in visualMatches {
                var baseVisual: [String : Any] = [
                    "title" : visual.title,
                    "link" : visual.link.absoluteString,
                    "source" : visual.source,
                    "sourceIcon": visual.sourceIcon.absoluteString,
                    "thumbnail": visual.thumbnail.absoluteString,
                    "image": visual.image.absoluteString,
                    "inStock" : visual.inStock ?? "",
                    "condition" : visual.condition ?? "",
                    "rating" : visual.rating ?? -1.0,
                    "reviews" : visual.reviews ?? -1
                ]
                
                if let saleItem = visual.saleItem {
                    var saleItemDict: [String : Any] = [
                        "thumbnail" : saleItem.thumbnail,
                        "link" : saleItem.link,
                        "price" : saleItem.price,
                        "currency" : saleItem.currency,
                        "title" : saleItem.title,
                        "itemType" : saleItem.itemType,
                        "timestamp" : saleItem.timestamp,
                        "source": saleItem.source,
                        "sourceIcon": saleItem.sourceIcon?.absoluteString ?? "",
                        "rating": saleItem.rating ?? -1.0,
                        "reviews": saleItem.reviews ?? -1,
                        "condition": saleItem.condition ?? ""
                    ]
                    if let inStock = saleItem.inStock {
                        saleItemDict.updateValue(inStock, forKey: "inStock")
                    }
                    print("GoogleLensObject: toDictionary\(saleItemDict)")
                    baseVisual.updateValue(saleItemDict, forKey: "saleItem")
                }
                visuals.append(baseVisual)
            }
            if !visuals.isEmpty {
                result.updateValue(visuals, forKey: "visualMatches")
            }
        }

        if !relatedItems.isEmpty {
            var relatedItemsDict: [[String: Any]] = []
            for relatedItem in relatedItems {
                let relatedDict: [String : Any] = [
                    "title" : relatedItem.title,
                    "link" : relatedItem.link.absoluteString,
                    "thumbnail" : relatedItem.thumbnail.absoluteString
                ]
                relatedItemsDict.append(relatedDict)
            }
            
            if !relatedItemsDict.isEmpty {
                result.updateValue(relatedItemsDict, forKey: "relatedItems")
            }
        }
        result.updateValue(productsToken, forKey: "productsToken")
        return result.isEmpty ? nil : result
    }
    
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        guard let productsToken = dict["productsToken"] as? String else {
            return nil
        }
        
        var visuals: [VisualMatch] = []
        if let visualMatches = dict["visualMatches"] as? [[String:Any]] {
            for visualMatch in visualMatches {
                if let visualTitle = visualMatch["title"] as? String,
                   let visualLinkString = visualMatch["link"] as? String,
                   let visualLink = URL(string: visualLinkString),
                   let source = visualMatch["source"] as? String,
                   let sourceIcon = visualMatch["sourceIcon"] as? String,
                   let sourceIconLink = URL(string: sourceIcon),
                   let thumbnail = visualMatch["thumbnail"] as? String,
                   let thumbnailLink = URL(string: thumbnail),
                   let image = visualMatch["image"] as? String,
                   let imageLink = URL(string: image)
                {
                    let inStock = visualMatch["inStock"] as? Bool ?? nil
                    let rawCondition = visualMatch["condition"] as? String
                    let condition = (rawCondition?.isEmpty == true) ? nil : rawCondition
                    let rating = visualMatch["rating"] as? Double ?? -1.0
                    let reviews = visualMatch["reviews"] as? Int ?? -1
                    
                    if let saleItem = visualMatch["saleItem"] as? [String : Any],
                       let thumbnail = saleItem["thumbnail"] as? String,
                       let link = saleItem["link"] as? String,
                       let price = saleItem["price"] as? Double,
                       let currency = saleItem["currency"] as? String,
                       let title = saleItem["title"] as? String,
                       let itemType = saleItem["itemType"] as? String,
                       let timestamp = saleItem["timestamp"] as? Int64 {
                        let saleSource = saleItem["source"] as? String ?? ""
                        let saleSourceIcon = saleItem["sourceIcon"] as? String ?? ""
                        let saleSourceIconLink = URL(string: saleSourceIcon)
                        let saleCondition = saleItem["condition"] as? String ?? ""
                        let saleReviews = saleItem["reviews"] as? Int ?? -1
                        let saleRating = saleItem["rating"] as? Double ?? -1.0
                        let inStock = saleItem["inStock"] as? Bool ?? nil
                        visuals.append(
                            VisualMatch(
                                title: visualTitle,
                                link: visualLink,
                                source: source,
                                sourceIcon: sourceIconLink,
                                thumbnail: thumbnailLink,
                                image: imageLink,
                                saleItem: SaleItem(
                                    thumbnail: thumbnail,
                                    link: link,
                                    price: price,
                                    currency: currency,
                                    title: title,
                                    itemType: itemType,
                                    timestamp: timestamp,
                                    selected: false,
                                    source: saleSource,
                                    sourceIcon: saleSourceIconLink,
                                    inStock: inStock,
                                    condition: saleCondition,
                                    rating: saleRating,
                                    reviews: saleReviews
                                ),
                                inStock: inStock,
                                condition: condition,
                                rating: rating,
                                reviews: reviews
                            )
                        )
                    } else {
                        visuals.append(
                            VisualMatch(
                                title: visualTitle,
                                link: visualLink,
                                source: source,
                                sourceIcon: sourceIconLink,
                                thumbnail: thumbnailLink,
                                image: imageLink,
                                inStock: inStock,
                                condition: condition,
                                rating: rating,
                                reviews: reviews
                            )
                        )
                    }
                }
            }
        }
        var related: [RelatedItem] = []
        if let relatedItems = dict["relatedItems"] as? [[String: Any]] {
            for relatedItem in relatedItems {
                if let title = relatedItem["title"] as? String,
                   let linkString = relatedItem["link"] as? String,
                   let link = URL(string: linkString),
                   let thumbnailString = relatedItem["thumbnail"] as? String,
                   let thumbnail = URL(string: thumbnailString)
                {
                    related.append(
                        RelatedItem(
                            title: title,
                            link: link,
                            thumbnail: thumbnail
                        )
                    )
                }
            }
        }
        
        return GoogleLensObject(
            title: TranslationUnit.getMessage(for: .GOOGLE_LENS_TITLE) ?? "Visual",
            productsToken: productsToken,
            visualMatches: visuals,
            relatedItems: related
        )
    }
    
    static func < (lhs: GoogleLensObject, rhs: GoogleLensObject) -> Bool {
        return false
    }
}

struct ShazamObject: ObjectDescriptionBase {
    var id: UUID
    var title: String
    var description: String?
    var errorMessage: String?
    var type: String = "shazam"
    
    let mediaItem: SHMatchedMediaItem
    
    func render() -> AnyView {
        AnyView(
            ShazamView(mediaItem: mediaItem)
        )
    }
    
    init(mediaItem: SHMatchedMediaItem, title: String) {
        self.id = UUID()
        self.description = nil
        self.errorMessage = nil
        self.mediaItem = mediaItem
        self.title = title
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        return false
    }
    
    func toDictionary() -> [String : Any]? {
        return [
            "title" : mediaItem.title ?? "",
            "artist": mediaItem.artist ?? "",
            "explicit": mediaItem.explicitContent,
            "artwork": mediaItem.artworkURL?.absoluteString ?? "",
            "web": mediaItem.webURL?.absoluteString ?? "",
            "video": mediaItem.videoURL?.absoluteString ?? ""
        ]
    }
    
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        if let title = dict["title"] as? String,
           let artist = dict["artist"] as? String,
           let explicit = dict["explicit"] as? Bool,
           let artwork = dict["artwork"] as? String,
           let webString = dict["web"] as? String,
           let videoString = dict["video"] as? String
            {
            var properties: [SHMediaItemProperty : Any] = [
                SHMediaItemProperty.title: title,
                SHMediaItemProperty.artist: artist,
                SHMediaItemProperty.explicitContent: explicit
            ]
            
            if let webURL = URL(string: webString) {
                properties.updateValue(webURL, forKey: SHMediaItemProperty.webURL)
            }
            if let artworkURL = URL(string: artwork) {
                properties.updateValue(artworkURL, forKey: SHMediaItemProperty.artworkURL)
            }
            if let videoURL = URL(string: videoString) {
                properties.updateValue(videoURL, forKey: SHMediaItemProperty.videoURL)
            }
            return ShazamObject(
                mediaItem: SHMatchedMediaItem(properties: properties),
                title: TranslationUnit.getMessage(for: .SHAZAM_TITLE) ?? "Music"
            )
        }
        return nil
    }
    
    static func < (lhs: ShazamObject, rhs: ShazamObject) -> Bool {
        return false
    }
}

struct WeatherObject: ObjectDescriptionBase, Skipable {
    var id: UUID
    var title: String
    var description: String?
    var errorMessage: String?
    var type: String = "weather"
    
    let weather: Weather
    var hourlyPlotImage: UIImage?
    var minutelyPlotImage: UIImage?
    var city: String?
    
    private init(weather: Weather, title: String) {
        self.id = UUID()
        self.title = title
        self.weather = weather
        self.description = nil
        self.errorMessage = nil
    }
    
    static func create(with weather: Weather, title: String, completion: @escaping (WeatherObject) -> Void) {
        var obj = WeatherObject(weather: weather, title: title)
        let group = DispatchGroup()

        group.enter()
        obj.getHourlyPlot { image in
            if let image = image {
                print("getHourlyPlot was good")
                obj.hourlyPlotImage = image
            } else {
                print("getHourlyPlot was bad")
            }
            group.leave()
        }
        
        group.enter()
        obj.getMinutelyPlot { image in
            if let image = image {
                print("getMinutelyPlot was good")
                obj.minutelyPlotImage = image
            } else {
                print("getMinutelyPlot was bad")
            }
            group.leave()
        }
        
        group.enter()
        obj.getCityName { name in
            if let city = name {
                obj.city = city
            }
            group.leave()
        }

        group.notify(queue: .main) {
            completion(obj)
        }
    }
    
    func render() -> AnyView {
        AnyView(
            WeatherView(
                weather: weather,
                hourlyPlotImage: hourlyPlotImage,
                minutelyPlotImage: minutelyPlotImage,
                city: city
            )
        )
    }
    
    private func getCityName(completion: @escaping (String?) -> Void) {
        guard var components = URLComponents(string: "https://myurl.com/city") else {
            print("WeatherObject: Unable to create URLComponents.")
            completion(nil)
            return
        }
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(weather.currentWeather.metadata.location.coordinate.latitude)),
            URLQueryItem(name: "long", value: String(weather.currentWeather.metadata.location.coordinate.longitude))
        ]
        
        guard let url = components.url else {
            print("WeatherObject: Unable to create URL.")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data")
                completion(nil)
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
                if let city = jsonResponse?["city"] as? String {
                    print("WeatherObject: Successfully found city: \(city)")
                    completion(city)
                } else {
                    print("WeatherObject: Unable to retrieve city name")
                    completion(nil)
                }
            } catch {
                print("WeatherObject: JSON-Serialization failed: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        return false
    }
    
    func toDictionary() -> [String : Any]? {
        return nil
    }
    
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        return nil
    }
    
    static func < (lhs: WeatherObject, rhs: WeatherObject) -> Bool {
        return false
    }
    
    private func getHourlyPlot(completion: @escaping (UIImage?) -> Void) {
        print("WeatherObject: GetHourlyPlot...")
        guard let url = URL(string: "https://myurl.com/hourlyweather") else {
            print("WeatherObject: Unable to create URL.")
            return
        }
        
        let now = Date()
        let calendar = Calendar.current

        let oneHourLater = calendar.date(byAdding: .hour, value: 1, to: now)!

        let nextHour = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: oneHourLater))!

        let next24Hours = weather.hourlyForecast
            .filter { $0.date >= nextHour }
            .prefix(24)
            .map { hourly in
                HourlyMeasurement(
                    time: hourly.date,
                    temperature: hourly.temperature.value,
                    rain: hourly.precipitationAmount.value,
                    chance: hourly.precipitationChance
                )
            }
        
        let slots = next24Hours.map { hour in
            return [
                "degrees": hour.temperature,
                "millimeters": hour.rain,
                "hours": String(calendar.component(.hour, from: hour.time)),
                "chance": hour.chance,
            ]
        }
        
        var payload: [String: Any] = ["slots": slots]
        payload.updateValue(UserDefaults.standard.string(forKey: UserDefaultsKeys.LANGUAGE.rawValue) ?? "ENG", forKey: "language")

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("WeatherObject: Failed to serialize payload.")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("WeatherObject: Request error: \(error)")
                completion(nil)
                return
            }

            guard let data = data,
                  let image = UIImage(data: data) else {
                print("WeatherObject: Invalid image data.")
                completion(nil)
                return
            }

            completion(image)
        }
        task.resume()
    }
    
    private func getMinutelyPlot(completion: @escaping (UIImage?) -> Void) {
        print("WeatherObject: GetMinutelyPlot...")
        guard let url = URL(string: "https:///minutelyweather") else {
            print("WeatherObject: Unable to create URL.")
            return
        }
        
        let now = Date()
        let oneHourLater = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
        let calendar = Calendar.current
        
        if let minuteForecast = weather.minuteForecast?.forecast {
            let minutelyData = minuteForecast
                .filter { $0.date >= now && $0.date <= oneHourLater }
                .prefix(60)
                .map { minute in
                    MinutelyMeasurement(
                        time: minute.date,
                        chance: minute.precipitationChance
                    )
                }
            
            guard minutelyData.count == 60 else {
                print("WeatherObject: MinutelyData does not contain 60 items. \(minutelyData.count)")
                completion(nil)
                return
            }
            
            let slots = minutelyData.map { minute in
                return [
                    "minute": String(calendar.component(.minute, from: minute.time)),
                    "chance": minute.chance
                ]
            }
            
            var payload: [String: Any] = ["slots": slots]
            payload.updateValue(UserDefaults.standard.string(forKey: UserDefaultsKeys.LANGUAGE.rawValue) ?? "ENG", forKey: "language")

            guard let httpBody = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
                print("WeatherObject: Failed to serialize payload.")
                completion(nil)
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = httpBody

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("WeatherObject: Minutely Request error: \(error)")
                    completion(nil)
                    return
                }

                guard let data = data,
                      let image = UIImage(data: data) else {
                    print("WeatherObject: Minutely Invalid image data.")
                    completion(nil)
                    return
                }
                completion(image)
            }
            task.resume()
        } else {
            print("WeatherObjecct: No minute data was retrived!")
            completion(nil)
        }
    }
}

struct DateObject: ObjectDescriptionBase {
    var id: UUID
    var title: String
    var description: String?
    var errorMessage: String?
    var type: String = "date"
    var events: EventList
    
    
    func render() -> AnyView {
        AnyView(
            DateView(eventList: events)
        )
    }
    
    init(title: String, suggestedEvents: [EventObject]) {
        self.id = UUID()
        self.title = title
        self.description = nil
        self.errorMessage = nil
        self.events = EventList(dateObjectID: id, events: suggestedEvents)
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        return false
    }
    
    static func == (lhs: DateObject, rhs: DateObject) -> Bool {
        return rhs.id == lhs.id
    }
    
    func toDictionary() -> [String : Any]? {
        // we treat every entry as suggested
        var eventsDict: [[String : Any]] = []
        for event in events.events {
            var eventDict: [String : Any] = [
                "title": event.title,
                "start": event.start.timeIntervalSince1970,
                "end": event.end.timeIntervalSince1970,
                "description": event.description
            ]
            if let location = event.location {
                let locationDict: [String : Any] = [
                    "adress" : location.adress,
                    "city": location.city,
                    "long": location.coordinates.longitude,
                    "lat": location.coordinates.latitude
                ]
                eventDict.updateValue(locationDict, forKey: "location")
            }
            eventsDict.append(eventDict)
        }
        return ["suggested": eventsDict]
    }
    
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        guard let suggestedEvents = dict["suggested"] as? [[String: Any]] else {
            print("DateObject: fromDictionary: could not parse suggested events")
            return nil
        }
        var eventObjects: [EventObject] = []
        for event in suggestedEvents {
            if let title = event["title"] as? String,
            let start = event["start"] as? Double,
            let end = event["end"] as? Double,
            let description = event["description"] as? String {
                if let location = event["location"] as? [String: Any],
                   let lon = location["long"] as? Double,
                   let lat = location["lat"] as? Double,
                   let adress = location["adress"] as? String,
                   let city = location["city"] as? String {
                    let eventLocation = Location(
                        coordinates: CLLocationCoordinate2D(
                            latitude: lat,
                            longitude: lon
                        ),
                        adress: adress,
                        city: city
                    )
                    eventObjects.append(
                        EventObject(
                            title: title,
                            start: Date(timeIntervalSince1970: TimeInterval(start)),
                            end: Date(timeIntervalSince1970: TimeInterval(end)),
                            description: description,
                            location: eventLocation
                        )
                    )
                } else {
                    eventObjects.append(
                        EventObject(
                            title: title,
                            start: Date(timeIntervalSince1970: TimeInterval(start)),
                            end: Date(timeIntervalSince1970: TimeInterval(end)),
                            description: description
                        )
                    )
                }
            }
        }
        return DateObject(
            title: TranslationUnit.getMessage(for: .DATE_TITLE) ?? "Calendar",
            suggestedEvents: eventObjects
        )
    }
    
    static func < (lhs: DateObject, rhs: DateObject) -> Bool {
        return false
    }
}

struct IntermeditateTextObject: ObjectDescriptionBase, Skipable, Invisible {
    var id: UUID = UUID()
    var title: String = "Intermediate text"
    var description: String?
    var errorMessage: String?
    var type: String = "intermediate text"
    
    func render() -> AnyView {
        AnyView(
            EmptyView()
        )
    }
    
    func isEqual(to other: any ObjectDescriptionBase) -> Bool {
        return false
    }
    
    func toDictionary() -> [String : Any]? {
        return nil
    }
    
    static func fromDictionary(_ dict: [String : Any]) -> (any ObjectDescriptionBase)? {
        return nil
    }
    
    static func < (lhs: IntermeditateTextObject, rhs: IntermeditateTextObject) -> Bool {
        return false
    }
    
    init(description: String) {
        self.description = description
        self.errorMessage = nil
    }
}
