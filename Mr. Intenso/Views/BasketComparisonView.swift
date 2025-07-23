import Foundation
import SwiftUI

/// Possible ways to sort input
enum BasketSortCriterion: String, CaseIterable, Identifiable {
    case priceAscending     = "Price ↑"
    case priceDescending    = "Price ↓"
    case titleAZ            = "Title A→Z"
    case titleZA            = "Title Z→A"
    case mostRecent         = "Most Recent"
    case leastRecent        = "Least Recent"

    var id: Self { self }
}

extension BasketSortCriterion {
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
        case .leastRecent:
            return "Älteste"
        case .mostRecent:
            return "Neueste"
        }
    }
}

struct BasketComparisonView: View {
    let object: String
    @State private var saleItems: [SaleItem] = []
    @State private var selectedSort: BasketSortCriterion = .priceAscending
    @State private var sortByPrice = false
    @State private var detailsShown: [UUID] = []
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text(TranslationUnit.getMessage(for: .BASKET_SORT_BY) ?? "Sort by:")
                    .foregroundColor(Color.black)
                Picker("Sort", selection: $selectedSort) {
                    ForEach(BasketSortCriterion.allCases) { criterion in
                        Text(criterion.translatedCriterion).tag(criterion)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 140)
                Spacer()
            }
            .padding()
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.black, lineWidth: 1)
            )
            .padding(.vertical, 4)
            
            if saleItems.first(where: { $0.selected }) == nil {
                Text(TranslationUnit.getMessage(for: .BASKET_EMPTY) ?? "No items in basket.")
                    .foregroundColor(.black)
                    .font(.system(size: 22))
                    .padding()
            } else {
                ScrollView {
                    VStack {
                        ForEach(sortedBindingItems(), id: \.id) { item in
                            if item.wrappedValue.selected {
                                saleItemRow(item)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            saleItems = appViewModel.getSaleItems(for: object)
            print("BasketComparisonView: number of saleitems: \(saleItems.count)")
        }
    }
    
    @ViewBuilder
    func saleItemRow(_ item: Binding<SaleItem>) -> some View {
        VStack {
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
                        Image(systemName: item.wrappedValue.selected ? "trash" : "cart.badge.plus")
                            .foregroundColor(Color.black)
                            .font(.system(size: 24))
                            .frame(width: 40, height: 40)
                            .onTapGesture {
                                item.wrappedValue.selected.toggle()
                                appViewModel.delete(saleItem: item.wrappedValue)
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
            
            if detailsShown.contains(item.wrappedValue.id) {
                Divider()
                    .foregroundStyle(Color.black)
                VStack(spacing: 5) {
                    // No information has been given for any
                    if item.wrappedValue.source == "",
                       let condition = item.wrappedValue.condition,
                            condition == "",
                        let rating = item.wrappedValue.rating,
                        let reviews = item.wrappedValue.reviews,
                            reviews < 0,
                            item.wrappedValue.inStock == nil {
                        HStack(alignment: .center) {
                            Text("No information available")
                                .foregroundStyle(Color.black)
                        }
                    }
                       
                    
                    // Source + Icon
                    if item.wrappedValue.source != "" {
                        HStack {
                            Text("•")
                                .foregroundStyle(Color.black)
                                .fontWeight(.bold)
                            Text("\(TranslationUnit.getMessage(for: .BASKET_SOURCE_TITLE) ?? "Source"):")
                                .foregroundStyle(Color.black)
                            Spacer()
                                .frame(maxWidth: .infinity)
                            
                            Text(item.wrappedValue.source)
                                .foregroundStyle(Color.black)
                                .lineLimit(1)
                            
                            if let iconURL = item.wrappedValue.sourceIcon {
                                AsyncImage(url: iconURL) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image.resizable().scaledToFit().frame(width: 20, height: 20)
                                    case .failure:
                                        Image(systemName: "photo").frame(width: 20, height: 20)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                    }
                    
                    // condition
                    if let condition = item.wrappedValue.condition,
                        condition != "" {
                        HStack {
                            Text("•")
                                .foregroundStyle(Color.black)
                                .fontWeight(.bold)
                            Text("\(TranslationUnit.getMessage(for: .BASKET_CONDITION_TITLE) ?? "Condition"):")
                                .foregroundStyle(Color.black)
                            Spacer()
                                .frame(maxWidth: .infinity)
                            
                            Text(condition)
                                .foregroundStyle(Color.black)
                        }
                    }
                    
                    // in stock
                    if let inStock = item.wrappedValue.inStock {
                        HStack {
                            Text("•")
                                .foregroundStyle(Color.black)
                                .fontWeight(.bold)
                            Text("\(TranslationUnit.getMessage(for: .BASKET_INSTOCK_TITLE) ?? "In Stock"):")
                                .foregroundStyle(Color.black)
                            Spacer()
                                .frame(maxWidth: .infinity)
                            
                            Text((inStock ? TranslationUnit.getMessage(for: .YES) : TranslationUnit.getMessage(for: .NO)) ?? "-")
                                .foregroundStyle(Color.black)
                        }
                    }
                    
                    // reviews
                    if let reviews = item.wrappedValue.reviews,
                        reviews >= 0 {
                        HStack {
                            Text("•")
                                .foregroundStyle(Color.black)
                                .fontWeight(.bold)
                            Text("\(TranslationUnit.getMessage(for: .BASKET_REVIEWS_TITLE) ?? "Reviews"):")
                                .foregroundStyle(Color.black)
                            Spacer()
                                .frame(maxWidth: .infinity)
                                
                            Text(String(reviews))
                                .foregroundColor(Color.black)
                        }
                    }
                    
                    // rating
                    if let rating = item.wrappedValue.rating,
                        rating >= 0.0 {
                        HStack {
                            Text("•")
                                .foregroundStyle(Color.black)
                                .fontWeight(.bold)
                            Text("\(TranslationUnit.getMessage(for: .BASKET_RATING_TITLE) ?? "Rating"):")
                                .foregroundStyle(Color.black)
                            Spacer()
                                .frame(maxWidth: .infinity)
                            
                            Text(String(format: "%.1f", rating)) // 1.0 - 5.0
                                .foregroundColor(Color.black)
                            ZStack {
                                Image(systemName: "star") // empty star
                                    .foregroundColor(.gray)

                                Image(systemName: "star.fill") // filled star
                                    .foregroundColor(.yellow)
                                    .mask(
                                        GeometryReader { geo in
                                            Rectangle()
                                                .size(width: geo.size.width * (rating / 5.0), height: geo.size.height)
                                                .alignmentGuide(.leading) { _ in 0 }
                                        }
                                    )
                            }
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
        let itemBindings = saleItems.indices.map { index in
            $saleItems[index]
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
        case .mostRecent:
            return itemBindings.sorted { $0.wrappedValue.timestamp > $1.wrappedValue.timestamp }
        case .leastRecent:
            return itemBindings.sorted { $0.wrappedValue.timestamp < $1.wrappedValue.timestamp }
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
