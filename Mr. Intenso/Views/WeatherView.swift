import Foundation
import WeatherKit
import SwiftUI
import Charts

struct HourlyMeasurement: Identifiable {
    var id = UUID()
    var time: Date
    var temperature: Double
    var rain: Double
    var chance: Double
    
    init(time: Date, temperature: Double, rain: Double, chance: Double) {
        self.time = time
        self.temperature = temperature
        self.rain = rain
        self.chance = chance
    }
}

struct MinutelyMeasurement: Identifiable {
    var id = UUID()
    var time: Date
    var chance: Double
    
    init(time: Date, chance: Double) {
        self.time = time
        self.chance = chance
    }
}

struct DailyMeasurement: Identifiable {
    var id = UUID()
    var date: Date
    var low: Double
    var high: Double
    var rain: Double
    var symbol: String
    
    init(date: Date, low: Double, high: Double, rain: Double, symbol: String) {
        self.date = date
        self.low = low
        self.high = high
        self.rain = rain
        self.symbol = symbol
    }
}

enum WeatherTab: Int, Identifiable {
    case current, minutely, hourly, longterm

    var id: Int { self.rawValue }
}

struct WeatherView: View {
    let weather: Weather
    let hourlyPlotImage: UIImage?
    let minutelyPlotImage: UIImage?
    let city: String?
    @State private var selectedTab: WeatherTab = .current
    
    let calendar = Calendar.current
    let now = Date()
    
