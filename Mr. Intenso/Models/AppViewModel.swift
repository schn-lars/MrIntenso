import Foundation
import SwiftUI
import Reachability

/**
 
    This document contains the viewmodel which essentially creates everything. Most of the communication throughout the application
    is somehow tied to this thing. On its own it does not provide much functionality, it is more of a mediator of calls to other components.
    It is mostly used as @EnvironmentObject in Views.
 
 */

class AppViewModel: ObservableObject {
    @Published var navigationPath = NavigationPath() // This lets us traverse the app more easily
    @Published var previousNavigationCount: Int = 0
    @Published var geoNavigationPath: [ObjectInformation] = []
    @Published var reinitiator: ObjectInformation? = nil
    @Published var videoFeedViewModel: VideoFeedViewModel? = nil
    @Published var sharedObjects: [UUID] = []
    
    let reachability = try! Reachability()
    @ObservedObject var persistence: PersistenceController = .shared
    
    var settings: Settings!
    var locationManager: LocationManager?
    var informationRetrievalUnit: InformationRetrievalUnit!
    
    func initialize(with settings: Settings, locationManager: LocationManager) {
        self.settings = settings
        self.locationManager = locationManager
        self.informationRetrievalUnit = InformationRetrievalUnit(locationManager: locationManager, settings: settings)
        UserDefaults.standard.initializeDefaults()
        initializeCache()
        initializeShoppingItems()
        self.videoFeedViewModel = VideoFeedViewModel(settings: settings)
        self.videoFeedViewModel?.fetchChanges()
        print("Initialized AppViewModel:", ObjectIdentifier(self))
    }
    
    func navigate(to route: AppRoute) {
        print("Navigating to \(route)")
        navigationPath.append(route)
    }
    
    // This method is used to navigate to further detailed description views
    func geoNavigate(to object: ObjectInformation, fromCache: Bool = false) {
        print("AppViewModel: geoNavigate(to:)")
        geoNavigationPath.append(object)
        refreshLocationDescription(objectInformation: object)
        MessageCenter.shared.clearAll()
        navigate(to: AppRoute.detailedView(object, fromCache))
    }
    
    func goToRoot() {
        navigationPath = NavigationPath()
    }
    
    func goBack() {
        if navigationPath.count > 0 {
            navigationPath.removeLast()
        }
    }
    
    /**
            This function is called with the fetched object of the scanned QR-Code.
            Caching does not matter here, since this would go against the desired purpose.
     */
    func initiateSharedInfoRetrievalProcess(objectInformation: ObjectInformation) {
        geoNavigationPath.append(objectInformation)
        persistence.cacheObject(objectInformation)
        addLocationDescription(objectInformation: objectInformation)
        addShoppingBasketDescription(objectInformation: objectInformation)
        
        informationRetrievalUnit.triggerSharedInfoRetrievalProcess(
            objectInformation: objectInformation) { result in
                self.addQRCodeDescription(objectInformation: objectInformation)
                if self.persistence.getNumberOfCachedObjects() >= Constants.MAX_CACHE_SIZE {
                    print("We have reached the limit of cache size.")
                    MessageCenter.shared.showAlertMessage("You have reached max size of cache. New objects will cause deletion of old ones.")
                }
        }
        
        navigate(to: AppRoute.detailedView(objectInformation, false))
    }
    
