import SwiftUI

struct GoogleLensResultView: View {
    @EnvironmentObject var mainViewModel: AppViewModel
    @State var showRelatedContent: Bool = true
    
    let relatedContent: [RelatedItem]
    let visualMatches: [VisualMatch]
    
    var body: some View {
        ScrollView {
            VStack {
                if !relatedContent.isEmpty {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center) {
                            if let msg = TranslationUnit.getMessage(for: .GOOGLE_LENS_RELATED_TITLE) {
                                Text(msg)
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 22))
                            } else {
                                Text("Related Content")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 22))
                            }
                            
                            Spacer()
                            Image(systemName: showRelatedContent ? "arrow.up.square" : "arrow.down.square")
                                .frame(width: 35, height: 35)
                                .font(.system(size: 35))
                                .foregroundColor(Color.black)
                                .onTapGesture {
                                    showRelatedContent.toggle()
                                }
                        }
                        if showRelatedContent {
                            VStack(spacing: 5) {
                                ForEach(relatedContent, id: \.id) { relatedItem in
                                    Divider()
                                        .foregroundColor(Color.black)
                                    relatedItemRow(relatedItem)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1)
                    )
                }
                
                if !visualMatches.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(visualMatches, id: \.id) { visualMatch in
                            Divider()
                                .foregroundColor(Color.black)
                            visualMatchItemRow(visualMatch)
                        }
                    }
                } else {
                    if let msg = TranslationUnit.getMessage(for: .GOOGLE_LENS_NO_OBJECTS_FOUND) {
                        Text(msg)
                            .foregroundColor(Color.black)
                            .font(.system(size: 22))
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func relatedItemRow(_ item: RelatedItem) -> some View {
        HStack(spacing: 6) {
            AsyncImage(url: item.thumbnail) { phase in
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
            Spacer()
            Text(item.title)
                .foregroundColor(Color.black)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
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
            if UIApplication.shared.canOpenURL(item.link) {
                UIApplication.shared.open(item.link)
            }
        }
    }
    
    @ViewBuilder
    func visualMatchItemRow(_ item: VisualMatch) -> some View {
        HStack(spacing: 6) {
            // thumbnail
            AsyncImage(url: item.thumbnail) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .foregroundColor(Color.black)
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    Image(systemName: "photo.badge.exclamationmark").resizable().scaledToFit()
                        .foregroundColor(Color.black)
                @unknown default:
                    Image(systemName: "photo.badge.exclamationmark").resizable().scaledToFit()
                        .foregroundColor(Color.black)
                }
            }
            .frame(width: 80, height: 80)
            
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    AsyncImage(url: item.sourceIcon) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable().scaledToFit().frame(width: 20, height: 20)
                        case .failure:
                            EmptyView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                        
                    Text(item.source)
                        .foregroundColor(Color.black)
                    
                    if let saleItem = item.saleItem {
                        Text("•")
                            .foregroundColor(Color.black)
                        Text(String(format: "%.1f", saleItem.price) + " \(saleItem.currency)")
                            .foregroundColor(Color.black)
                    }
                }
                Text(item.title)
                    .foregroundColor(Color.black)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                // TODO: pretty sure this can be done cleaner...
                if let condition = item.condition,
                   let rating = item.rating,
                   let reviews = item.reviews,
                   rating >= 0.0, reviews > 0 {
                    // we have the whole lower thing
                    HStack(spacing: 5) {
                        Text(condition)
                            .foregroundColor(Color.black)
                            .font(.caption)
                        Text("•")
                            .foregroundColor(Color.black)
                            .font(.caption)
                        Text(String(format: "%.1f", rating)) // 1.0 - 5.0
                            .foregroundColor(Color.black)
                            .font(.caption)
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
                        Text("•")
                            .foregroundColor(Color.black)
                            .font(.caption)
                        if let msg = TranslationUnit.getMessage(for: .GOOGLE_LENS_REVIEWS) {
                            Text(String(format: msg, reviews))
                                .foregroundColor(Color.black)
                                .font(.caption)
                        } else {
                            Text("\(reviews) reviews")
                                .foregroundColor(Color.black)
                                .font(.caption)
                        }
                    }
                } else if let condition = item.condition {
                    HStack(spacing: 5) {
                        Text(condition)
                            .foregroundColor(Color.black)
                            .font(.caption)
                    }
                } else if let rating = item.rating,
                          let reviews = item.reviews,
                          rating >= 0.0, reviews >= 0  {
                    // I assume that rating and reviews are bound together
                    HStack(spacing: 5) {
                        Text(String(format: "%.1f", rating))
                            .foregroundColor(Color.black)
                            .font(.caption)
                        ZStack {
                            Image(systemName: "star") 
                                .foregroundColor(.gray)
                            
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .mask(
                                    GeometryReader { geo in
                                        Rectangle()
                                            .size(width: geo.size.width * (rating / 5.0), height: geo.size.height)
                                            .alignmentGuide(.leading) { _ in 0 }
                                    }
                                )
                        }
                        Text("•")
                            .foregroundColor(Color.black)
                            .font(.caption)
                        if let msg = TranslationUnit.getMessage(for: .GOOGLE_LENS_REVIEWS) {
                            Text(String(format: msg, reviews))
                                .foregroundColor(Color.black)
                                .font(.caption)
                        } else {
                            Text("\(reviews) reviews")
                                .foregroundColor(Color.black)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black, lineWidth: 1)
        )
        .padding(.vertical, 4)
        .onTapGesture {
            if var saleItem = item.saleItem {
                saleItem.setSelectd(true)
                mainViewModel.insert(saleItem: saleItem)
            }
            
            //https://stackoverflow.com/questions/51068874/open-web-url-link-in-browser-in-swift
            if UIApplication.shared.canOpenURL(item.link) {
                UIApplication.shared.open(item.link)
            }
        }
    }
}
