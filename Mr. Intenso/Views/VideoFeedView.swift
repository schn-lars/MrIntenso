import SwiftUI
import AVKit
import CoreLocation
import CodeScanner

struct ViewVisiblePreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

struct VideoFeedView: View {
    @ObservedObject var viewModel: VideoFeedViewModel
    
    @EnvironmentObject var mainViewModel: AppViewModel
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var hideButtons: Bool = false
    @State private var showSourcePick: Bool = false
    @State private var isScanning: Bool = false
    
    @EnvironmentObject var messageCenter: MessageCenter
    
    var body: some View {
        ZStack {
            /*YOLOCamera(modelPathOrName: "best", task: .segment, cameraPosition: .back)*/
            CameraViewRepresentable()
                .environmentObject(viewModel)
                .environmentObject(settings)
                .ignoresSafeArea()
            VStack(spacing: 10) {
                // MARK: Top bar with Legend & Settings
                HStack {
                    if !viewModel.legendItems.isEmpty {
                        legendView()
                    }
                }
                .padding(.horizontal)
                Spacer()
                
                // Bottom buttons & hidden message. We might even want to display inference here.
                VStack {
                    if let message = messageCenter.message, !showSourcePick {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            .transition(.opacity)
                    }
                }
                // MARK: Bottom bar
                VStack(alignment: .leading) {
                    if showSourcePick {
                        VStack(spacing: 10) {
                            Button(action: {
                                viewModel.pickImage()
                                showSourcePick = false
                            }) {
                                Image(systemName: "photo.on.rectangle")
                                    .resizable()
                                    .frame(width: 35, height: 35)
                                    .padding()
                                    .foregroundColor(Color.white)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.7))
                            )
                            .cornerRadius(12)
                            
                            Button(action: {
                                viewModel.stopVideo()
                                isScanning.toggle()
                                showSourcePick = false
                            }) {
                                Image(systemName: "qrcode.viewfinder")
                                    .resizable()
                                    .frame(width: 35, height: 35)
                                    .padding()
                                    .foregroundColor(Color.white)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.7))
                            )
                            .cornerRadius(12)
                        }
                        //.padding(.leading, 20)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .fixedSize()
                        .zIndex(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(alignment: .center) {
                    if viewModel.isFrozen {
                        let autoDownloadImage = settings.autoDownload
                        Button(action: {
                            print("Pressed Download")
                            hideButtons = true
                            viewModel.download()
                            hideButtons = false
                        }) {
                            Image(systemName: "square.and.arrow.down")
                                .resizable()
                                .frame(width: 35, height: 35)
                                .padding()
                                .foregroundColor(Color.white)
                                .opacity(!autoDownloadImage ? 1 : 0)
                            // either we want to always download the picture or the screen is frozen and we do not want auto downloads
                                .opacity(hideButtons ? 0 : 1)
                        }
                        .disabled(!(viewModel.isFrozen && !autoDownloadImage))
                        .opacity(hideButtons ? 0 : 1)
                        .cornerRadius(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.7))
                        )
                    } else {
                        Button(action: {
                            showSourcePick.toggle()
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .resizable()
                                .frame(width: 35, height: 35)
                                .padding()
                                .foregroundColor(Color.white)
                                .opacity(1)
                                .rotationEffect(showSourcePick ? Angle(degrees: 90) : .zero)
                                .animation(.easeInOut, value: showSourcePick)
                        }
                        .cornerRadius(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.7))
                        )
                    }
                    Spacer()
                    
