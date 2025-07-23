import Foundation

/**
    This document contains the code relevant to the application-side's shopping basket. The persistence is located somewhere else.
    This is because the shopping basket does not need to care which ones are persistent, because as long as I can make sure, that I am adding
    further items successfully and make sure that initially all saved items are put into the basket, it works.
 */

class ShoppingBasket: ObservableObject {
    @Published var saleItems: [String: [SaleItem]] = [:]
    
    func reset() {
        saleItems = [:]
    }
    
    func addItem(_ value: [SaleItem]) {
        if value.isEmpty { return }
        if value.allSatisfy({ $0.itemType == value[0].itemType }) { return }
        if saleItems.keys.contains(value[0].itemType) {
            saleItems[value[0].itemType]?.append(contentsOf: value)
        } else {
            saleItems[value[0].itemType] = value
        }
    }
    
    func containsSaleItem(_ value: SaleItem) -> Bool {
        return saleItems.keys.contains(value.itemType) &&
        (saleItems[value.itemType]?.contains(where: { $0.id == value.id }) ?? false ||
         saleItems[value.itemType]?.contains(where: { $0.link == value.link }) ?? false)
    }
    
    func addItem(_ value: SaleItem) {
        if saleItems.keys.contains(value.itemType) {
            if saleItems[value.itemType]?.contains(where: { $0.id == value.id }) ?? false { return }
            saleItems[value.itemType]?.append(value)
        } else {
            saleItems[value.itemType] = [value]
        }
    }
    
    func getSaleItems(for key: String) -> [SaleItem] {
        return saleItems[key] ?? []
    }
    
    func removeItem(value: SaleItem) {
        guard var itemList = saleItems[value.itemType] else { return }
        if let index = itemList.firstIndex(where: { $0.id == value.id }) {
            itemList.remove(at: index)
            if itemList.isEmpty {
                saleItems.removeValue(forKey: value.itemType)
            } else {
                saleItems[value.itemType] = itemList
            }
        }
    }
}
