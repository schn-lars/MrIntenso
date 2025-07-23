import SwiftUI

enum AppRoute: Hashable {
    case videoFeed
    case settings
    case detailedView(ObjectInformation, Bool)
    //case browser(URL)
}

struct ViewCoordinator: View {
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var messageCenter: MessageCenter

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            if let vm = viewModel.videoFeedViewModel {
                VideoFeedViewWrapper(vm: vm)
                    .navigationDestination(for: AppRoute.self) { route in
                        buildView(for: route)
                    }
                    .environmentObject(viewModel)
                    .environmentObject(MessageCenter.shared)
            } else {
                Text("ViewModel is nil")
            }
            
        }
        .onChange(of: viewModel.navigationPath) { old, new in
            let newCount = viewModel.navigationPath.count
            let oldCount = viewModel.previousNavigationCount

            if newCount < oldCount {
                if viewModel.geoNavigationPath.count > 0 {
                    viewModel.geoNavigationPath.removeLast()
                    if let curr = viewModel.geoNavigationPath.last {
                        viewModel.refreshLocationDescription(objectInformation: curr)
                    }
                }
            }
            
            viewModel.previousNavigationCount = newCount
        }
    }
    
    @ViewBuilder
    private func buildView(for route: AppRoute) -> some View {
        switch route {
        case .videoFeed:
            VideoFeedViewWrapper(vm: viewModel.videoFeedViewModel!)
        case .settings:
            SettingsView()
        case .detailedView(let info, let fromCache):
            DetailedObjectDescriptionView(fromCache: fromCache, info: info) {
                info.inCache = viewModel.isObjectInformationCached(objectInformation: info) // dont set true, could have been removed!
            }
        }
    }
}

struct VideoFeedViewWrapper: View {
    @ObservedObject var vm: VideoFeedViewModel
    @State private var isVisible: Bool = false

    var body: some View {
        ZStack {
            if vm.isReady {
                VideoFeedView(viewModel: vm)
            } else {
                LoadingScreen()
            }
        }
    }
}
