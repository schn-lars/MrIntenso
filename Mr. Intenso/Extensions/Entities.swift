import Foundation
import SwiftUI
import CoreLocation
import ShazamKit

/**
    This extension is needed to convert the data present in the coredata-''database'' into our representation in the code.
    It is quite bulky, but that is the tradeoff we have. If you use protocols, you are prone to run in such kinds of problems.
 */

extension DescriptionEntityBase {
    func toObjectDescriptionBase() -> (any ObjectDescriptionBase)? {
        if let spec = self as? SpecificationDetail {
            return spec.errorMessage == nil
                ? SpecificationObject(
                    title: title ?? "Unknown",
                    specification: spec.specificationString ?? "",
                    description: descriptionText
                )
                : SpecificationObject(title: title ?? "Unknown", errorMessage: errorMessage)
        }

        if let image = self as? ImageDetail {
            return image.errorMessage == nil
                ? ImageObject(
                    title: title ?? "Image",
                    image: UIImage(data: image.imageData!)!,
                    description: descriptionText
                )
                : ImageObject(title: title ?? "Unknown", errorMessage: errorMessage ?? "")
        }

        if let url = self as? URLDetail {
            return url.errorMessage == nil
                ? WebObject(
                    title: title ?? "Website",
                    url: URL(string: url.urlString!)!,
                    description: descriptionText
                )
                : WebObject(title: title ?? "Website", errorMessage: errorMessage ?? "Unknown")
        }

        if let url = self as? LocationDetail {
            return url.errorMessage == nil
                ? LocationObject(
                    location: Location(
                        coordinates: CLLocationCoordinate2D(
                            latitude: url.latitude,
                            longitude: url.longitude
                        ),
                        adress: url.address!,
                        city: url.city!
                    )
                )
                : LocationObject(title: title ?? "Unknown", errorMessage: errorMessage ?? "")
        }
        
        if let navigation = self as? NavigationDetail {
            return navigation.errorMessage == nil
                ? NavigationObject(
                    destination: Location(
                        coordinates: CLLocationCoordinate2D(
                            latitude: navigation.latitude,
                            longitude: navigation.longitude
                        ),
                        adress: navigation.address!,
                        city: navigation.city!
                    ),
                    description: description
                )
                : NavigationObject(title: title ?? "Unknown", errorMessage: errorMessage ?? "")
        }
        
        if let shopping = self as? ShoppingDetail {
            let saleItemsArray = (shopping.items as? Set<SaleItemEntity>) ?? []

            let convertedItems: [SaleItem] = saleItemsArray.map { entity in
                SaleItem(
                    id: entity.id!,
                    thumbnail: entity.thumbnail!,
                    link: entity.link!,
                    price: entity.price,
                    currency: entity.currency!,
                    title: entity.title!,
                    itemType: entity.type!,
                    timestamp: entity.timestamp,
                    selected: entity.selected,
                    source: entity.source ?? "",
                    sourceIcon: URL(string: entity.sourceIcon ?? ""),
                    inStock: entity.inStock,
                    rating: entity.rating,
                    reviews: Int(entity.reviews)
                )
            }

            return ShoppingObject(
                id: self.uuid!,
                title: self.title ?? "",
                description: self.descriptionText,
                errorMessage: self.errorMessage,
                type: self.type ?? "shopping",
                saleItems: convertedItems
            )
        }
        
        if let shazam = self as? ShazamDetail {
            if let title = shazam.songtitle,
               let artist = shazam.artist,
               let artworkString = shazam.artwork,
               let webString = shazam.web,
               let videoString = shazam.video {
                var properties: [SHMediaItemProperty : Any] = [
                    SHMediaItemProperty.title: title,
                    SHMediaItemProperty.artist: artist,
                    SHMediaItemProperty.explicitContent: shazam.explicit
                ]
                
                if let webURL = URL(string: webString) {
                    properties.updateValue(webURL, forKey: SHMediaItemProperty.webURL)
                }
                if let artworkURL = URL(string: artworkString) {
                    properties.updateValue(artworkURL, forKey: SHMediaItemProperty.artworkURL)
                }
                if let videoURL = URL(string: videoString) {
                    properties.updateValue(videoURL, forKey: SHMediaItemProperty.videoURL)
                }
                return ShazamObject(mediaItem: SHMatchedMediaItem(properties: properties), title: TranslationUnit.getMessage(for: .SHAZAM_TITLE) ?? "Music")
            }
        }
        
        if let date = self as? DateDetail {
            let events = (date.events as? Set<EventDetail>) ?? []
            
            let convertedItems: [EventObject] = events.map { entity in
                if let city = entity.city,
                   let adress = entity.adress {
                    let location = Location(
                        coordinates: CLLocationCoordinate2D(
                            latitude: entity.lat,
                            longitude: entity.lon
                        ),
                        adress: adress,
                        city: city
                    )
                    return EventObject(
                        title: entity.title ?? "",
                        start: Date(timeIntervalSince1970: TimeInterval(entity.start)),
                        end: Date(timeIntervalSince1970: TimeInterval(entity.end)),
                        description: entity.notes ?? "",
                        location: location,
                        saved: entity.saved
                    )
                } else {
                    return EventObject(
                        title: entity.title ?? "",
                        start: Date(timeIntervalSince1970: TimeInterval(entity.start)),
                        end: Date(timeIntervalSince1970: TimeInterval(entity.end)),
                        description: entity.notes ?? "",
                        saved: entity.saved
                    )
                }
            }
            return DateObject(
                title: TranslationUnit.getMessage(for: .DATE_TITLE) ?? "Calendar",
                suggestedEvents: convertedItems
            )
        }
        return nil
    }
}

extension SaleItemEntity {
    func toSaleItem() -> SaleItem? {
        if
            let id = id,
            let thumbnail = thumbnail,
            let currency = currency,
            let title = title,
            let type = type,
            let link = link,
            let source = source,
            let sourceIcon = sourceIcon
        {
            return SaleItem(
                id: id,
                thumbnail: thumbnail,
                link: link,
                price: price,
                currency: currency,
                title: title,
                itemType: type,
                timestamp: timestamp,
                selected: selected,
                source: source,
                sourceIcon: URL(string: sourceIcon),
                rating: rating,
                reviews: Int(reviews)
            )
            
        } else {
            print("SaleItemEntity toSaleItem failed due to missing data")
            return nil
        }
    }
}

extension ObjectEntity {
    func toObjectInformation() -> ObjectInformation {
        return ObjectInformation(
            id: uuid!,
            object: objectName!,
            confidence: confidence,
            coordinates: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            lastSpotted: lastSpotted,
            favorite: true, // This method is only used on cached objects, therefore this is true
            inCache: true,
            shared: shared,
            image: UIImage(data: imageData!)!
        )
    }
}