    var availableTabs: [WeatherTab] {
        var tabs: [WeatherTab] = [.current]
        if minutelyPlotImage != nil { tabs.append(.minutely) }
        if hourlyPlotImage != nil { tabs.append(.hourly) }
        tabs.append(.longterm)
        return tabs
    }
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 8) {
                ForEach(availableTabs.indices, id: \.self) { index in
                    Circle()
                        .fill(availableTabs[index] == selectedTab ? Color.black : Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: selectedTab)
                }
            }
            .padding(.bottom, 4)
            
            TabView(selection: $selectedTab) {
                ForEach(availableTabs, id: \.self) { tab in
                    switch tab {
                    case .current:
                        // current weather
                        VStack(spacing: 5) {
                            getProperWeatherIcon(for: weather.currentWeather.symbolName)
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: 12,
                                        )
                                    .foregroundStyle(Color.black.opacity(0.1))
                                    .padding(-20)
                                )
                                .padding(.bottom, 15)
                            if let city = city {
                                Text(city)
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(Color.black)
                                HStack(alignment: .center) {
                                    Text(String(format: "%.1f°C", weather.currentWeather.temperature.value))
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(Color.black)
                                    Text("•")
                                        .foregroundStyle(Color.black)
                                        .bold()
                                    Text(weather.currentWeather.condition.description.capitalized)
                                        .font(.subheadline)
                                        .foregroundColor(Color.black)
                                }
                            } else {
                                Text(String(format: "%.1f°C", weather.currentWeather.temperature.value))
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(Color.black)
                                Text(weather.currentWeather.condition.description.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(Color.black)
                            }
                        }
                        .tag(WeatherTab.current)
                    
                    case .hourly:
                        // hourly
                        if let hourlyPlotImage = hourlyPlotImage {
                            VStack(spacing: 5) {
                                HStack {
                                    if let city = city {
                                        Text(
                                            String(
                                                format: TranslationUnit.getMessage(for: .WEATHER_HOURLY_FORECAST_CITY) ?? "24h-Forecast of %@", city)
                                        )
                                        .font(.headline)
                                        .foregroundStyle(.black)
                                        .padding(.leading, 8)
                                    } else {
                                        Text(
                                            String(
                                                format: TranslationUnit.getMessage(for: .WEATHER_HOURLY_FORECAST) ?? "24h-Forecast")
                                        )
                                        .font(.headline)
                                        .foregroundStyle(.black)
                                        .padding(.leading, 8)
                                    }
                                }
                                .padding(.bottom, 8)
                                
                                VStack(spacing: 5) {
                                    Image(uiImage: hourlyPlotImage)
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                            .tag(WeatherTab.hourly)
                        }
                    case .minutely:
                        // minute weather
                        if let minutelyPlotImage = minutelyPlotImage {
                            VStack(spacing: 5) {
                                HStack {
                                    if let city = city {
                                        Text(
                                            String(
                                                format: TranslationUnit.getMessage(for: .WEATHER_MINUTELY_FORECAST_CITY) ?? "60min-Forecast of %@", city)
                                        )
                                        .font(.headline)
                                        .foregroundStyle(.black)
                                        .padding(.leading, 8)
                                    } else {
                                        Text(
                                            String(
                                                format: TranslationUnit.getMessage(for: .WEATHER_MINUTELY_FORECAST) ?? "60min-Forecast")
                                        )
                                        .font(.headline)
                                        .foregroundStyle(.black)
                                        .padding(.leading, 8)
                                    }
                                }
                                .padding(.bottom, 8)
                                
                                VStack(spacing: 5) {
                                    Image(uiImage: minutelyPlotImage)
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                            .tag(WeatherTab.minutely)
                        }
                    case .longterm:
                        getLongtermForecast()
                            .padding()
                            .padding(.trailing, -10)
                            .padding(.leading, -10)
                            .tag(WeatherTab.longterm)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // we make custom
        }
        .background(alignment: .bottom) {
            HStack(spacing: 4) {
                Image(systemName: "apple.logo")
                    .foregroundColor(.black)
                Text(TranslationUnit.getMessage(for: .WEATHER_ANNOTATION) ?? "Weather data by Apple")
                    .foregroundColor(.black)
                Text("|")
                    .foregroundStyle(Color.black)
                Text(TranslationUnit.getMessage(for: .WEATHER_SOURCE) ?? "Other sources")
                    .foregroundColor(.blue)
                    .underline()
                    .onTapGesture {
                        if let url = URL(string: "https://developer.apple.com/weatherkit/data-source-attribution/"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
            }
            .font(.footnote)
            .padding(8)
            .background(Color.white.opacity(0.8))
            .cornerRadius(8)
            .padding(.bottom, -14)
        }
    }
    
    // https://github.com/DeimanteValunaite/weather-app-swift/blob/main/WeatheryApp/ViewModels/WeatherViewModel.swift
    @ViewBuilder
    private func getProperWeatherIcon(for icon: String, size: CGFloat? = 180) -> some View {
        let iconName = icon.appending(".fill")
        let baseImage = Image(systemName: iconName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
        
        switch iconName {
        case "cloud.sun.rain.fill", "cloud.moon.rain.fill":
            baseImage
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .yellow, .blue)

        case "cloud.bolt.rain.fill":
            baseImage
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .blue, .yellow)
            
        case "cloud.rain.fill", "cloud.heavyrain.fill", "cloud.snow.fill", "cloud.drizzle.fill":
            baseImage
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .blue)

        case "sun.max.fill":
            baseImage
                .symbolRenderingMode(.palette)
                .foregroundStyle(.yellow, .orange)

        case "cloud.fill":
            baseImage
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white)

        case "moon.stars.fill", "cloud.sun.fill":
            baseImage
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .yellow)

        default:
            baseImage
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white)
        }
    }
    
    private func getLongtermForecast() -> some View {
        let days: [DailyMeasurement] = weather.dailyForecast
            .map { day in
                if #available(iOS 18.0, *) {
                    DailyMeasurement(
                        date: day.date,
                        low: day.lowTemperature.value,
                        high: day.highTemperature.value,
                        rain: day.precipitationAmountByType.rainfall.value,
                        symbol: day.symbolName
                    )
                } else {
                    DailyMeasurement(
                        date: day.date,
                        low: day.lowTemperature.value,
                        high: day.highTemperature.value,
                        rain: day.precipitationAmount.value,
                        symbol: day.symbolName
                    )
                }
            }
        
        
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: UserDefaults.standard.getLanguage() == "ENG" ? "en_US" : "de_DE")
        weekdayFormatter.setLocalizedDateFormatFromTemplate("EEE")

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: UserDefaults.standard.getLanguage() == "ENG" ? "en_US" : "de_DE")
        dateFormatter.setLocalizedDateFormatFromTemplate("dd.MM")
        
        return VStack {
            HStack {
                if let city = city {
                    Text(String(format: TranslationUnit.getMessage(for: .WEATHER_LONGTERM_CITY) ?? "Longterm Forecast for %@", city))
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.leading, 8)
                } else {
                    Text(TranslationUnit.getMessage(for: .WEATHER_LONGTERM) ?? "Longterm Forecast")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.leading, 8)
                }
                
            }
            .padding(.bottom, 8)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(days) { day in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(weekdayFormatter.string(from: day.date))
                                    .foregroundStyle(.black)
                                Text(dateFormatter.string(from: day.date))
                                    .foregroundStyle(.black)
                            }
                            .frame(width: 60, alignment: .leading)
                            

                            getProperWeatherIcon(for: day.symbol, size: 30)

                            Text("\(day.low, specifier: "%.1f")° /\n \(day.high, specifier: "%.1f")°")
                                .foregroundStyle(.black)

                            Spacer()

                            Text(String(format: "%.1f mm", day.rain))
                                .foregroundStyle(.blue)
                        }
                        .padding()
                        .background(Color.black.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
}
