import SwiftUI

@main
struct Mr__IntensoApp: App {
    @StateObject private var viewModel = AppViewModel()
    @StateObject var settings = Settings()

    @StateObject var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            ViewCoordinator()
                .environmentObject(viewModel)
                .environmentObject(settings) // everyone should be able to see this boi
                .environmentObject(locationManager)
                .environmentObject(MessageCenter.shared) 
                .onAppear {
                    viewModel.initialize(with: settings, locationManager: locationManager) // this method is being executed immediately if app is started. This is crucial as per se the variables are created lazily
                    // maybe set model initializer here as well
                    print("Done initializing")
                }
        }
    }
}
