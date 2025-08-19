//
//  WeatherBanner.swift
//  Wisp
//
//  Created by Ege Hurturk on 19.08.2025.
//

import SwiftUI
import Foundation

struct WeatherBanner: View {
    let weatherIcon: String
    let temperature: Double
    
    private var formattedTemperature: String {
        let measurement = Measurement(value: temperature, unit: UnitTemperature.celsius)
        
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.current
        formatter.unitOptions = .providedUnit // or .providedUnit if you want °C/°F shown
        formatter.numberFormatter.maximumFractionDigits = 1
        
        return formatter.string(from: measurement)
    }
    
    private var weatherDescription: String {
        switch weatherIcon {
        case "sun.max.fill":
            return "Bright sunny skies with warmth all throughout the day."
        case "cloud.sun.fill":
            return "Partly cloudy skies with occasional sunshine breaking through often."
        case "cloud.fill":
            return "Overcast skies covering the horizon, minimal sunshine peeking through."
        case "cloud.rain.fill":
            return "Steady rainfall with gray clouds dominating the entire day."
        case "cloud.heavyrain.fill":
            return "Heavy downpour expected, dark clouds filling the entire sky."
        case "cloud.snow.fill":
            return "Cold snowy conditions with fluffy snowflakes drifting from above."
        case "cloud.bolt.fill":
            return "Thunderstorms arriving quickly, lightning flashing across the dark sky."
        case "wind":
            return "Strong winds blowing fiercely, sweeping across the open landscapes."
        case "cloud.fog.fill":
            return "Dense fog blankets the surroundings, reducing visibility all around."
        default:
            return "Stable weather conditions all around, expect a bit of wind."
        }
    }
    
    private enum WeatherTheme {
       case sunny, partlyCloudy, cloudy, rain, heavy, wind, fog, `default`
    }
    
    private var theme: WeatherTheme {
       switch weatherIcon {
       case "sun.max", "sun.max.fill":
           return .sunny
       case "cloud.sun", "cloud.sun.fill":
           return .partlyCloudy
       case "cloud", "cloud.fill":
           return .cloudy
       case "cloud.rain", "cloud.rain.fill", "cloud.snow", "cloud.snow.fill":
           return .rain
       case "cloud.heavyrain", "cloud.heavyrain.fill", "cloud.bolt", "cloud.bolt.fill":
           return .heavy
       case "wind":
           return .wind
       case "cloud.fog", "cloud.fog.fill":
           return .fog
       default:
           return .default
       }
    }
       
    private var backgroundGradient: LinearGradient {
       let colors: [Color]
       switch theme {
       case .sunny:
           // blue + white (bright)
           colors = [
               Color.blue.opacity(0.60),
               Color.white.opacity(0.85)
           ]
       case .partlyCloudy:
           // a bit of gray + blue
           colors = [
               Color.blue.opacity(0.55),
               Color.gray.opacity(0.35),
               Color.white.opacity(0.70)
           ]
       case .cloudy:
           // mostly gray with a hint of blue
           colors = [
               Color.gray.opacity(0.65),
               Color.gray.opacity(0.45),
               Color.blue.opacity(0.25)
           ]
       case .rain:
           // gray on rains
           colors = [
               Color.gray.opacity(0.70),
               Color.gray.opacity(0.50),
               Color.blue.opacity(0.30)
           ]
       case .heavy:
           // darker for heavy rain / storms
           colors = [
               Color.gray.opacity(0.85),
               Color.black.opacity(0.55),
               Color.blue.opacity(0.25)
           ]
       case .wind:
           // darker, cool tones
           colors = [
               Color.gray.opacity(0.75),
               Color.indigo.opacity(0.35)
           ]
       case .fog:
           // muted dark grays
           colors = [
               Color.gray.opacity(0.80),
               Color.gray.opacity(0.55)
           ]
       case .default:
           colors = [
               Color.blue.opacity(0.45),
               Color.white.opacity(0.75)
           ]
       }
       
       return LinearGradient(
           gradient: Gradient(colors: colors),
           startPoint: .topLeading,
           endPoint: .bottomTrailing
       )
   }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather")
                .font(.title2)
                .foregroundColor(.primary)
                .fontWeight(.bold)
            
            HStack(spacing: 8) {
                // Weather icon and temperature
                HStack(spacing: 16) {
                    Image(systemName: weatherIcon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(WeatherManager.formattedTemperature(temperature: temperature))
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(WeatherManager.weatherDescriptionFromIcon(weatherIcon: weatherIcon))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            ZStack {
               // Blurred gradient base
               RoundedRectangle(cornerRadius: 12)
                   .fill(backgroundGradient)
                   .blur(radius: 22)
               
               // Frosted glass layer on top
               RoundedRectangle(cornerRadius: 12)
                   .fill(.ultraThinMaterial)
           }
        )
        .overlay(
           // Subtle stroke for definition
           RoundedRectangle(cornerRadius: 12)
               .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
       )
//       .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    WeatherBanner(
        weatherIcon: "sun.max.fill", temperature: 19.8
    )
}
