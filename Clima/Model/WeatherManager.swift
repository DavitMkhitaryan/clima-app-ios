//
//  WeatherManager.swift
//  Clima
//
//  Created by Davit Mkhitaryan on 20.09.23.
//  Copyright © 2023 App Brewery. All rights reserved.
//

import Foundation
import CoreLocation

struct WeatherManager {
            
    var delegate: WeatherManagerDelegate?
    
    func fetchWeather(cityName: String) {
        let weatherURL = getWeatherURL()
        let urlString = "\(weatherURL)&q=\(cityName)"
        performRequest(with: urlString)
    }
    
    func fetchWeather(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let weatherURL = getWeatherURL()
        let urlString = "\(weatherURL)&lat=\(latitude)&lon=\(longitude)"
        self.delegate?.updateWeatherInProgress(self)
        performRequest(with: urlString)
    }
    
    func performRequest(with urlString: String) {
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { (data, response, error) in
                
                if error != nil {
                    self.delegate?.didFailWithError(error: error!)
                    return
                }
                
                if let safeData = data {
                    if let weather = self.parseJSON(safeData) {
                        self.delegate?.didUpdateWeather(self, weather: weather)
                    }
                }
            }
            task.resume()
        }
    }
    
    func parseJSON(_ weatherData: Data) -> WeatherModel? {
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(WeatherData.self, from: weatherData)
            let id = decodedData.weather[0].id
            let temp = decodedData.main.temp
            let name = decodedData.name
            
            let weather = WeatherModel(conditionId: id, cityName: name, temperature: temp)
            return weather
        } catch {
            self.delegate?.didFailWithError(error: error)
            return nil
        }
    }
    
    func getApiKey() -> String? {
        if let path = Bundle.main.path(forResource: "keys", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
            
            // Access the value for the WEATHER_API_KEY key
            if let weatherAPIKey = dict["WEATHER_API_KEY"] as? String {
                // Now you have the API key as a string
                print("Weather API Key: \(weatherAPIKey)")
                return weatherAPIKey
                
                // You can use the weatherAPIKey variable in your code here
            } else {
                // Handle the case where the key doesn't exist or the value is not a string
                print("Weather API Key not found or not a string")
                return nil
            }
        } else {
            // Handle the case where the plist file couldn't be loaded
            print("Error loading keys.plist")
            return nil
        }
    }
    
    func getWeatherURL() -> String {
        let weatherApiKey = getApiKey()
        return "https://api.openweathermap.org/data/2.5/weather?appid=\(weatherApiKey!)&units=metric"
    }
}

protocol WeatherManagerDelegate {
    func didUpdateWeather(_ weatherManager: WeatherManager, weather: WeatherModel)
    func didFailWithError(error: Error)
    func updateWeatherInProgress(_ weatherManager: WeatherManager)
}
