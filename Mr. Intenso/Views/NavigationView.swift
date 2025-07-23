import Foundation
import MapKit
import SwiftUI
import AVFoundation

struct NavigationTrackingMapView: UIViewRepresentable {
    let destination: Location
    @Binding var directions: MKDirections.Response?
    let onLocationUpdate: ((CLLocationCoordinate2D) -> Void)?
    let userLocation: CLLocationCoordinate2D?
    let userHeading: CLLocationDirection?
    
    @Binding var zoomToUser: Bool
    @Binding var fromDistance: Int
    
    func makeCoordinator() -> DynamicCoordinator {
        return DynamicCoordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsCompass = false
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(MKPointAnnotation.self))
        mapView.setCameraZoomRange(MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 500), animated: false) // maybe if the user cannot zoom out too much
        return mapView
    }
    
    final class TypedCircle: MKCircle {
        var color: UIColor = .black // default debug color
        
        static func with(center: CLLocationCoordinate2D, radius: CLLocationDistance, color: UIColor) -> TypedCircle {
            let circle = TypedCircle(center: center, radius: radius)
            circle.color = color
            return circle
        }
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        
        if mapView.annotations.isEmpty {
            let annotation = MKPointAnnotation()
            annotation.coordinate = destination.coordinates
            annotation.title = destination.adress
            mapView.addAnnotation(annotation)
        }
        
        if let userLocation = userLocation, let route = directions?.routes.first {
            let coords = route.polyline.coordinates
            if let splitIndex = nearestCoordinateIndex(to: userLocation, in: coords) {
                let traveledCoords = Array(coords.prefix(upTo: splitIndex + 1))
                let remainingCoords = Array(coords.suffix(from: splitIndex))

                let traveledPolyline = TravelPolyline(coordinates: traveledCoords, count: traveledCoords.count)
                let remainingPolyline = MKPolyline(coordinates: remainingCoords, count: remainingCoords.count)

                mapView.addOverlay(traveledPolyline)
                mapView.addOverlay(remainingPolyline)
            } else {
                // we need this otherwise, if the user is not near the start, then the thingy is not shown
                mapView.addOverlay(MKPolyline(coordinates: coords, count: coords.count))
            }
        }

        if let location = userLocation, zoomToUser {
            mapView.setUserTrackingMode(.none, animated: false)
            let camera = MKMapCamera(
                lookingAtCenter: location,
                fromDistance: CLLocationDistance(fromDistance),
                pitch: 0, // from above, anything else is weird
                heading: userHeading ?? 0)
            mapView.setCamera(camera, animated: true)
            mapView.setUserTrackingMode(.followWithHeading, animated: false)
            DispatchQueue.main.async {
                self.zoomToUser = false
            }
        }
    }
    
    private func nearestCoordinateIndex(to location: CLLocationCoordinate2D, in coords: [CLLocationCoordinate2D]) -> Int? {
        guard !coords.isEmpty else { return nil }
        let userLoc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        var closestIndex = 0
        var minDistance = CLLocationDistance.greatestFiniteMagnitude
        
        for (i, coord) in coords.enumerated() {
            let pointLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let distance = userLoc.distance(from: pointLoc)
            if distance < minDistance {
                minDistance = distance
                closestIndex = i
            }
        }
        return minDistance < 30 ? closestIndex : nil
    }
    
    final class TravelPolyline: MKPolyline {}

    class DynamicCoordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var parent: NavigationTrackingMapView

        init(_ parent: NavigationTrackingMapView) {
            self.parent = parent
            super.init()
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // the traveled distance by the user
            if let polyline = overlay as? TravelPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .gray
                renderer.lineWidth = 6
                return renderer
            }
            
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 6
                return renderer
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

struct NavigationMapView: UIViewRepresentable {
    let destination: Location
    @Binding var directions: MKDirections.Response?
    
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

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        // Add destination annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = destination.coordinates
        annotation.title = destination.adress
        mapView.addAnnotation(annotation)
        
        // Add polyline for directions if available
        if let routes = directions?.routes {
            for route in routes {
                mapView.addOverlay(route.polyline)
                mapView.setVisibleMapRect(route.polyline.boundingMapRect,
                                          edgePadding: UIEdgeInsets(top: 80, left: 40, bottom: 200, right: 40),
                                          animated: true)
            }
        }
    }

    func makeCoordinator() -> StaticCoordinator {
        return StaticCoordinator()
    }
    
    final class NavigationAnnotation: MKPointAnnotation {
        let destination: Location
        
        init(destination: Location) {
            self.destination = destination
        }
    }
    
    class StaticCoordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                print("Polyline count: \(polyline.pointCount)")
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// https://github.com/Kilo-Loco/MapKitTurnByTurn/tree/master

struct NavigationRouteView: View {
    let destination: Location
    @Binding var directions: MKDirections.Response?
    let onDismiss: (() -> Void)?
    let userLocation: CLLocationCoordinate2D?
    let userHeading: CLLocationDirection?
    @ObservedObject var locationManager: LocationManager
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    
    @State private var zoomToUser: Bool = false
    @State private var fromDistance: Int = 200 // Camera altitude
    @State private var expectedTravelTime = 0
    @State private var muted: Bool = false
    
