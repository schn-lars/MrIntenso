import Foundation
import CoreLocation
import MapKit
import AVFoundation

/**
    This document contains all Location-depedent logic for the application. It also handles navigation for the navigation-object.
 */

// https://holyswift.app/the-new-way-to-get-current-user-location-in-swiftu-tutorial/

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation? = nil
    @Published var heading: CLLocationDirection? = nil
    
    @Published var nextStep: MKRoute.Step? = nil
    
    @Published var currentStepInstruction: String = "Move towards the start."
    @Published var currentStep: MKRoute.Step? = nil
    @Published var currentDistanceToInstruction: Double = 0
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let locationManager = CLLocationManager()
    
    private let stepsToLookAhead: Int = 5 // CLLocationManager is limited to 20 regions to be monitored
    private var monitoredStepIndex: Int = 0
    private var allSteps: [MKRoute.Step] = []
    private var monitoredRegions: [CLCircularRegion] = []
    private var hasEnteredCurrentStep = false
    private var currentStepRegionIdentifier: String?
    private var hasRequestedInitialRegionState: Bool = false
    
    override init() {
        super.init()
        resetLocationMonitoringOnAppLaunch()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // only update every 10 meters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        HTMLRetrieverService.shared.sendDebugLog("Initiated location manager")
    }
    
    // MARK: Reset
    private func resetLocationMonitoringOnAppLaunch() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        monitoredRegions.removeAll()
        monitoredStepIndex = 0
        allSteps.removeAll()
        currentStep = nil
        nextStep = nil
        hasRequestedInitialRegionState = false
        currentStepInstruction = "Move towards the start."
        currentDistanceToInstruction = 0.0
        hasEnteredCurrentStep = false
        //HTMLRetrieverService.shared.sendDebugLog("Reset location monitoring due to cold start or crash recovery.")
    }
    
    // MARK: Location-Updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.location = location
            if let currentStep = self.currentStep {
                let currentStepLocation = CLLocation(
                    latitude: currentStep.polyline.coordinates.last?.latitude ?? currentStep.polyline.coordinate.latitude,
                    longitude: currentStep.polyline.coordinates.last?.longitude ?? currentStep.polyline.coordinate.longitude
                )
                self.currentDistanceToInstruction = currentStepLocation.distance(from: location)
                
                if self.hasEnteredCurrentStep && (self.currentDistanceToInstruction > 40 || self.monitoredStepIndex == 0) {
                    //HTMLRetrieverService.shared.sendDebugLog("Manually triggered step transition after exiting current step.")
                    self.advanceToNextStep()
                }
            }
        }
    }
    
    /**
            This function is called, when the user has been at the step but has moved away now.
     */
    // MARK: advancing to next step
    private func advanceToNextStep() {
        //HTMLRetrieverService.shared.sendDebugLog("LocationManager: AdvanceToNextStep")
        hasEnteredCurrentStep = false
        let identifier = currentStepRegionIdentifier
        currentStepRegionIdentifier = nil

        if let visitedStep = monitoredRegions.first(where: { $0.identifier == identifier }) {
            locationManager.stopMonitoring(for: visitedStep)
            monitoredRegions.removeAll { $0.identifier == identifier }
            monitoredStepIndex += 1
            monitorNextSteps()
        }
        
        //HTMLRetrieverService.shared.sendDebugLog("AdvancedToNextStep: Set currentStep for index \(self.monitoredStepIndex)")
        DispatchQueue.main.async {
            self.currentStep = self.nextStep
            self.currentDistanceToInstruction = self.currentStep?.distance ?? 0.0
            self.nextStep = self.allSteps[safe: self.monitoredStepIndex + 1]
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = newHeading.trueHeading
        }
        // TODO: ETA can be done here as well i think
    }
    
    /**
            This method is needed for the start, as didEnter will not trigger, if the user is already inside.
     */
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if state == .inside {
            if region.identifier.split(separator: ":").first == "0" && !hasEnteredCurrentStep {
                //HTMLRetrieverService.shared.sendDebugLog("didDetermineState: We are already inside \(region.identifier)")
                hasEnteredCurrentStep = true
                self.locationManager(manager, didEnterRegion: region)
            }
        }
    }
    
    func startMonitoringRouteSteps(_ steps: [MKRoute.Step]) {
        //HTMLRetrieverService.shared.sendDebugLog("LocationManager: Start monitoring... Number of steps: \(steps.count)")
        allSteps = steps
        
        guard let start = allSteps.first else { return }
        DispatchQueue.main.async {
            self.currentStep = start
            self.nextStep = self.allSteps[safe: 1]
        }
        locationManager.requestLocation() // because of refreshing of currentDistanceToInstruction
        
        // Add destination Circle manually
        guard let goal = allSteps.last else { return }
        let center = goal.polyline.coordinates.last ?? goal.polyline.coordinate
        let goalRegion = DestinationCircularRegion(
                            center: center,
                            radius: 20,
                            identifier: "\(allSteps.count - 1):\(goal.instructions)"
                        )
        goalRegion.notifyOnEntry = true
        goalRegion.notifyOnExit = false
        monitoredRegions.append(goalRegion)
        locationManager.startMonitoring(for: goalRegion)
        
        monitoredStepIndex = 0
        monitorNextSteps()
        
        if let initialMessage = steps.first?.instructions {
            print("About to speak initial message. \(initialMessage)")
            let speechUtterance = AVSpeechUtterance(string: initialMessage)
            self.speechSynthesizer.speak(speechUtterance)
        }
    }
    
    // MARK: Monitoring next step
    private func monitorNextSteps() {
        //HTMLRetrieverService.shared.sendDebugLog("MonitorNextSteps: With index \(self.monitoredStepIndex)")
        // This is being called after the second to last region has been exited. We want to skip this.
        if monitoredStepIndex == allSteps.count { return }
        let maxSteps = min(monitoredStepIndex + stepsToLookAhead, allSteps.count - 1) // we do not want goal to be added here
        
        for i in monitoredStepIndex..<maxSteps {
            let step = allSteps[i]
            let center = step.polyline.coordinates.last ?? step.polyline.coordinate
            let region = StepCircularRegion(center: center, radius: 40, identifier: "\(i):\(step.instructions)")
            region.notifyOnEntry = true
            region.notifyOnExit = false
            if i == monitoredStepIndex {
                currentStepRegionIdentifier = region.identifier
            }
            monitoredRegions.append(region)
            locationManager.startMonitoring(for: region)
            
            if monitoredStepIndex == 0 && i == 0 && !hasRequestedInitialRegionState {
                //HTMLRetrieverService.shared.sendDebugLog("MonitorNextSteps: Requesting state for \(self.monitoredStepIndex)")
                hasRequestedInitialRegionState = true
                locationManager.requestState(for: region)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //HTMLRetrieverService.shared.sendDebugLog("LocationManager: Failed to get location: \(error.localizedDescription)")
    }
    
    /**
            This function stop monitoring of all currently monitored regions for navigation.
            If you want to add functionality of geo-fencing, this is still possible, as they will not be removed.
     */
    func stopMonitoringRouteSteps() {
        //HTMLRetrieverService.shared.sendDebugLog("LocationManager: Stopping monitoring...")
        for region in monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        monitoredRegions.removeAll()
        
        DispatchQueue.main.async {
            self.allSteps.removeAll()
            self.currentStepInstruction = "Move towards the start."
            self.currentStep = nil
            self.nextStep = nil
            self.currentDistanceToInstruction = 0.0
            self.monitoredStepIndex = 0
            self.currentStepRegionIdentifier = nil
            self.hasEnteredCurrentStep = false
            self.hasRequestedInitialRegionState = false
        }
    }
    
    private func reachedDestination() {
        //HTMLRetrieverService.shared.sendDebugLog("LocationManager: ReachedDestination...")
        for region in monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        monitoredRegions.removeAll()
        
        DispatchQueue.main.async {
            self.allSteps.removeAll()
            self.currentStep = nil
            self.nextStep = nil
            self.currentDistanceToInstruction = 0.0
            self.monitoredStepIndex = 0
            self.currentStepRegionIdentifier = nil
            self.hasEnteredCurrentStep = false
            self.hasRequestedInitialRegionState = false
        }
    }

    /**
            I want to register once a goal is entered.
     */
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // CAUTION: Apple drops custom type of region. It will always be of CLRegion
        //HTMLRetrieverService.shared.sendDebugLog("LocationManager: didEnterRegion \(region.identifier)")
        guard let stepString = region.identifier.split(separator: ":").first,
            let stepInt = Int(stepString) else {
            //HTMLRetrieverService.shared.sendDebugLog("LocationManager: Could not extract step for \(region.identifier)")
            return
        }
        
        if stepInt == allSteps.count - 1 {
            // We have reached the goal
            //HTMLRetrieverService.shared.sendDebugLog("LocationManager: didEnterRegion as goalRegion for \(region.identifier)")
            DispatchQueue.main.async {
                self.currentStepInstruction = "You have reached your destination!"
            }
            locationManager.stopMonitoring(for: region)
            reachedDestination()
        } else {
            // Intermediate step
            if region.identifier == currentStepRegionIdentifier {
                hasEnteredCurrentStep = true
                if monitoredStepIndex == 0 {
                    advanceToNextStep()
                }
                //HTMLRetrieverService.shared.sendDebugLog("Entered current step region: \(region.identifier)")
            } else {
                print("Entered non-current step region: \(region.identifier)")
                //HTMLRetrieverService.shared.sendDebugLog("Entered non-current step region: \(region.identifier)")
            }
        }
    }
}

final class DestinationCircularRegion: CLCircularRegion {}
final class StepCircularRegion: CLCircularRegion {}
