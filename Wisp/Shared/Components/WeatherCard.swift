import SwiftUI

/// Simple weather card component for displaying weather conditions
struct WeatherCard: View {
    let weatherData: WeatherData
    
    var body: some View {
        compactView
    }
    
    // MARK: - Compact View (for lists)
    private var compactView: some View {
        HStack(spacing: 12) {
            // Weather icon
            ZStack {
                Circle()
                    .fill(weatherData.condition.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: weatherData.condition.systemIconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(weatherData.condition.color)
            }
            
            // Weather info
            VStack(alignment: .leading, spacing: 2) {
                Text(weatherData.formattedTemperature)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(weatherData.condition.readableDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Additional info
            VStack(alignment: .trailing, spacing: 2) {
                Text("Feels like \(weatherData.formattedFeelsLike)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(weatherData.humidityPercentage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Preview
#Preview("Weather Card") {
    VStack(spacing: 12) {
        ForEach(WeatherData.mockData) { weather in
            WeatherCard(weatherData: weather)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}