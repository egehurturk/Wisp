import Foundation

struct LapData {
    let number: Int
    let time: TimeInterval
    let distance: Double
    let pace: Double
    
    var formattedTime: String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}