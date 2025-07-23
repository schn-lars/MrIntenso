import Foundation
import AVFoundation
import Combine

/**
    This component is responsible for starting and stopping the information retrieval unit.
 */

class InformationRetrievalUnit {
    var locationManager: LocationManager
    var settings: Settings
    var generalManager: GeneralObjectManager?
    var appendingManager: ShoppingManager?
    var sharedGeneralManager: GeneralObjectManager?
    private var cancellables = Set<AnyCancellable>()
    
    init(locationManager: LocationManager, settings: Settings) {
        print("Initializing InformationRetrievalUnit")
        self.locationManager = locationManager
        self.settings = settings
        
        settings.$apiKey
            .compactMap { $0 }
            .first() // i think if we remove this, we can do this anytime it changes
            .sink { [weak self] key in
                print("API key received: \(key)")
                self?.initializeGeneralManager(with: key)
            }
            .store(in: &cancellables)
    }
    
    private func initializeGeneralManager(with key: String) {
        // general: reverseSearch, audio
        var reverseSearchHandler = ImageUploadHandler()
        reverseSearchHandler.nextWorkflowHandler = ReverseImageSearchHandler(apikey: key)
        reverseSearchHandler.nextWorkflowHandler?.nextWorkflowHandler = ReverseImageResultHandler()
        self.generalManager = GeneralObjectManager(
            parallelJobs: [
                reverseSearchHandler,
                MusicRecognitionHandler(),
                WeatherForecastHandler(),
                WikipediaPageHandler()
            ]
        )
        self.appendingManager = ShoppingManager()
        appendingManager?.head = ShoppingItemHandler(apikey: key)
        self.generalManager?.next = appendingManager
        
        // shared
        self.sharedGeneralManager = GeneralObjectManager(parallelJobs: [
            WeatherForecastHandler(),
            DestinationWeatherForecastHandler()
        ])
    }
    
    func triggerSharedInfoRetrievalProcess(
        objectInformation: ObjectInformation,
        completion: @escaping (ObjectInformation) -> Void
    ) {
      // here we have to fetch the data which is more dynamic (f.e. Shopping)
        let element = objectInformation.object
        print("\(element): InformationRetrievalUnit - triggerSharedInformationRetrieval")
        switch element {
        case "laptop":
            // Here we need to add the ShoppingManager which fetches dynamic shopping data
            objectInformation.handlerCount = sharedGeneralManager?.getHandlerCount()
            sharedGeneralManager?.processObject(information: objectInformation) { result in
                completion(result)
            }
        default:
            print("TriggerSharedInformationRetrievalProcess: No dynamic information retrieval for \(element)")
            objectInformation.handlerCount = sharedGeneralManager?.getHandlerCount()
            sharedGeneralManager?.processObject(information: objectInformation) { result in
                completion(result)
            }
        }
    }
    
    func triggerRetrieval(objectInformation: ObjectInformation, completion: @escaping (ObjectInformation) -> Void) {
        //let element = "poster" // THIS IS FOR DEBUGGING, MAKES THINGS EASIER TO TEST
        let element = objectInformation.object
        print("Retrieving \(element) information...")
        switch element {
        case "bird":
            let entryManager = AnimalResourcesManager(parallelJobs: [AnimalLostWebHandler()])
            let classifierManager = BirdClassificationManager()
            entryManager.next = classifierManager
            classifierManager.next = BirdInformationRetrievalManager(parallelJobs:
                [BirdDatabaseHandler(locationManager: locationManager),
                 WebPageHandler()
                ])
            appendingManager?.next = entryManager
            objectInformation.handlerCount = appendingManager?.getHandlerCount()
            appendingManager?.processObject(information: objectInformation) { result in
                completion(result)
                self.appendingManager?.next = nil
            }
        case "person":
            let manager = TestSerialManager()
            appendingManager?.next = manager
            objectInformation.handlerCount = generalManager?.getHandlerCount()
            generalManager?.processObject(information: objectInformation) { result in
                completion(result)
                self.appendingManager?.next = nil
            }
        case "poster":
            let thirdManager = PosterDateExtractionManager(parallelJobs: [
                PosterDateExtractionHandler(),
                DestinationWeatherForecastHandler()
            ])
            
            let secondJobs: [any WorkflowHandler] = [PosterTextWebsiteExtractorHandler(), PosterTextAdressExtractorHandler()]
            let secondManager = PosterTextContentExtractionManager(
                parallelJobs: secondJobs,
                next: thirdManager
            )
            let extractionJobs: [any WorkflowHandler] = [
                QRCodeDetectorHandler(),
                PosterTextExtractionHandler()
            ]
            let manager = PosterContentExtractionManager(parallelJobs: extractionJobs)
            manager.next = secondManager
            appendingManager?.next = manager
            objectInformation.handlerCount = generalManager?.getHandlerCount()
            generalManager?.processObject(information: objectInformation) { result in
                completion(result)
                self.appendingManager?.next = nil
            }
        case "cat", "dog":
            let manager = AnimalResourcesManager(parallelJobs: [AnimalLostWebHandler()])
            appendingManager?.next = manager
            objectInformation.handlerCount = generalManager?.getHandlerCount()
            generalManager?.processObject(information: objectInformation) { result in
                completion(result)
                self.appendingManager?.next = nil
            }
        case "laptop":
            objectInformation.handlerCount = generalManager?.getHandlerCount()
            generalManager?.processObject(information: objectInformation) { result in
                completion(result)
            }
        default:
            objectInformation.handlerCount = generalManager?.getHandlerCount()
            generalManager?.processObject(information: objectInformation) { result in
                completion(result)
            }
        }
    }
}