                    // Capture-Button
                    Button(action: {
                        print("Froze Screen")
                        if !viewModel.isFrozen {
                            showSourcePick = false
                            viewModel.onFreezeScreen()
                        } else {
                            viewModel.onUnfreezeScreen()
                        }
                        viewModel.updateFreeze()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Image(systemName: viewModel.isFrozen ? "play" : "pause")
                                        .foregroundColor(Color.black)
                                        .font(.system(size: 30))
                                )
                            Circle()
                                .stroke(Color.black, lineWidth: 3)
                                .frame(width: 80, height: 80)
                        }
                    }
                    .opacity(hideButtons ? 0 : 1)
                    .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                    Button(action: {
                        print("Switched to Settings")
                        mainViewModel.navigate(to: .settings)
                    }) {
                        Image(systemName: "gearshape")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .padding()
                            .foregroundColor(Color.white)
                    }
                    .opacity(hideButtons ? 0 : 1)
                    .cornerRadius(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.7))
                    )
                }
                .padding(.horizontal)
            }
            .zIndex(3)
            .blur(radius: viewModel.showPatchNotes ? 100 : 0)
            
            // MARK: Patch-Notes
            if viewModel.showPatchNotes {
                PatchNoteView(groupedPatchNotes: viewModel.groupedPatchNodes) {
                    print("PatchnoteView dismissed")
                    viewModel.showPatchNotes = false
                    viewModel.startVideo()
                }
                .onAppear {
                    viewModel.stopVideo()
                }
            }
        }
        .onTapGesture { location in
            // https://stackoverflow.com/questions/58579495/how-to-get-local-tap-position-in-ontapgesture
            if viewModel.isFrozen {
                print("Pressed on frozen screen \(location)") // type(of: location) = CGPoint
                guard let objInfo = viewModel.clickedMask(at: location) else {
                    print("Empty object information")
                    self.messageCenter.displayMessage(for: "This is not a mask!", delay: 2.0)
                    return
                }
                if objInfo.coordinates.latitude == 0.0 && objInfo.coordinates.longitude == 0.0 {
                    let location = locationManager.location
                    objInfo.coordinates = location?.coordinate ?? CLLocationCoordinate2D()
                }
                messageCenter.clearAll()
                mainViewModel.initiateInfoRetrievalProcess(objectInformation: objInfo)
            }
        }
        .sheet(isPresented: $isScanning) {
            // https://www.hackingwithswift.com/books/ios-swiftui/scanning-qr-codes-with-swiftui
            CodeScannerView(codeTypes: [.qr], completion: handleScanner)
        }
    }
    
    private func handleScanner(result: Result<ScanResult, ScanError>) {
        isScanning = false
        switch result {
        case .success(let result):
            let uuid = result.string
            print("Scanning result is: \(uuid)")
            guard uuid.count == 36 else { return } // UUIDs are exactly 36 characters long
            mainViewModel.fetchShareRequest(uuid: uuid)
        case .failure(let error):
            print("Could not scan: \(error.localizedDescription)")
            MessageCenter.shared.displayMessage(for: error.localizedDescription, delay: 3.0)
        }
    }
    
    // MARK: ViewBuilder for the legend
    @ViewBuilder
    private func legendView() -> some View {
        let rows = calculateLegendRows()
        
        VStack(alignment: .leading, spacing: 4) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    ForEach(rows[rowIndex], id: \.key) { item in
                        HStack {
                            Rectangle()
                                .fill(Color(uiColor: item.color))
                                .frame(width: 20, height: 20)
                                .cornerRadius(4)
                            Text(item.key)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .padding(4)
                        .frame(width: item.width)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(4)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(8)
    }
    
    /**
            Used to dynamically calculate and build the new legend table which is located in the top left corner.
            BEWARE: I had to give specific names to the "rows" array, as the compiler hat problems with type checking.
     */
    private func calculateLegendRows() -> [[(key: String, color: UIColor, width: CGFloat)]] {
        typealias LegendItem = (key: String, color: UIColor, width: CGFloat)
        var currentRowWidth: CGFloat = 0
        var rows: [[LegendItem]] = [[]]
        let maxRowWidth: CGFloat = UIScreen.main.bounds.width - 32

        for item in viewModel.legendItems {
            let textWidth = item.key.widthOfString(usingFont: UIFont.systemFont(ofSize: 14)) + 36
            let legendItem: LegendItem = (key: item.key, color: item.color, width: textWidth)
            if currentRowWidth + textWidth > maxRowWidth {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.count - 1].append(legendItem)
            currentRowWidth += textWidth + 8
        }
        return rows
    }
}
