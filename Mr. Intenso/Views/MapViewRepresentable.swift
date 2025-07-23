import Foundation
import MapKit
import SwiftUI

/**
 
 https://developer.apple.com/documentation/mapkit/decluttering-a-map-with-mapkit-annotation-clustering
 
 Realistic buildings
 https://medium.com/ciandt-techblog/whats-new-in-mapkit-an-overview-of-the-latest-advancements-da248f385e97
 
 */
struct ClusteredMapView: UIViewRepresentable {
    @Binding var selectedObjects: [ObjectInformation]?
    let similarObjects: [ObjectInformation]
    
    let mapType: MKMapType
    let showsBuildings: MKMapConfiguration.ElevationStyle
    let userTrackingMode: MKUserTrackingMode
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(MKPointAnnotation.self))
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Cluster")
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow // this sets the map initially to the user's position
        mapView.pointOfInterestFilter = .excludingAll
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .default)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)

        let annotations = similarObjects.map { object -> ObjectAnnotation in
            let annotation = ObjectAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: object.coordinates.latitude, longitude: object.coordinates.longitude)
            annotation.title = object.object
            annotation.object = object
            return annotation
        }
        uiView.addAnnotations(annotations)
        
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
    
    /**
            This class is needed to give additional information to the user. Currently it is used to mark a glyph yellow if within a cluster a favorite object exists.
     */
    final class ObjectAnnotation: MKPointAnnotation {
        var object: ObjectInformation?
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ClusteredMapView
        
        init(_ parent: ClusteredMapView) {
            self.parent = parent
        }
        
        
        /**
                This method basically provides the frame which is being displayed. It does so by checking the annotations and building them as I configured.
                Yellow annotations are either clutsers with at least one favorite contained in them or one single favorite. Otherwise we color them blue.
                The body of each annotation is the count of how many objects were located there.
         */
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let cluster = annotation as? MKClusterAnnotation {
                let view = MKMarkerAnnotationView(annotation: cluster, reuseIdentifier: "Cluster")
                
                let containsFavorite = cluster.memberAnnotations.contains {
                    guard let objectAnnotation = $0 as? ObjectAnnotation else { return false }
                    return objectAnnotation.object?.favourite ?? false
                }
                
                let containsShared = cluster.memberAnnotations.contains {
                    guard let objectAnnotation = $0 as? ObjectAnnotation else { return false }
                    return objectAnnotation.object?.shared ?? false
                }
                
                if containsFavorite && containsShared {
                    view.markerTintColor = .systemOrange
                } else if containsFavorite {
                    view.markerTintColor = .yellow
                } else if containsShared {
                    view.markerTintColor = .red
                } else {
                    view.markerTintColor = .blue
                }
                view.glyphText = "\(cluster.memberAnnotations.count)" // body of the marker shows count
                return view
            }
            guard let objectAnnotation = annotation as? ObjectAnnotation else { return nil }
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: NSStringFromClass(MKPointAnnotation.self))
            view.canShowCallout = true
            let isFavorite = objectAnnotation.object?.favourite ?? false
            let isShared = objectAnnotation.object?.shared ?? false
            
            if isFavorite && isShared {
                view.markerTintColor = .systemOrange
            } else if isFavorite {
                view.markerTintColor = .yellow
            } else if isShared {
                view.markerTintColor = .red
            } else {
                view.markerTintColor = .blue
            }
            
            view.glyphText = "1"
            view.clusteringIdentifier = "objectCluster"
            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let cluster = view.annotation as? MKClusterAnnotation {
                // Multiple objects selected
                print("Selected a cluster with \(cluster.memberAnnotations.count) items")
                var selected: [ObjectInformation] = []
                for member in cluster.memberAnnotations { // iterate over all annotations to retrieve the matching object
                    guard let objectAnnotation = member as? ObjectAnnotation,
                          let objectInformation = objectAnnotation.object else {
                        continue
                    }
                    selected.append(objectInformation)
                }
                parent.selectedObjects = selected
            } else if let objectAnnotation = view.annotation as? ObjectAnnotation {
                // Single object selected
                print("Selected single annotation")
                if let object =  objectAnnotation.object {
                    parent.selectedObjects = [object]
                }
            }
        }
    }
}

//    MARK: Main Map-Container
/**
    This struct is basically responsible for coordinating the Map as well as navigation to the listview (.sheet)
 */

struct ObjectMapViewContainer: View {
    let similarObjects: [ObjectInformation]
    @State private var selectedList: ObjectSelectionList?
    @State var isPresented: Bool = false
    
    // Settings
    @State private var trackingMode: MKUserTrackingMode = .none
    @State private var mapType: MKMapType = .standard
    @State private var showsBuildings: MKMapConfiguration.ElevationStyle = .flat
    
    @State private var showSettings: Bool = false
    @State private var showMapTypeSelection: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // map
            ClusteredMapView(
                selectedObjects: Binding(
                    get: { selectedList?.objects },
                    set: { newValue in
                        if let value = newValue {
                            selectedList = ObjectSelectionList(objects: value)
                        } else {
                            selectedList = nil
                        }
                    }
                ),
                similarObjects: similarObjects,
                mapType: mapType,
                showsBuildings: showsBuildings,
                userTrackingMode: trackingMode
            )
            .sheet(item: $selectedList) { item in
                ObjectListView(objects: item.objects) {
                    selectedList = nil
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
                    .padding(.bottom, 150)
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

struct ObjectSelectionList: Identifiable {
    let id = UUID()
    let objects: [ObjectInformation]
}

enum MapTypeOption: CaseIterable {
    case standard, satellite, hybrid

    var icon: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe.americas.fill"
        case .hybrid: return "square.3.stack.3d.top.filled"
        }
    }

    var mapType: MKMapType {
        switch self {
        case .standard: return .standard
        case .satellite: return .satellite
        case .hybrid: return .hybrid
        }
    }

    var offset: CGSize {
        switch self {
        case .standard: return CGSize(width: -60, height: -10)
        case .satellite: return CGSize(width: -40, height: -60)
        case .hybrid: return CGSize(width: 10, height: -60)
        }
    }
}

// MARK: view after selecting an annotation
struct ObjectListView: View {
    let objects: [ObjectInformation]
    let onDismiss: () -> Void
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        NavigationView {
            List(objects, id: \.id) { object in
                HStack {
                    if let image = object.image {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 100, height: 100)
                            .cornerRadius(6)
                    } else {
                        Color.gray
                            .frame(width: 100, height: 100)
                            .cornerRadius(6)
                    }
                    
                    Spacer()

                    Text(DateFormatter.localizedString(
                        from: Date(timeIntervalSince1970: TimeInterval(object.lastSpotted)),
                        dateStyle: .medium,
                        timeStyle: .short
                        )
                    )
                    
                    Spacer()
                    
                    Image(systemName: object.favourite ? "star.fill" : "star")
                        .foregroundColor(object.shared ? .red : (object.favourite) ? .yellow : .gray)
                        .font(.system(size: 25))
                }
                .onTapGesture {
                    print("Pressed \(object.id)")
                    appViewModel.geoNavigate(to: object, fromCache: true) // those are cached objects which are being displayed!
                    onDismiss()
                }
            }
            .navigationTitle("Selected Objects")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        // Dismisses automatically via sheet binding reset
                        // https://developer.apple.com/documentation/swiftui/view/sheet(item:ondismiss:content:)
                        onDismiss()
                    }
                }
            }
        }
    }
}
