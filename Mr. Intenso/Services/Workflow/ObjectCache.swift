import Foundation

class ObjectCache {
    private var cachedObjects = PriorityQueue<ObjectInformation>()
    
    func addObject(_ newObject: ObjectInformation) {
        // Do not delete items which the user explicitly wanted to save
        if let identicalObject = getFirst(where: { $0.isTheSameObject(newObject) }), !identicalObject.favourite {
            print("Found identical object. Deleting this now. \(identicalObject.id)")
            removeAll(where: { $0.id == identicalObject.id })
        }
        // Check cache size and remove oldest if needed
        if getCachedCount() >= Constants.MAX_CACHE_SIZE {
            print("Cache is full. Removing oldest object.")
            let allCached = getCachedObjects()
            if let oldestTime = allCached.map(\.lastSpotted).min() {
                let candidates = allCached.filter { !$0.favourite }.sorted(by: { $0.lastSpotted < $1.lastSpotted })
                if let removable = candidates.first ?? allCached.first(where: { $0.lastSpotted == oldestTime }) {
                    print("Removed oldest object from cache! (\(removable.id))")
                    removeAll(where: { $0.id == removable.id })
                }
            }
        }
        newObject.inCache = true
        cachedObjects.push(newObject)
        print("ObjectCache: Added \(newObject.id). Now cache contains \(cachedObjects.size())")
    }
    
    func getCachedObject(_ newObject: ObjectInformation) -> ObjectInformation? {
        return cachedObjects.retrieveFirstObject(where: { $0 == newObject })
    }
    
    func removeAll(where predicate: (ObjectInformation) -> Bool) {
        cachedObjects.removeAll(where: predicate)
    }
    
    func getFirst(where predicate: (ObjectInformation) -> Bool) -> ObjectInformation? {
        return cachedObjects.retrieveFirstObject(where: predicate)
    }
    
    func getCachedCount() -> Int {
        return cachedObjects.size()
    }
    
    var description: String {
        return cachedObjects.description
    }
    
    func clear() {
        cachedObjects.clear()
    }
    
    func getCachedObjects() -> [ObjectInformation] {
        return cachedObjects.getAll { _ in true }
    }
    
    func getCachedObjects(where predicate: (ObjectInformation) -> Bool) -> [ObjectInformation] {
        return cachedObjects.getAll(where: predicate)
    }
}
