import Foundation
import SwiftUI

/// Possible ways to sort input
enum ShopSortCriterion: String, CaseIterable, Identifiable {
    case priceAscending     = "Price ↑"
    case priceDescending    = "Price ↓"
    case titleAZ            = "Title A→Z"
    case titleZA            = "Title Z→A"

    var id: Self { self }
}

extension ShopSortCriterion {
    var translatedCriterion: String {
        guard UserDefaults.standard.string(forKey: UserDefaultsKeys.LANGUAGE.rawValue) == "GER" else {
            return self.rawValue
        }
        
        switch self {
        case .priceAscending:
            return "Preis ↑"
        case .priceDescending:
            return "Preis ↓"
        case .titleAZ:
            return "Titel A→Z"
        case .titleZA:
            return "Titel Z→A"
        }
    }
}

struct ShoppingView: View {
    @State var shoppingItems: [SaleItem]
    @State private var selectedSort: ShopSortCriterion = .priceAscending
    
    @State private var sortByPrice = false
    @State private var detailsShown: [UUID] = []
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text(TranslationUnit.getMessage(for: .BASKET_SORT_BY) ?? "Sort by:")
                    .foregroundColor(Color.black)
                Picker("Sort", selection: $selectedSort) {
                    ForEach(ShopSortCriterion.allCases) { criterion in
                        Text(criterion.translatedCriterion).tag(criterion)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 140)
                Spacer()
            }
            .padding()
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 1)
            )
            .padding(.vertical, 4)
            
            ScrollView {
                VStack {
                    ForEach(sortedBindingItems(), id: \.id) { item in
                        saleItemRow(item)
                    }
                }
            }
        }
        .onAppear {
            // This is kind of horrible, but should not impact user at all. He does not even now, thats the magic of it.
            if !shoppingItems.isEmpty {
                let savedItems = appViewModel.getSaleItems(for: shoppingItems[0].itemType)
                for savedItem in savedItems {
                    if let shoppingItemIndex = shoppingItems.firstIndex(where: { savedItem.id == $0.id }) {
                        shoppingItems[shoppingItemIndex].selected = true
                    }
                }
            }
        }
            
    }
    
    @ViewBuilder
    func saleItemRow(_ item: Binding<SaleItem>) -> some View {
        HStack(spacing: 6) {
            if let url = URL(string: item.wrappedValue.thumbnail) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFit().frame(width: 60, height: 60)
                    case .failure:
                        Image(systemName: "photo").frame(width: 60, height: 60)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo").frame(width: 60, height: 60)
            }
            Spacer()
            Text(truncateTitle(title: item.wrappedValue.title))
                .foregroundColor(Color.black)
            Spacer()
            
            VStack {
                Text("\(item.wrappedValue.currency)\(String(format: "%.2f", item.wrappedValue.price))")
                    .foregroundColor(Color.black)
                    .padding(.trailing, 6)
                
                HStack {
                    Image(systemName: item.wrappedValue.selected ? "cart.badge.minus" : "cart.badge.plus")
                        .foregroundColor(Color.black)
                        .font(.system(size: 24))
                        .frame(width: 40, height: 40)
                        .onTapGesture {
                            item.wrappedValue.selected.toggle()
                            if item.wrappedValue.selected {
                                item.wrappedValue.timestamp = Int64(Date().timeIntervalSince1970)
                                appViewModel.insert(saleItem: item.wrappedValue)
                            } else {
                                appViewModel.delete(saleItem: item.wrappedValue)
                            }
                        }
                    
                    Image(systemName: detailsShown.contains(item.wrappedValue.id) ? "minus.square" : "plus.square")
                        .foregroundColor(Color.black)
                        .font(.system(size: 24))
                        .frame(width: 40, height: 40)
                        .onTapGesture {
                            let id = item.wrappedValue.id
                            if let index = detailsShown.firstIndex(of: id) {
                                detailsShown.remove(at: index)
                            } else {
                                detailsShown.append(id)
                            }
                        }
                }
            }
        }
        .padding()
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black, lineWidth: 1)
        )
        .padding(.vertical, 4)
        .onTapGesture {
            //https://stackoverflow.com/questions/51068874/open-web-url-link-in-browser-in-swift
            if let url = URL(string: item.wrappedValue.link), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func sortedBindingItems() -> [Binding<SaleItem>] {
        let itemBindings = shoppingItems.indices.map { index in
            $shoppingItems[index]
        }
        
        switch selectedSort {
        case .priceAscending:
            return itemBindings.sorted { $0.wrappedValue.price < $1.wrappedValue.price }
        case .priceDescending:
            return itemBindings.sorted { $0.wrappedValue.price > $1.wrappedValue.price }
        case .titleAZ:
            return itemBindings.sorted { $0.wrappedValue.title < $1.wrappedValue.title }
        case .titleZA:
            return itemBindings.sorted { $0.wrappedValue.title > $1.wrappedValue.title }
        }
    }
    
    private func truncateTitle(title: String, limit: Int = 20) -> String {
        let words = title.split(separator: " ")
        var result = ""
        
        for word in words {
            if result.count + word.count + 1 > limit {
                break
            }
            result += (result.isEmpty ? "" : " ") + word
        }
        return result.isEmpty ? "" : result + " [...]"
    }
}