    /**
            This method forwards the execution of a information retrieval process.
     */
    func initiateInfoRetrievalProcess(objectInformation: ObjectInformation, allowCacheHit: Bool = true) {
        if let cacheHit = persistence.getCachedObject(objectInformation: objectInformation), allowCacheHit {
            print("Cache hit!")
            geoNavigate(to: cacheHit, fromCache: true)
            if let _ = cacheHit.detailedDescription.first(where: { $0 is WeatherObject }) as? WeatherObject {
                // we already have everything we would need
                addShoppingBasketDescription(objectInformation: cacheHit)
                addQRCodeDescription(objectInformation: cacheHit)
            } else {
                informationRetrievalUnit.triggerSharedInfoRetrievalProcess(objectInformation: cacheHit) { result in
                    self.addShoppingBasketDescription(objectInformation: cacheHit)
                    self.addQRCodeDescription(objectInformation: cacheHit)
                }
            }
        } else {
            // https://github.com/ashleymills/Reachability.swift?tab=readme-ov-file
            // Note: Could not test yet, as internet connection is needed to verify licence
            reachability.whenUnreachable = { _ in
                print("You do not have internet access.")
                MessageCenter.shared.displayMessage(for: "No Internet-Access!", delay: 2.0)
                return
            }
            
            /*if !Constants.isConnectedToVPN() { // this needs to be removed for user studies when we have a SSH tunnel
                print("You are not connected to the VPN!")
                MessageCenter.shared.displayMessage(for: "VPN is not connected!", delay: 2.0)
                return
            }*/
            let newObjectInformation = ObjectInformation(objectInformation: objectInformation)
            
            // We do not want to be able to navigate back to the original cache-hit object when re-trying retrieval:
            if !allowCacheHit {
                reinitiator = objectInformation
            }
            
            geoNavigationPath.append(!allowCacheHit ? newObjectInformation : objectInformation)
            persistence.cacheObject(!allowCacheHit ? newObjectInformation : objectInformation)
            // initial version of past objects
            addLocationDescription(objectInformation: !allowCacheHit ? newObjectInformation : objectInformation)
            addShoppingBasketDescription(objectInformation: !allowCacheHit ? newObjectInformation : objectInformation)
            
            informationRetrievalUnit.triggerRetrieval(objectInformation: !allowCacheHit ? newObjectInformation : objectInformation) { finalResult in
                print("Successfully completed the information retrieval process")
                self.addQRCodeDescription(objectInformation: finalResult) // we want the process to be done in order to share objects
                if self.persistence.getNumberOfCachedObjects() >= Constants.MAX_CACHE_SIZE {
                    print("We have reached the limit of cache size.")
                    MessageCenter.shared.showAlertMessage("You have reached max size of cache. New objects will cause deletion of old ones.")
                }
            }
            navigate(to: AppRoute.detailedView(!allowCacheHit ? newObjectInformation : objectInformation, false))
        }
    }
    
    // MARK: Secondary descriptions
    
    private func addShoppingBasketDescription(objectInformation: ObjectInformation) {
        guard isBuyable(object: objectInformation.object) else { return }
        print("AppViewModel: Adding shopping basket description for \(objectInformation.id)...")
        let basket = getSaleItems(for: objectInformation.object)
        objectInformation.detailedDescription.removeAll(where: { $0 is BasketObject })
        print("AppViewModel: Adding \(basket.count) shopping basket items to \(objectInformation.id)...")
        objectInformation.addObjectDescription(new: BasketObject(object: objectInformation.object)) {}
    }
    
    /**
        This function is needed as a condition to add the shopping basket. 'Person' f.e. are not purchasable in a ideal society.
     */
    private func isBuyable(object: String) -> Bool {
        return [
             "car",
             "motorcycle",
             "airplane",
             "bus",
             "truck",
             "boat",
             "backpack",
             "umbrella",
             "handbag",
             "tie",
             "suitcase",
             "frisbee",
             "skis",
             "snowboard",
             "sportsball",
             "kite",
             "baseballbat",
             "baseballglove",
             "skateboard",
             "surfboard",
             "tennisracket",
             "bottle",
             "wineglass",
             "cup",
             "fork",
             "knife",
             "spoon",
             "bowl",
             "chair",
             "couch",
             "pottedplant",
             "bed",
             "diningtable",
             "toilet",
             "tv",
             "laptop",
             "mouse",
             "remote",
             "keyboard",
             "cellphone",
             "microwave",
             "oven",
             "toaster",
             "refrigerator",
             "book",
             "clock",
             "vase",
             "scissors",
             "teddybear",
             "hairdrier"
        ].contains(where: { $0 == object })
    }
    
