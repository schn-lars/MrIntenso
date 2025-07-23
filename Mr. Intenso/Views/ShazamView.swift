import Foundation
import ShazamKit
import SwiftUI
import AVKit
import MusicKit
import MediaPlayer
import StoreKit

struct ShazamView: View {
    let mediaItem: SHMatchedMediaItem
    @State private var tabViewIndex = 0
    @State private var hasAppleMusicSubscription: Bool = false
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(alignment: .center) {
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        if mediaItem.explicitContent {
                            Image(systemName: "e.square.fill")
                                .foregroundColor(Color.black)
                                .font(.system(size: 18))
                        }
                        if let title = mediaItem.title {
                            Text(title == "" ? (TranslationUnit.getMessage(for: .SHAZAM_UNKNOWN_TITLE) ?? "Unknown title") : title)
                                .foregroundColor(Color.black)
                                .font(.system(size: 24))
                                .multilineTextAlignment(.center)
                        } else {
                            Text(TranslationUnit.getMessage(for: .SHAZAM_UNKNOWN_TITLE) ?? "Unknown title")
                                .foregroundColor(Color.black)
                                .font(.system(size: 24))
                                .multilineTextAlignment(.center)
                        }
                    }
                    HStack(alignment: .center) {
                        if let artist = mediaItem.artist {
                            Text(artist == "" ? (TranslationUnit.getMessage(for: .SHAZAM_UNKNOWN_ARTIST) ?? "Unknown artist") : artist)
                                .foregroundColor(Color.black)
                                .font(.system(size: 16))
                                .multilineTextAlignment(.center)
                        } else {
                            Text(TranslationUnit.getMessage(for: .SHAZAM_UNKNOWN_ARTIST) ?? "Unknown artist")
                                .foregroundColor(Color.black)
                                .font(.system(size: 16))
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            TabView(selection: $tabViewIndex) {
                // Artwork slide
                if let artworkURL = mediaItem.artworkURL {
                    AsyncImage(url: artworkURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .overlay (
                                    HStack {
                                        Spacer()
                                        
                                        Image(systemName: "shazam.logo")
                                            .font(.system(size: 30))
                                            .foregroundColor(Color.white)
                                            .padding(5)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.gray.opacity(0.7))
                                            )
                                            .onTapGesture {
                                                if let webURL = mediaItem.webURL {
                                                    if UIApplication.shared.canOpenURL(webURL) {
                                                        UIApplication.shared.open(webURL)
                                                    }
                                                }
                                            }
                                    }
                                    .padding(.all, 2),
                                    alignment: .bottomTrailing
                                )
                        case .failure:
                            Image(systemName: "photo").resizable().scaledToFit()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .tag(0)
                }
                
                
                
                // Video slide
                // https://www.hackingwithswift.com/quick-start/swiftui/how-to-play-movies-with-videoplayer
                if let videoURL = mediaItem.videoURL, hasAppleMusicSubscription {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .tag(1)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            HStack(spacing: 8) {
                ForEach(0..<(mediaItem.videoURL != nil ? 2 : 1), id: \.self) { index in
                    Circle()
                        .fill(index == tabViewIndex ? Color.black : Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: tabViewIndex)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .onAppear {
            SKCloudServiceController.requestAuthorization { status in
                if status == .authorized {
                    SKCloudServiceController().requestCapabilities { capabilities, error in
                        if capabilities.contains(.musicCatalogPlayback) {
                            DispatchQueue.main.async {
                                self.hasAppleMusicSubscription = false
                            }
                        }
                    }
                }
            }
        }
    }
}
