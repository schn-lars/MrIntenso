import CoreData

// https://developer.apple.com/documentation/coredata/setting-up-a-core-data-stack

/**
    This document contains the entire logic for saving any particular object of the application to persistent memory.
    Furthermore, it reads out the information on boot-up.
 */

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    private var objectCache = ObjectCache()
    private var shoppingBasket = ShoppingBasket()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ObjectInformation")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Initiating persistence failed: \(error)")
            }
        }
        return container
    }()
    
    private init() {}
    
    private func save() {
        guard persistentContainer.viewContext.hasChanges else {
            print("Persistence: No uncommited changes to save.")
            return
        }
        do {
            try persistentContainer.viewContext.save()
        } catch let error as NSError {
            print("Failed to save context: \(error.localizedDescription)")
            print("Domain: \(error.domain)")
            print("Code: \(error.code)")
            print("Description: \(error.localizedDescription)")
            print("UserInfo: \(error.userInfo)")
            if let detailedErrors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
                for detailedError in detailedErrors {
                    print("Validation error: \(detailedError), userInfo: \(detailedError.userInfo)")
                }
            }
        }
    }
    
    // Here we need the methods for Creating, Deleting, Modifying and Fetching
    
    func delete(objectInformation: ObjectInformation) {
        // https://medium.com/thpintgroup/read-update-and-delete-data-with-coredata-d1b17e62addf
        print("Deleting from CoreData...")
        let context = persistentContainer.viewContext
        let coordinator = context.persistentStoreCoordinator
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ObjectEntity")
        let predicate = NSPredicate(format: "uuid == %@", objectInformation.id as CVarArg)
        fetchRequest.predicate = predicate
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try coordinator!.execute(deleteRequest, with: context)
        } catch {
            print("Error deleting object: \(error.localizedDescription)")
        }
        save()
        printPersistenceStatus()
    }
    
    
    func delete(saleItem: SaleItem) {
        shoppingBasket.removeItem(value: saleItem)
        
        print("Deleting saleItem from CoreData...")
        let context = persistentContainer.viewContext
        let coordinator = context.persistentStoreCoordinator
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SaleItemEntity")
        let predicate = NSPredicate(format: "id == %@", saleItem.id as CVarArg)
        fetchRequest.predicate = predicate
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try coordinator!.execute(deleteRequest, with: context)
        } catch {
            print("Error deleting saleItem: \(error.localizedDescription)")
        }
        save()
        printPersistenceStatus()
    }
    
    func resetCache() {
        // https://stackoverflow.com/questions/1077810/delete-reset-all-entries-in-core-data
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ObjectEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = NSBatchDeleteRequestResultType.resultTypeObjectIDs
        
        do {
            let results = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let objectIDs = results?.result as? [NSManagedObjectID]
            let changes = [NSDeletedObjectsKey : objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes as [AnyHashable : Any], into: [context])
        } catch {
            print("Error resetting persistent objects: \(error.localizedDescription)")
        }
        save()
        objectCache.clear()
        printPersistenceStatus()
    }
    
    func resetShoppingBasket() {
        shoppingBasket.reset()
        
        // https://stackoverflow.com/questions/1077810/delete-reset-all-entries-in-core-data
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SaleItemEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = NSBatchDeleteRequestResultType.resultTypeObjectIDs
        
        do {
            let results = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let objectIDs = results?.result as? [NSManagedObjectID]
            let changes = [NSDeletedObjectsKey : objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes as [AnyHashable : Any], into: [context])
        } catch {
            print("Error resetting persistent shopping items: \(error.localizedDescription)")
        }
        save()
        printPersistenceStatus()
    }
    
    
    private func printPersistenceStatus() {
        let context = persistentContainer.viewContext
        
        do {
            let objectRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ObjectEntity")
            let objectCount = try context.count(for: objectRequest)
            
            let descriptionRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DescriptionEntityBase")
            let descriptionCount = try context.count(for: descriptionRequest)
            
            let saleItemRequets = NSFetchRequest<NSFetchRequestResult>(entityName: "SaleItemEntity")
            let saleCount = try context.count(for: saleItemRequets)
            
            let dateRequets = NSFetchRequest<NSFetchRequestResult>(entityName: "EventDetail")
            let eventCount = try context.count(for: dateRequets)
            
            print("Persistence Stats:")
            print("  - Total ObjectEntity count: \(objectCount)")
            print("  - Total DescriptionEntity count: \(descriptionCount)")
            print("  - Total SaleItemEntity count: \(saleCount)")
            print("  - Total EventDetail count: \(eventCount)")
        } catch {
            print("Error while fetching persistence stats: \(error.localizedDescription)")
        }
    }
    
    func insert(saleItem: SaleItem) {
        if shoppingBasket.containsSaleItem(saleItem) {
            print("Persistence: SaleItem has already been saved.")
            return
        }
        
        shoppingBasket.addItem(saleItem)
        
        print("Inserting saleItem into CoreData...")
        let context = persistentContainer.viewContext
        let newObject = NSEntityDescription.insertNewObject(forEntityName: "SaleItemEntity", into: context) as! SaleItemEntity
        newObject.id = saleItem.id
        newObject.thumbnail = saleItem.thumbnail
        newObject.link = saleItem.link
        newObject.price = saleItem.price
        newObject.currency = saleItem.currency
        newObject.title = saleItem.title
        newObject.type = saleItem.itemType
        newObject.timestamp = saleItem.timestamp
        newObject.selected = saleItem.selected
        newObject.source = saleItem.source
        newObject.sourceIcon = saleItem.sourceIcon?.absoluteString ?? ""
        newObject.rating = saleItem.rating ?? -1.0
        newObject.reviews = Int32(saleItem.reviews ?? -1)
        newObject.condition = saleItem.condition ?? ""
        if let inStock = saleItem.inStock {
            newObject.inStock = inStock
        }
        save()
    }
    
    func insert(objectInformation: ObjectInformation) {
        if objectInformation.detailedDescription.isEmpty {
            // This should not happen anyway, but can't hurt to write it down again
            print("We do not want to save empty entries.")
            return
        }
        print("Inserting into CoreData...")
        
        // First add the detailed descriptions. How to establish connection to the main object? UUID as Foreign key, possible?
        let context = persistentContainer.viewContext
        let newObject = NSEntityDescription.insertNewObject(forEntityName: "ObjectEntity", into: context) as! ObjectEntity
        
        newObject.uuid = objectInformation.id
        newObject.objectName = objectInformation.object
        newObject.latitude = objectInformation.coordinates.latitude
        newObject.longitude = objectInformation.coordinates.longitude
        newObject.confidence = objectInformation.confidence
        newObject.imageData = objectInformation.image?.jpegData(compressionQuality: 0.8)
        newObject.lastSpotted = objectInformation.lastSpotted
        newObject.shared = objectInformation.shared
        
        for description in objectInformation.detailedDescription {
            if description is Skipable {
                continue
            }
            
            let baseDescription: DescriptionEntityBase
            
            if let specification = description as? SpecificationObject {
                let newDescription = SpecificationDetail(context: context)
                newDescription.specificationString = specification.specification
                baseDescription = newDescription
            } else if let image = description as? ImageObject {
                let newDescription = ImageDetail(context: context)
                newDescription.imageData = image.image?.jpegData(compressionQuality: 0.8)
                baseDescription = newDescription
            } else if let url = description as? WebObject {
                let newDescription = URLDetail(context: context)
                newDescription.urlString = url.url?.absoluteString
                baseDescription = newDescription
            } else if let location = description as? LocationObject {
                let newDescription = LocationDetail(context: context)
                newDescription.address = location.location.adress
                newDescription.city = location.location.city
                newDescription.latitude = location.location.coordinates.latitude
                newDescription.longitude = location.location.coordinates.longitude
                baseDescription = newDescription
            } else if let navigation = description as? NavigationObject {
                let newDescription = NavigationDetail(context: context)
                newDescription.address = navigation.destination.adress
                newDescription.city = navigation.destination.city
                newDescription.latitude = navigation.destination.coordinates.latitude
                newDescription.longitude = navigation.destination.coordinates.longitude
                baseDescription = newDescription
            } else if let shopping = description as? ShoppingObject {
                let newDescription = ShoppingDetail(context: context)
                for saleItem in shopping.saleItems {
                    let newSaleItem = SaleItemEntity(context: context)
                    newSaleItem.title = saleItem.title
                    newSaleItem.price = saleItem.price
                    newSaleItem.currency = saleItem.currency
                    newSaleItem.id = saleItem.id
                    newSaleItem.link = saleItem.link
                    newSaleItem.thumbnail = saleItem.thumbnail
                    newSaleItem.timestamp = saleItem.timestamp
                    newSaleItem.type = saleItem.itemType
                    newSaleItem.selected = saleItem.selected
                    newSaleItem.shoppingObject = newDescription
                }
                baseDescription = newDescription
            } else if let shazam = description as? ShazamObject {
                let newDescription = ShazamDetail(context: context)
                newDescription.songtitle = shazam.mediaItem.artist
                newDescription.artist = shazam.mediaItem.artist
                newDescription.artwork = shazam.mediaItem.artworkURL?.absoluteString ?? ""
                newDescription.video = shazam.mediaItem.videoURL?.absoluteString ?? ""
                newDescription.explicit = shazam.mediaItem.explicitContent
                newDescription.web = shazam.mediaItem.webURL?.absoluteString ?? ""
                baseDescription = newDescription
            } else if let date = description as? DateObject {
                let newDescription = DateDetail(context: context)
                for event in date.events.events {
                    let newEvent = EventDetail(context: context)
                    newEvent.title = event.title
                    newEvent.identifier = event.id
                    newEvent.notes = event.description
                    newEvent.end = event.end.timeIntervalSince1970
                    newEvent.start = event.start.timeIntervalSince1970
                    if let location = event.location {
                        newEvent.adress = location.adress
                        newEvent.city = location.city
                        newEvent.lat = location.coordinates.latitude
                        newEvent.lon = location.coordinates.longitude
                    }
                    newEvent.saved = event.saved
                    newEvent.dateObject = newDescription
                }
                baseDescription = newDescription
            } else {
                print("Unrecognized description type: \(type(of: description))")
                continue
            }
            
            // Set common properties on base entity
            baseDescription.title = description.title
            baseDescription.descriptionText = description.description
            baseDescription.errorMessage = description.errorMessage
            baseDescription.uuid = description.id
            baseDescription.object = newObject
            baseDescription.type = description.type
        }
        save()
        printPersistenceStatus()
    }
    
    func insert(eventObject: EventObject, for dateID: UUID) {
        print("Inserting new eventObject")
        let context = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<DateDetail> = DateDetail.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", dateID as CVarArg)
        
        do {
            if let dateDetail = try context.fetch(fetchRequest).first {
                let newEvent = EventDetail(context: context)
                newEvent.identifier = eventObject.id
                newEvent.title = eventObject.title
                newEvent.start = eventObject.start.timeIntervalSince1970
                newEvent.end = eventObject.end.timeIntervalSince1970
                newEvent.notes = eventObject.description
                newEvent.saved = eventObject.saved

                if let location = eventObject.location {
                    newEvent.city = location.city
                    newEvent.adress = location.adress
                    newEvent.lat = location.coordinates.latitude
                    newEvent.lon = location.coordinates.longitude
                }

                // relationship (1:1 and 1:M)
                newEvent.dateObject  = dateDetail
                dateDetail.addToEvents(newEvent)
                save()
            } else {
                print("No DateDetail found with id: \(dateID)")
            }
        } catch {
            print("Failed to fetch DateDetail: \(error)")
        }
    }
    
    func delete(eventObject: EventObject) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<EventDetail> = EventDetail.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", eventObject.id as CVarArg)

        do {
            if let result = try context.fetch(fetchRequest).first {
                context.delete(result)
                save()
            } else {
                print("No event found with ID \(eventObject.id) to delete.")
            }
        } catch {
            print("Failed to delete EventDetail: \(error)")
        }
    }
    
    /**
            We need to propagate changes done on the event details into our database.
            This migth be of use. I implemented it just in case. Currently it is if it is in persistence  it is a valid object.
            If not, then no need to update, as it is not yet in persistence. This could cause some issues otherwise.
     */
    func update(eventObject: EventObject) {
        print("Persistence: Updating eventObject")
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<EventDetail> = EventDetail.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", eventObject.id as CVarArg)
        
        do {
            if let result = try context.fetch(fetchRequest).first {
                result.title = eventObject.title
                result.start = eventObject.start.timeIntervalSince1970
                result.end = eventObject.end.timeIntervalSince1970
                result.notes = eventObject.description
                
                if let location = eventObject.location {
                    result.city = location.city
                    result.adress = location.adress
                    result.lat = location.coordinates.latitude
                    result.lon = location.coordinates.longitude
                }
                save()
            } else {
                print("Event with ID \(eventObject.id) not found.")
            }
        } catch {
            print("Failed to update EventDetail: \(error)")
        }
    }
    
    func getCachedObject(objectInformation: ObjectInformation) -> ObjectInformation? {
        return objectCache.getCachedObject(objectInformation)
    }
    
    /**
     This method adds a new entry to the cache. Be aware, that duplicate entries are not saved!
     */
    func cacheObject(_ objectInformation: ObjectInformation) {
        print("Persistence: Adding new object to cache! \(getNumberOfCachedObjects())")
        objectCache.addObject(objectInformation)
        print("Persistence: Added object to cache! \(getNumberOfCachedObjects())")
    }
    
    func initializeCache() {
        //https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/FetchingObjects.html
        print("Starting to initialize the cache!")
        let context = persistentContainer.viewContext
        let objectsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ObjectEntity")
        
        do {
            let fetchedObjects = try context.fetch(objectsFetch) as! [ObjectEntity]
            print("\(#function): \(fetchedObjects.count) objects found in persistence!")
            for object in fetchedObjects {
                let objectInformation = object.toObjectInformation()
                
                let parsedDescriptions: [any ObjectDescriptionBase] =
                (object.descriptions)? // NSSet
                    .compactMap { ($0 as? DescriptionEntityBase)?.toObjectDescriptionBase() } ?? []
                
                objectInformation.detailedDescription = parsedDescriptions
                print(parsedDescriptions.first?.description ?? "No descriptions")
                objectCache.addObject(objectInformation)
            }
        } catch {
            print("Error initializing cache: \(error.localizedDescription)")
        }
    }
    
    func initializeShoppingItems() {
        print("Starting to initialize shopping items.")
        let context = persistentContainer.viewContext
        let saleItemFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SaleItemEntity")
        
        do {
            let fetchedSaleItems = try context.fetch(saleItemFetch) as! [SaleItemEntity]
            for saleItem in fetchedSaleItems {
                if let parsedSaleItem = saleItem.toSaleItem() {
                    shoppingBasket.addItem(parsedSaleItem)
                }
            }
        } catch {
            print("Error initializing shopping items: \(error.localizedDescription)")
        }
    }
    
    
    func getCachedObjects(where predicate: (ObjectInformation) -> Bool) -> [ObjectInformation]? {
        return objectCache.getCachedObjects(where: predicate)
    }
    
    func getNumberOfCachedObjects() -> Int {
        return objectCache.getCachedCount()
    }
    
    func getCachedObjects() -> [ObjectInformation] {
        return objectCache.getCachedObjects()
    }
    
    func getSaleItems(for object: String) -> [SaleItem] {
        return shoppingBasket.getSaleItems(for: object)
    }
}