    private func addLocationDescription(objectInformation: ObjectInformation) {
        print("AppViewModel: Adding location description for \(objectInformation.id)...")
        guard var similarObjects = persistence.getCachedObjects(where: { $0.object == objectInformation.object}),
           !similarObjects.isEmpty else {
            print("There are no similar objects.")
            return
        }
        
        // Replace and refresh the past objects
        objectInformation.detailedDescription.removeAll(where: { $0 is MapObject })
        similarObjects.removeAll { obj in
            geoNavigationPath.contains(where: { $0.id == obj.id })
        }
        
        // We do not want to have the initiator of a new query to be inside the 'Past Objects' menu
        if let reinitiator = reinitiator {
            similarObjects.removeAll(where: { $0.id == reinitiator.id })
            self.reinitiator = nil
        }
        
        if similarObjects.isEmpty { return } // We do not want empty map
        
        print("AppViewModel: There have been found \(similarObjects.count) similar objects.")
        let mapObject = MapObject(title: "Past Objects", similarObjects: similarObjects)
        objectInformation.addObjectDescription(new: mapObject) {}
    }
    
    private func addQRCodeDescription(objectInformation: ObjectInformation) {
        print("AppViewModel: Adding Share description for \(objectInformation.id)...")
        objectInformation.detailedDescription.removeAll(where: { $0 is QRCodeObject })
        
        objectInformation.addObjectDescription(new: QRCodeObject(objectInformation: objectInformation)) {}
    }
    
    // MARK: Persistence
    
    func getSaleItems(for object: String) -> [SaleItem] {
        return persistence.getSaleItems(for: object)
    }
    
    func initializeCache() {
        persistence.initializeCache()
    }
    
    func initializeShoppingItems() {
        persistence.initializeShoppingItems()
    }
    
    func delete(objectInformation: ObjectInformation) {
        persistence.delete(objectInformation: objectInformation)
    }
    
    func delete(saleItem: SaleItem) {
        persistence.delete(saleItem: saleItem)
    }
    
    func delete(eventObject: EventObject) {
        persistence.delete(eventObject: eventObject)
    }
    
    func insert(eventObject: EventObject, for dateObjectID: UUID) {
        persistence.insert(eventObject: eventObject, for: dateObjectID)
    }
    
    func update(eventObject: EventObject) {
        persistence.update(eventObject: eventObject)
    }
    
    func insert(objectInformation: ObjectInformation) {
        // If you favorize the info without it being in cache (because of errorMessage)
        if !isObjectInformationCached(objectInformation: objectInformation) {
            persistence.cacheObject(objectInformation)
        }
        persistence.insert(objectInformation: objectInformation)
    }
    
    func insert(saleItem: SaleItem) {
        persistence.insert(saleItem: saleItem)
    }
    
    func reset() {
        resetCache()
        resetShoppingBasket()
    }
    
    /**
        This method deletes the persistent SaleItems and the ones inside the shopping-basket.
     */
    func resetShoppingBasket() {
        persistence.resetShoppingBasket()
    }
    
    /**
        This method is deleting the persistent objects as well as the ones inside the memory.
     */
    func resetCache() {
        persistence.resetCache()
    }
    
    func isObjectInformationCached(objectInformation: ObjectInformation) -> Bool {
        return persistence.getCachedObjects().contains(where: { $0.id == objectInformation.id })
    }
    
    func refreshLocationDescription(objectInformation: ObjectInformation) {
        print("AppViewModel: refreshLocationDescription(\(objectInformation.id)")
        addLocationDescription(objectInformation: objectInformation)
    }
    
    // MARK: API-Calls
    
