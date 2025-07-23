import Foundation
import MapKit
import SwiftUI

struct LocationMapView: UIViewRepresentable {
    let location: Location
    
    let mapType: MKMapType
    let showsBuildings: MKMapConfiguration.ElevationStyle
    let userTrackingMode: MKUserTrackingMode
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(MKPointAnnotation.self))
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Cluster")
        
        mapView.showsUserLocation = true
        mapView.pointOfInterestFilter = .excludingAll
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .default)
        
        let coordinate = CLLocationCoordinate2D(
            latitude: location.coordinates.latitude,
            longitude: location.coordinates.longitude
        )
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        DispatchQueue.main.async {
            mapView.setRegion(region, animated: false)
        }
        mapView.userTrackingMode = .none // this sets the map initially to the user's position
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        let annotation = LocationAnnotation(location: location)
        annotation.coordinate = location.coordinates
        annotation.title = location.adress
        uiView.addAnnotation(annotation)
        
        // We need different configurations as most defaults are deprecated
        switch mapType {
        case .standard:
            let config = MKStandardMapConfiguration(elevationStyle: showsBuildings, emphasisStyle: .default)
            uiView.preferredConfiguration = config
        case .satellite, .hybrid:
            let config = MKImageryMapConfiguration(elevationStyle: showsBuildings)
            uiView.preferredConfiguration = config
        default:
            uiView.mapType = mapType
        }

        if uiView.userTrackingMode != userTrackingMode {
            uiView.userTrackingMode = userTrackingMode
        }

        // Camera needs angle for 3D effect
        let camera = uiView.camera
        camera.pitch = (showsBuildings == .realistic) ? 60 : 0
        uiView.setCamera(camera, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class LocationAnnotation: MKPointAnnotation {
        let location: Location
        
        init(location: Location) {
            self.location = location
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: LocationMapView
        
        init(_ parent: LocationMapView) {
            self.parent = parent
        }
        
        
        /**
                This method basically provides the frame which is being displayed. It does so by checking the annotations and building them as I configured.
                Yellow annotations are either clutsers with at least one favorite contained in them or one single favorite. Otherwise we color them blue.
                The body of each annotation is the count of how many objects were located there.
         */
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? LocationAnnotation else { return nil }
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: NSStringFromClass(MKPointAnnotation.self))
            view.canShowCallout = true
            view.markerTintColor = .red
            view.glyphImage = UIImage(systemName: "mappin.circle")
            view.clusteringIdentifier = "objectCluster"
            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        }
    }
}

// https://developer.apple.com/documentation/mapkit/mklookaroundscenerequest
// https://gist.github.com/thadk/ea2e067b246b3bf7d96b94115da1f846

/**
 
        This struct displays the lookaround-view (like google-StreetView but without the need for API key)
 
 */
struct LookAroundView: UIViewControllerRepresentable {
    let coordinate: CLLocationCoordinate2D
    
    func makeUIViewController(context: Context) -> MKLookAroundViewController {
        let vc = MKLookAroundViewController()
        let sceneRequest = MKLookAroundSceneRequest(coordinate: coordinate)

        sceneRequest.getSceneWithCompletionHandler() { scene, error in
            if let scene = scene {
                DispatchQueue.main.async {
                    vc.scene = scene
                }
            } else {
                print("No Look Around scene available: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MKLookAroundViewController, context: Context) {}
}

struct LocationMapViewContainer: View {
    let location: Location
    
    @State private var trackingMode: MKUserTrackingMode = .none
    @State private var mapType: MKMapType = .standard
    @State private var showsBuildings: MKMapConfiguration.ElevationStyle = .flat
    
    @State private var showSettings: Bool = false
    @State private var showMapTypeSelection: Bool = false
    
    @State private var showLookAroundScene: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // map
            LocationMapView(
                location: location,
                mapType: mapType,
                showsBuildings: showsBuildings,
                userTrackingMode: trackingMode
            )
            // We use a fullScreenCover, as with .sheet() it resulted in the navigationStack re-rendering
            // which caused the inference to start in the background, eventho the view was not present.
            // Did not find a solution to fix that. Consider this a bandaid for the issue. Stay healthy.
            .fullScreenCover(isPresented: $showLookAroundScene) {
                ZStack(alignment: .topTrailing) {
                    LookAroundView(coordinate: location.coordinates)

                    Button(action: {
                        showLookAroundScene = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }
            // Map-type bubbled menu
            if showMapTypeSelection {
                ForEach(MapTypeOption.allCases, id: \.self) { option in
                    Button {
                        mapType = option.mapType
                        showMapTypeSelection = false
                    } label: {
                        mapTypeButton(option.icon, isActive: mapType == option.mapType)
                    }
                    .offset(option.offset)
                    .padding(.trailing, 20)
                    .padding(.bottom, 190)
                    .scaleEffect(showMapTypeSelection ? 1 : 0.1, anchor: .bottomTrailing)
                    .opacity(showMapTypeSelection ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showMapTypeSelection)
                    .zIndex(10)
                }
            }

            // Settings vstack
            VStack(alignment: .trailing, spacing: 8) {
                if showSettings {
                    VStack(spacing: 0) {
                        // Media type selection button
                        Button {
                            withAnimation { showMapTypeSelection.toggle() }
                        } label: {
                            settingsIcon("map.fill", isActive: showMapTypeSelection)
                        }
                        Divider().background(Color.gray.opacity(0.6))
                        
                        // Follow-user button
                        Button {
                            trackingMode = (trackingMode == .follow ? .none : .follow)
                        } label: {
                            settingsIcon("location.fill", isActive: trackingMode == .follow)
                        }
                        Divider().background(Color.gray.opacity(0.6))
                        
                        // Binoculars button for streetview
                        Button {
                            showLookAroundScene.toggle()
                        } label: {
                            settingsIcon("binoculars", isActive: showLookAroundScene)
                        }
                        
                        Divider().background(Color.gray.opacity(0.6))

                        // 3D buildings toggle
                        Button {
                            showsBuildings = (showsBuildings == .flat ? .realistic : .flat)
                        } label: {
                            settingsIcon("view.3d", isActive: (showsBuildings == .realistic))
                        }
                    }
                    .background(Color(UIColor.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 3)
                    .frame(width: 45)
                    .padding(.bottom, 4)
                }

                // Gear button for initiating the settings vstack
                Button {
                    withAnimation {
                        showSettings.toggle()
                        showMapTypeSelection = false
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(Color(UIColor.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(radius: 2)
                }
            }
            .padding()
        }
    }
    
    // MARK: Helper methods to build UI-components.
    @ViewBuilder
    private func settingsIcon(_ systemName: String, isActive: Bool) -> some View {
        Image(systemName: systemName)
            .font(.title3)
            .foregroundColor(isActive ? .blue : .primary)
            .frame(width: 40, height: 40)
    }
    
    @ViewBuilder
    private func mapTypeButton(_ systemName: String, isActive: Bool) -> some View {
        Image(systemName: systemName)
            .font(.title3)
            .foregroundColor(isActive ? .blue : .primary)
            .frame(width: 40, height: 40)
            .background(Color(UIColor.systemGray6))
            .clipShape(Circle())
            .shadow(radius: 2)
    }
}

