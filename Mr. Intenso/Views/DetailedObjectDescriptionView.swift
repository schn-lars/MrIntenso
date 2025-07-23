import SwiftUI

struct DetailedObjectDescriptionView: View {
    let radius: CGFloat = 140
    let fromCache: Bool
    @State private var selectedIndex: Int = 0
    @State private var showRetriggerButton: Bool = false
    @State private var disableRetriggerButton: Bool = false
    @ObservedObject var info: ObjectInformation
    @EnvironmentObject var messageCenter: MessageCenter
    @State private var showAlert = false
    @State private var showQRCode: Bool = false
    @EnvironmentObject var mainViewModel: AppViewModel
    
    @State private var isSaveable: Bool = false
    
    var onDisappear: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            // TOP SECTION - 1/4 of the height
            VStack(spacing: 12) {
                Text(Constants.getTranslatedLanguage(for: info.object))
                    .font(.title)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack(spacing: 30) {
                    // Left Circle - Favorite Icon
                    ZStack {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: radius / 2, height: radius / 2)
                            .overlay(Circle().stroke(Color.black, lineWidth: 3))
                        
                        Image(systemName: info.favourite ? "star.fill" : "star")
                            .foregroundColor(info.shared ? .red : .yellow)
                            .font(.system(size: 30))
                            .onTapGesture {
                                info.setFavorite()
                                if info.favourite {
                                    mainViewModel.insert(objectInformation: info)
                                    messageCenter.clearErrorMessage()
                                    messageCenter.showMessage("Successfully saved object!")
                                } else {
                                    mainViewModel.delete(objectInformation: info)
                                    messageCenter.showMessage("Successfully deleted object!")
                                }
                            }
                            .disabled(!isSaveable)
                    }
                    // Middle Circle - Image
                    ZStack {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: radius, height: radius)
                            .overlay(Circle().stroke(Color.black, lineWidth: 3))
                        if let uiImage = info.image {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: radius - 10, height: radius - 10)
                                .clipShape(Circle())
                        }
                    }
                    // Right Circle - Confidence Score
                    ZStack {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: radius / 2, height: radius / 2)
                            .overlay(Circle().stroke(Color.black, lineWidth: 3))
                        
                        Text(String(format: "%.1f", info.confidence))
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
            }
            .offset(y: -20)
            
            // SELECTOR BOX
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        let isSelected = index == selectedIndex
                        Text(option.title)
                            .foregroundColor(.black)
                            .underline(isSelected, color: .black)
                            .onTapGesture {
                                selectedIndex = index
                            }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 40)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 1)
            )
            .padding(.horizontal)
            
            // MAIN CONTENT CONTAINER
            mainContent
            
            // Status Bar
            VStack {
                HStack(spacing: 20) {
                    if let errorMessage = messageCenter.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if let message = messageCenter.message {
                        Text(message)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if fromCache {
                        // Cache-Hit
                        if showRetriggerButton {
                            Button("Re-try retrieval") {
                                // Your action
                                print("Retrying information retrieval")
                                mainViewModel.initiateInfoRetrievalProcess(objectInformation: info, allowCacheHit: false)
                                print("Retrying has been finished!")
                                showRetriggerButton.toggle()
                            }
                            .buttonStyle(.bordered)
                        } else if mainViewModel.isObjectInformationCached(objectInformation: info) {
                            HStack {
                                ProgressView()
                                Text("This is a Cache-Hit!")
                                    .foregroundColor(.gray)
                            }
                            .onAppear {
                                // Replace with button after a short delay
                                isSaveable = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showRetriggerButton.toggle()
                                    }
                                }
                            }
                        }
                    } else if let handlerCount = info.handlerCount {
                        let currentCount = info.processedHandlers
                        if handlerCount == currentCount {
                            Text(TranslationUnit.getMessage(for: .INFO_PROCESS_COMPLETE) ?? "Information-Retrieval process completed!")
                                .foregroundColor(.black)
                                .onAppear {
                                    isSaveable = true
                                }
                        } else {
                            Text(String(format: TranslationUnit.getMessage(for: .INFO_PROCESSING) ?? "Processed %d/%d", currentCount, handlerCount))
                                .foregroundColor(.black)
                        }
                    } else {
                        Text("EmptyDetailedView")
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .background(messageCenter.errorMessage != nil ? Color.red.opacity(0.15) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 1)
            )
            .padding(.horizontal)
        }
        .padding(.top, 8)
        //.ignoresSafeArea(edges: .top)
        .background(Color(red: 210 / 255, green: 248 / 255, blue: 210 / 255)) // found online
        .onReceive(info.objectWillChange) { _ in
            if selectedOption is PlaceholderObject, !options.isEmpty {
                selectedIndex = 0
            }
        }
        .onDisappear {
            print("DetailedDescriptionView: onDisappear for \(info.id)")
            mainViewModel.exitShareRequest(objectInformation: info)
            onDisappear?()
        }
        .onAppear {
            // Check if the object is still in the cache
            print("DetailedObjectDescriptionView: onAppear for \(info.id)")
            if !mainViewModel.isObjectInformationCached(objectInformation: info) {
                print("This object is not in the cache anymore.")
                info.inCache = false
                messageCenter.showErrorMessage(TranslationUnit.getMessage(for: .CACHE_FULL_ERROR) ?? "This object will be deleted, unless you favorize it! Favorizing it causes oldest object to get deleted.")
            } else {
                messageCenter.clearMessage()
                messageCenter.clearErrorMessage()
            }
        }
        .onChange(of: messageCenter.alertMessage) { old, new in
            print("Change in messageCenter!")
            if new != nil {
                showAlert = true
                print("Showing alert is now true")
            }
        }
        .onChange(of: messageCenter.message) { new, _ in
            if new != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.messageCenter.message = nil
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Notice"),
                  message: Text(messageCenter.alertMessage ?? ""),
                  dismissButton: .default(Text("OK"), action: {
                messageCenter.alertMessage = nil
                }))
        }
    }
    
    private var mainContent: some View {
        // entire horizontal area is the selectedOption
        selectedOption.render()
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 1)
            )   
            .padding(.horizontal)
    }
    
    private var options: [any ObjectDescriptionBase] {
        info.detailedDescription.filter({ !($0 is Invisible) })
    }

    private var selectedOption: any ObjectDescriptionBase {
        options.indices.contains(selectedIndex) ? options[selectedIndex] : PlaceholderObject()
    }
}