    func shareRequest(
        objectInformation: ObjectInformation,
        completion: @escaping (Bool) -> Void
    ) {
        print("AppViewModel: shareRequest(\(objectInformation.id)")
        if sharedObjects.contains(where: { $0.uuidString == objectInformation.id.uuidString }) {
            print("ShareRequest: Object is already shared!")
            completion(true)
            return
        }
        sharedObjects.append(objectInformation.id)
        
        // Payload
        guard let payload = objectInformation.sharePayload else {
            print("AppViewModel: Share payload is invalid")
            completion(false)
            return
        }
        
        guard let url = URL(string: "https://myurl.com/share") else {
            print("FetchChanges: URL is nil")
            completion(false)
            return
        }
        
        var fetchRequest = URLRequest(url: url)
        fetchRequest.httpMethod = "POST"
        fetchRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            fetchRequest.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("AppViewModel:ShareRequest failed to serialize payload")
            completion(false)
            return
        }
        print("AppViewModel: ShareRequest about to perform request")
        
        URLSession.shared.dataTask(with: fetchRequest) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    if let data,
                    let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                       let errorMessage = errorDict["error"] {
                        print("\(#function): Server returned error - \(errorMessage)")
                        completion(false)
                        return
                    }
                } else {
                    print("ShareRequest was successful")
                    completion(true)
                    return
                }
            }
        }
        .resume()
    }
    
    /**
            This function is called for either clean up for the server or if the user deliberately closes the window of the QR-Code.
            We might want to think about adding some sort of timer to trigger this automatically, but i think this is unnecessary.
            Just make sure that the client cannot flood the server with requests
     */
    func exitShareRequest(objectInformation: ObjectInformation) {
        print("AppViewModel: exitShareRequest(\(objectInformation.id)")
        if !sharedObjects.contains(where: { $0.uuidString == objectInformation.id.uuidString }) {
            print("ExitShareRequest: Object is not shared!")
            return
        }
        sharedObjects.removeAll(where: { $0.uuidString == objectInformation.id.uuidString })
        
        // Payload
        let payload = ["uuid" : objectInformation.id.uuidString]
        guard let url = URL(string: "https://myurl.com/exitshare") else {
            print("ExitShareRequest: URL is nil")
            return
        }
        
        var fetchRequest = URLRequest(url: url)
        fetchRequest.httpMethod = "POST"
        fetchRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            fetchRequest.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("AppViewModel: ExitShareRequest failed to serialize payload")
            return
        }
        print("AppViewModel: ExitShareRequest about to perform request")
        
        URLSession.shared.dataTask(with: fetchRequest) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    if let data,
                    let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                       let errorMessage = errorDict["error"] {
                        print("\(#function): Server returned error - \(errorMessage)")
                        return
                    }
                } else {
                    print("ExitShareRequest was successful")
                    return
                }
            }
        }
        .resume()
    }
    
    func fetchShareRequest(uuid: String) {
        print("AppViewModel: fetchShareRequest(\(uuid)")
        // Payload
        let payload = ["uuid" : uuid]
        guard let url = URL(string: "https://myurl.com/fetch") else {
            print("FetchShareRequest: URL is nil")
            return
        }
        
        var fetchRequest = URLRequest(url: url)
        fetchRequest.httpMethod = "POST"
        fetchRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            fetchRequest.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("AppViewModel: FetchShareRequest failed to serialize payload")
            return
        }
        print("AppViewModel: FetchShareRequest about to perform request")
        
        URLSession.shared.dataTask(with: fetchRequest) { (data, response, error) in
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
            
            guard let data = data else {
                print("FetchShareRequest failed to get data")
                return
            }
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
                if let informationData = jsonResponse,
                   let fetchedInfo = ObjectInformation.fromJSON(informationData) {
                    print("FetchShareRequest: Successfully fetched!")
                    DispatchQueue.main.async {
                        if let videoFeed = self.videoFeedViewModel?.videoFeed {
                            print("FetchShareRequest: stopping video")
                            videoFeed.stop()
                        }
                        print("FetchShareRequest: processing...")
                        self.initiateSharedInfoRetrievalProcess(objectInformation: fetchedInfo)
                    }
                } else {
                    print("Unexpected response format")
                }
            } catch {
                print("FetchShareRequest: Error parsing JSON data")
                return
            }
            
        }
        .resume()
    }
}
