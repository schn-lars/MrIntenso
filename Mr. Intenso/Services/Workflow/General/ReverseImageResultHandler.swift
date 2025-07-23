import Foundation

class ReverseImageResultHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    var description: String = "Reverse Search"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        guard let json = input as? [String : Any] else {
            print("ReverseImagerResultHandler: Input must be a string but is \(type(of: input)).")
            completion(.failure("ReverseImagerResultHandler: Input must be a string."))
            return
        }
        
        guard let objectType = json["object"] as? String else {
            print("ReverseImagerResultHandler: ObjectType has not been added to the JSON.")
            completion(.failure("ObjectType has not been added to the JSON"))
            return
        }
        
        // Scraping the resulting JSON...
        var googleLensObject: GoogleLensObject = GoogleLensObject(productsToken: json["products_page_token"] as? String ?? "")
        if let relatedContent = json["related_content"] {
            for item in relatedContent as! [[String: Any]] {
                if let title = item["query"] as? String,
                   let link = item["link"] as? String,
                   let linkURL = URL(string: link),
                   let thumbnail = item["thumbnail"] as? String,
                   let thumbnailURL = URL(string: thumbnail) {
                    let relatedObject = RelatedItem(
                        title: title,
                        link: linkURL,
                        thumbnail: thumbnailURL
                    )
                    googleLensObject.addRelatedItem(relatedObject)
                }
            }
        }
        
        if let visualMatches = json["visual_matches"] {
            for match in visualMatches as! [[String: Any]] {
                if let title = match["title"] as? String,
                   let link = match["link"] as? String,
                   let linkURL = URL(string: link),
                   let thumbnail = match["thumbnail"] as? String,
                   let thumbnailURL = URL(string: thumbnail),
                   let source = match["source"] as? String,
                   let sourceIconString = match["source_icon"] as? String,
                   let sourceIcon = URL(string: sourceIconString),
                   let imageString = match["image"] as? String,
                   let imageURL = URL(string: imageString) {
                    let condition = match["condition"] as? String ?? nil
                    let ratingValue = Double(match["rating"] as? String ?? "") // if "" then it is nil when given to Double()
                    let reviews = match["reviews"] as? Int ?? nil
                    let inStock = match["in_stock"] as? Bool ?? nil
                    
                    // There might be additional information such as "in Stock" or price-tag
                    if let priceDict = match["price"] as? [String : Any],
                       let price = priceDict["extracted_value"] as? Double,
                       let currency = priceDict["currency"] as? String {
                        print("ReverseImageResultHandler: Got saleItem with following things: price \(price), \(title), \(link), \(String(describing: inStock)), \(condition ?? "ugugaga"), \(ratingValue ?? 6969), \(reviews ?? 7676)")
                        
                        let saleItem = SaleItem(
                            thumbnail: thumbnail,
                            link: link,
                            price: price,
                            currency: currency,
                            title: title,
                            itemType: objectType,
                            source: source,
                            sourceIcon: sourceIcon,
                            inStock: inStock,
                            condition: condition,
                            rating: ratingValue,
                            reviews: reviews
                        )
                        
                        let visualMatch = VisualMatch(
                            title: title,
                            link: linkURL,
                            source: source,
                            sourceIcon: sourceIcon,
                            thumbnail: thumbnailURL,
                            image: imageURL,
                            saleItem: saleItem,
                            inStock: inStock,
                            condition: condition,
                            rating: ratingValue,
                            reviews: reviews
                        )
                        googleLensObject.addVisualMatch(visualMatch)
                    } else {
                        let visualMatch = VisualMatch(
                            title: title,
                            link: linkURL,
                            source: source,
                            sourceIcon: sourceIcon,
                            thumbnail: thumbnailURL,
                            image: imageURL,
                            inStock: inStock,
                            condition: condition,
                            rating: ratingValue,
                            reviews: reviews
                        )
                        googleLensObject.addVisualMatch(visualMatch)
                    }
                }
            }
        }
        print("ReverseImageResultHandler: Done scraping JSON content.")
        completion(.success(googleLensObject))
    }
}