    // Optional: used to track traveled path (advanced)
    @State private var traveledCoordinates: [CLLocationCoordinate2D] = []
    
    var body: some View {
        ZStack {
            NavigationTrackingMapView(
                destination: destination,
                directions: $directions,
                onLocationUpdate: nil,
                userLocation: userLocation,
                userHeading: userHeading,
                zoomToUser: $zoomToUser,
                fromDistance: $fromDistance
            )
            
            VStack {
                if let currentStep = locationManager.currentStep {
                    HStack(alignment: .top, spacing: 12) {
                        navigationSign(currentStep)
                            .padding(.top, 16)
                            .padding(.leading, 8)
                            .padding(.bottom, 16)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            let distanceString = formattedDistanceText(locationManager.currentDistanceToInstruction)
                            let fullInstruction = distanceString.isEmpty
                            ? (currentStep.instructions.isEmpty || currentStep.instructions == "" ? locationManager.currentStepInstruction : currentStep.instructions)
                            : "\(distanceString) \((currentStep.instructions.isEmpty || currentStep.instructions == "" ? locationManager.currentStepInstruction : currentStep.instructions))"
                            
                            Text(fullInstruction)
                                .font(.system(size: 20, weight: .semibold))
                                .lineLimit(2)
                            
                            if let nextStep = locationManager.nextStep {
                                let nextDistance = formattedDistanceText(nextStep.distance)
                                let nextInstruction = nextDistance.isEmpty
                                    ? nextStep.instructions
                                    : "\(nextDistance) \(nextStep.instructions)"
                                Text(nextInstruction)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 12)
                        
                        Spacer()
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 55)
                } else if locationManager.currentStepInstruction != "" {
                    HStack(alignment: .top, spacing: 12) {
                        navigationSign(locationManager.currentStepInstruction)
                            .padding(.top, 16)
                            .padding(.leading, 8)
                            .padding(.bottom, 16)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(locationManager.currentStepInstruction)
                                .font(.system(size: 20, weight: .semibold))
                                .lineLimit(2)
                        }
                        .padding(.vertical, 12)
                        
                        Spacer()
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 55)
                } else {
                    Text("Opppssssiiieeesss")
                }
            
                Spacer()
                
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Button(action: {
                            if let location = userLocation {
                                zoomToUserLocation(location)
                            }
                        }) {
                            Image(systemName: "location.viewfinder")
                                .font(.title2)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        
                        Button(action: {
                            print("Speaker")
                            muted.toggle()
                        }) {
                            Image(systemName: muted ? "speaker.slash.fill" : "speaker.wave.1")
                                .font(.title2)
                                .foregroundColor(muted ? Color.red : Color.blue)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
                
                // Bottom travel info panel
                HStack {
                    VStack(alignment: .trailing) {
                        if let firstRoute = directions?.routes.first {
                            Text("\(Int(firstRoute.expectedTravelTime / 60)) min")
                                .font(.system(size: 24))
                                .fontWeight(.bold)
                            Text(String(format: "%.1f km", firstRoute.distance / 1000))
                                .font(.system(size: 16))
                        } else {
                            Text("Loading...")
                        }
                    }
                    .padding(.leading, 20)
                    Spacer()
                    
                    Button(action: { onDismiss?() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .padding()
                            .foregroundStyle(Color.red)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(.trailing, 20)
                }
                .frame(height: 100)
                .background(.thinMaterial)
            }
        }
        .ignoresSafeArea()
        .onChange(of: locationManager.currentStepInstruction) { old, new in
            if !muted {
                print("Speaking...")
                let speechUtterance = AVSpeechUtterance(string: new)
                // speak already has a queue working behind the scenes apparently
                self.speechSynthesizer.speak(speechUtterance)
            }
        }
        .onChange(of: locationManager.currentStep) { old, new in
            if !muted {
                if let step = new {
                    let instruction = step.instructions
                    print("Speaking...")
                    let speechUtterance = AVSpeechUtterance(string: instruction)
                    // speak already has a queue working behind the scenes apparently
                    self.speechSynthesizer.speak(speechUtterance)
                }
            }
        }
    }
    
    @ViewBuilder
    private func navigationSign(_ step: MKRoute.Step) -> some View {
        Image(systemName: getNavigationSignName(instruction: step.instructions))
            .font(.system(size: 75))
            .foregroundColor(.white)
    }
    
    @ViewBuilder
    private func navigationSign(_ instruction: String) -> some View {
        Image(systemName: getNavigationSignName(instruction: instruction))
            .font(.system(size: 75))
            .foregroundColor(.white)
    }
    
    private func getNavigationSignName(instruction: String) -> String {
        let input = instruction.lowercased()
        if input.starts(with: "starten") || input.starts(with: "move towards") {
            return "location.square.fill"
        } else if input.contains("arrive") || input.contains("destination") || input.starts(with: "das ziel") {
            return "flag.pattern.checkered"
        } else if input.contains("slight left") || input.contains("leicht links") {
            return "arrow.up.backward"
        } else if input.contains("slight right") || input.contains("leicht rechts") {
            return "arrow.up.right"
        } else if input.contains("left") || input.contains("links") {
            return "arrow.backward.square"
        } else if input.contains("right") || input.contains("rechts") {
            return "arrow.forward.square"
        } else if input.contains("continue") || input.contains("straight") || input.contains("geradeaus") {
            return "arrow.up.square"
        } else if input.contains("roundabout") {
            return "arrow.counterclockwise"
        } else {
            return "questionmark.square"
        }
    }
    
    private func formattedDistanceText(_ distance: Double) -> String {
        if distance == 0.0 { 
            return ""
        } else if distance < 100 {
            return "In < 100m:"
        } else {
            let km = distance / 1000
            let roundedUp = ceil(km * 10) / 10
            return String(format: "In %.1f km:", roundedUp)
        }
    }
    
    private func zoomToUserLocation(_ coordinate: CLLocationCoordinate2D) {
        zoomToUser = true
    }
}


// https://developer.apple.com/documentation/mapkit/mklookaroundscenerequest
// https://gist.github.com/thadk/ea2e067b246b3bf7d96b94115da1f846


struct NavigationMapViewContainer: View {
    let destination: Location
    @EnvironmentObject private var locationManager: LocationManager
    @State private var directions: MKDirections.Response?
    
    @State private var showSettings: Bool = false
    @State private var showRouteTypeSelection: Bool = false
    
    @State private var showNavigation: Bool = false
    @State private var isLoading: Bool = false
    @State private var routeType: MKDirectionsTransportType = .walking
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // map
            if let userLocation = locationManager.location {
                NavigationMapView(
                    destination: destination,
                    directions: $directions
                )
                .onAppear {
                    print("User location loaded: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
                    calculateRoute(from: userLocation.coordinate, to: destination.coordinates)
                }
            } else {
                ProgressView("Loading location...")
            }
            
            // Map-type bubbled menu
            if showRouteTypeSelection {
                ForEach(RouteTypeOption.allCases, id: \.self) { option in
                    Button {
                        routeType = option.transportType
                        showRouteTypeSelection = false
                        if let userLocation = locationManager.location {
                            calculateRoute(from: userLocation.coordinate, to: destination.coordinates)
                        }
                    } label: {
                        mapTypeButton(option.icon, isActive: routeType == option.transportType)
                    }
                    .offset(option.offset)
                    .padding(.trailing, 20)
                    .padding(.bottom, 60)
                    .scaleEffect(showRouteTypeSelection ? 1 : 0.1, anchor: .bottomTrailing)
                    .opacity(showRouteTypeSelection ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showRouteTypeSelection)
                    .zIndex(10)
                }
            }
            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            print("Starting Navigation...")
                            if let firstRoute = directions?.routes.first {
                                self.locationManager.startMonitoringRouteSteps(firstRoute.steps)
                            }
                            showNavigation.toggle()
                        }
                    } label: {
                        Text("Start Navigation")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color(UIColor.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(radius: 2)
                    }
                    Spacer()
                }
                .padding(.top, 20) // adjust as needed for safe area
                Spacer()
            }
            
            // Settings vstack
            VStack(alignment: .trailing, spacing: 8) {
                if showSettings {
                    VStack(spacing: 0) {
                        // Media type selection button
                        Button {
                            withAnimation { showRouteTypeSelection.toggle() }
                        } label: {
                            settingsIcon("map.fill", isActive: showRouteTypeSelection)
                        }
                    }
                    .background(Color(UIColor.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 3)
                    .frame(width: 45)
                    .padding(.bottom, 4)
                }
                
                // Gear button for initiating the settings vstack
                HStack {
                    Button {
                        withAnimation {
                            showSettings.toggle()
                            showRouteTypeSelection = false
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
                
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showNavigation) {
            NavigationRouteView(
                destination: destination,
                directions: $directions,
                onDismiss: {
                    print("onDismiss navigationrouteview")
                    showNavigation = false
                    locationManager.stopMonitoringRouteSteps()
                },
                userLocation: locationManager.location?.coordinate,
                userHeading: locationManager.heading,
                locationManager: locationManager
            )
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
    
    private func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.requestsAlternateRoutes = false
        request.transportType = routeType

        let directionsRequest = MKDirections(request: request)
        directionsRequest.calculate { response, error in
            if let response = response {
                print("Successfully calculated route")
                self.directions = response
            } else {
                print("Route calculation failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

enum RouteTypeOption: CaseIterable {
    case walking, automobile

    var icon: String {
        switch self {
        case .automobile: return "car"
        case .walking: return "figure.walk"
        }
    }

    var transportType: MKDirectionsTransportType {
        switch self {
        case .walking: return .walking
        case .automobile: return .automobile
        }
    }

    var offset: CGSize {
        switch self {
        case .automobile: return CGSize(width: -60, height: -10)
        case .walking: return CGSize(width: -40, height: -60)
        }
    }
}
