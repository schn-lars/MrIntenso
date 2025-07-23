import Foundation

/**
    This document contains some control structures which are being used by some objects in order to make things more compact.
 */

/*
  *   MARK: Patch-Notes
 */

struct PatchNote: Codable {
    var date: String
    var hash: String
    var message: String
    
    enum CodingKeys: CodingKey {
        case date
        case hash
        case message
    }
}

struct PatchNoteSection: Codable, Identifiable {
    var id: String { date }
    let date: String
    var messages: [String]
}

/*
 *  MARK: Shopping
 */

struct SaleItem: Identifiable {
    let id: UUID
    let thumbnail: String
    let link: String
    let price: Double
    let currency: String
    let title: String
    
    // additional information
    let source: String
    let sourceIcon: URL?
    let inStock: Bool?
    let condition: String?
    let rating: Double?
    let reviews: Int?
    
    var itemType: String = ""
    var selected: Bool = false
    var timestamp: Int64 = Int64(NSDate().timeIntervalSince1970)
    
    init(id: UUID, thumbnail: String, link: String, price: Double, currency: String, title: String, itemType: String, selected: Bool, source: String, sourceIcon: URL?, inStock: Bool? = nil, condition: String? = nil, rating: Double? = nil, reviews: Int? = nil) {
        self.id = id
        self.thumbnail = thumbnail
        self.link = link
        self.price = price
        self.currency = currency
        self.title = title
        self.itemType = itemType
        self.selected = selected
        self.source = source
        self.sourceIcon = sourceIcon
        self.inStock = inStock
        self.condition = condition
        self.rating = rating
        self.reviews = reviews
    }
    
    init(id: UUID, thumbnail: String, link: String, price: Double, currency: String, title: String, itemType: String, timestamp: Int64, selected: Bool, source: String, sourceIcon: URL?, inStock: Bool? = nil, condition: String? = nil, rating: Double? = nil, reviews: Int? = nil) {
        self.id = id
        self.thumbnail = thumbnail
        self.link = link
        self.price = price
        self.currency = currency
        self.title = title
        self.itemType = itemType
        self.timestamp = timestamp
        self.selected = selected
        self.source = source
        self.sourceIcon = sourceIcon
        self.inStock = inStock
        self.condition = condition
        self.rating = rating
        self.reviews = reviews
    }
    
    init(thumbnail: String, link: String, price: Double, currency: String, title: String, itemType: String, timestamp: Int64, selected: Bool, source: String, sourceIcon: URL?, inStock: Bool? = nil, condition: String? = nil, rating: Double? = nil, reviews: Int? = nil) {
        self.id = UUID()
        self.thumbnail = thumbnail
        self.link = link
        self.price = price
        self.currency = currency
        self.title = title
        self.itemType = itemType
        self.timestamp = timestamp
        self.selected = selected
        self.source = source
        self.sourceIcon = sourceIcon
        self.inStock = inStock
        self.condition = condition
        self.rating = rating
        self.reviews = reviews
    }
    
    init(thumbnail: String, link: String, price: Double, currency: String, title: String, itemType: String, selected: Bool = false, source: String, sourceIcon: URL?, inStock: Bool? = nil, condition: String? = nil, rating: Double? = nil, reviews: Int? = nil) {
        self.id = UUID()
        self.thumbnail = thumbnail
        self.link = link
        self.price = price
        self.currency = currency
        self.title = title
        self.itemType = itemType
        self.selected = selected
        self.source = source
        self.sourceIcon = sourceIcon
        self.inStock = inStock
        self.condition = condition
        self.rating = rating
        self.reviews = reviews
    }
    
    init(thumbnail: String, link: String, price: Double, currency: String, title: String, source: String, sourceIcon: URL?, inStock: Bool? = nil, condition: String? = nil, rating: Double? = nil, reviews: Int? = nil) {
        self.id = UUID()
        self.thumbnail = thumbnail
        self.link = link
        self.price = price
        self.currency = currency
        self.title = title
        self.selected = false
        self.source = source
        self.sourceIcon = sourceIcon
        self.inStock = inStock
        self.condition = condition
        self.rating = rating
        self.reviews = reviews
    }
    
    mutating func setItemType(_ itemType: String) {
        self.itemType = itemType
    }
    
    mutating func setSelectd(_ selected: Bool) {
        self.selected = selected
    }
}

struct RelatedItem: Identifiable {
    let id = UUID()
    var title: String
    var link: URL
    var thumbnail: URL
    
    init(title: String, link: URL, thumbnail: URL) {
        self.title = title
        self.link = link
        self.thumbnail = thumbnail
    }
}

struct VisualMatch: Identifiable {
    let id = UUID()
    var title: String
    var link: URL
    var source: String
    var sourceIcon: URL
    var thumbnail: URL
    var image: URL
    var inStock: Bool? = nil
    var condition: String? = nil
    var rating: Double? = nil
    var reviews: Int? = nil
    var saleItem: SaleItem? = nil
    
    init(title: String, link: URL, source: String, sourceIcon: URL, thumbnail: URL, image: URL) {
        self.title = title
        self.link = link
        self.source = source
        self.sourceIcon = sourceIcon
        self.thumbnail = thumbnail
        self.image = image
    }
    
    init(title: String, link: URL, source: String, sourceIcon: URL, thumbnail: URL, image: URL, saleItem: SaleItem, inStock: Bool? = nil, condition: String? = nil, rating: Double? = nil, reviews: Int? = nil) {
        self.title = title
        self.link = link
        self.source = source
        self.sourceIcon = sourceIcon
        self.thumbnail = thumbnail
        self.image = image
        self.saleItem = saleItem
        self.inStock = inStock
        self.condition = condition
        self.rating = rating
        self.reviews = reviews
    }
    
    init(title: String, link: URL, source: String, sourceIcon: URL, thumbnail: URL, image: URL, inStock: Bool? = nil, condition: String? = nil, rating: Double? = nil, reviews: Int? = nil) {
        self.title = title
        self.link = link
        self.source = source
        self.sourceIcon = sourceIcon
        self.thumbnail = thumbnail
        self.image = image
        self.inStock = inStock
        self.condition = condition
        self.rating = rating
        self.reviews = reviews
    }
}

struct EventObject: Identifiable {
    var id: UUID = UUID()
    var title: String
    var start: Date
    var end: Date
    var description: String
    var location: Location?
    var saved: Bool = false
    
    init(title: String, start: Date, end: Date, description: String, location: Location? = nil, saved: Bool = false) {
        self.id = UUID()
        self.title = title
        self.start = start
        self.end = end
        self.description = description
        self.location = location
        self.saved = saved
    }
    
    init(start: Date, location: Location? = nil) {
        self.location = location
        self.start = start
        self.title = ""
        self.description = ""
        self.end = start.addingTimeInterval(1800)
    }
    
    mutating func save(status: Bool) {
        self.saved = status
    }
}

class EventList: ObservableObject {
    let dateObjectID: UUID
    @Published var events: [EventObject] = []
    
    init(dateObjectID: UUID, events: [EventObject]) {
        self.dateObjectID = dateObjectID
        self.events = events
    }
}
