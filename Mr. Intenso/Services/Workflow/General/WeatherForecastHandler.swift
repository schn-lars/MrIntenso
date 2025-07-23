import Foundation
import CoreLocation
import WeatherKit

class WeatherForecastHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    var description: String = TranslationUnit.getMessage(for: .WEATHER_TITLE) ?? "Weather"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        guard let object = input as? ObjectInformation else {
            print("WeatherForecastHandler: Input was of type \(type(of: input))")
            completion(.failure("WeatherForecastHandler: Input was of type \(type(of: input))"))
            return
        }
        print("WeatherForecastHandler: Starting...")
        /// Do not use current location, but rather the location of the passed object.
        /// If it is a shared object, then our location might not play a role at all.
        /// Think of: LocationObject + DateObject -> we want forecast for this if not too far in advance
        let location = CLLocation(
            latitude: object.coordinates.latitude,
            longitude: object.coordinates.longitude
        )
        
        Task { // allows us to call async function from synchronous environment
            let weather = try? await getWeather(location: location)
            if let weather {
                completion(.success(weather))
            } else {
                completion(.failure("WeatherForecastHandler: Failed to fetch weather"))
            }
        }
    }
    
    private func getWeather(location: CLLocation) async throws -> Weather? {
        do {
            let weather = try await WeatherService.shared.weather(
                for: location
            )
            return weather
        } catch {
            print("WeatherForecastHandler: Error in getWeather \(error.localizedDescription)")
            return nil
        }
    }
}
