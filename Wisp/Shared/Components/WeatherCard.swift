import SwiftUI

/// Simple weather card component for displaying weather conditions
struct WeatherCard: View {
    let weatherData: WeatherData
    
    var body: some View {
        compactView
    }
    
    
    // MARK: - Compact View (for lists)
    private var compactView: some View {
        Text("Placeholder")
    }
}

// MARK: - Preview
#Preview("Weather Card") {
  
}
