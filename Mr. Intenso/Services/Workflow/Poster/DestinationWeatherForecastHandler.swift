import Foundation
import CoreLocation
import WeatherKit

class DestinationWeatherForecastHandler: WorkflowHandler {
    var nextWorkflowHandler: (any WorkflowHandler)?
    
    var description: String = TranslationUnit.getMessage(for: .DESTINATION_WEATHER_TITLE) ?? "Weather at Destination"
    
    func process(_ input: Any, completion: @escaping (WorkflowResult) -> Void) {
        guard let object = input as? ObjectInformation else {
            print("DestinationWeatherForecastHandler: Input was of type \(type(of: input))")
            completion(.failure("DestinationWeatherForecastHandler: Input was of type \(type(of: input))"))
            return
        }
        
        guard let locationObject = object.detailedDescription.first(where: { $0 is LocationObject }) as? LocationObject else {
            print("DestinationWeatherForecastHandler: There has not been any location found to this object!")
            completion(.failure("DestinationWeatherForecastHandler: There has not been any location found to this object!"))
            return
        }
        
        print("DestinationWeatherForecastHandler: Starting...")
        /// Do not use current location, but rather the location of the passed object.
        /// If it is a shared object, then our location might not play a role at all.
        /// Think of: LocationObject + DateObject -> we want forecast for this if not too far in advance
        let location = CLLocation(
            latitude: locationObject.location.coordinates.latitude,
            longitude: locationObject.location.coordinates.longitude
        )
        
        let objectLocation = CLLocation(
            latitude: object.coordinates.latitude,
            longitude: object.coordinates.longitude
        )
        
        getCityName(location: objectLocation) { result in
            if let city = result {
                if city == locationObject.location.city {
                    print("The cities match! No need to add object.")
                    completion(.failure("The cities match! No need to add object."))
                    return
                } else {
                    Task { // allows us to call async function from synchronous environment
                        let weather = try? await self.getWeather(location: location)
                        if let weather {
                            completion(.success(weather))
                        } else {
                            completion(.failure("WeatherForecastHandler: Failed to fetch weather"))
                        }
                    }
                }
            } else {
                print("Could not extract city name.")
                completion(.failure("Could not extract city name."))
                return
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
    
    private func getCityName(location: CLLocation, completion: @escaping (String?) -> Void) {
        guard var components = URLComponents(string: "https://myurl.com/city") else {
            print("WeatherObject: Unable to create URLComponents.")
            completion(nil)
            return
        }
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "long", value: String(location.coordinate.longitude))
        ]
        
        guard let url = components.url else {
            print("WeatherObject: Unable to create URL.")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data")
                completion(nil)
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
                if let city = jsonResponse?["city"] as? String {
                    print("WeatherObject: Successfully found city: \(city)")
                    completion(city)
                } else {
                    print("WeatherObject: Unable to retrieve city name")
                    completion(nil)
                }
            } catch {
                print("WeatherObject: JSON-Serialization failed: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }
}
