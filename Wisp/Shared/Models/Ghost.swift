import Foundation
import SwiftUI

/// Ghost model representing a running competitor
struct Ghost: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: GhostType
    let distance: Double // in meters
    let time: TimeInterval // in seconds
    let pace: Double // seconds per kilometer
    let description: String
    let avatarImageURL: String?
    
    enum GhostType: String, CaseIterable {
        case personalRecord = "PR"
        case stravaFriend = "Strava"
        case customGoal = "Goal"
        case pastRun = "Past Run"
        case challengeGhost = "Challenge"
        
        var icon: String {
            switch self {
            case .personalRecord: return "trophy.fill"
            case .stravaFriend: return "figure.socialdance"
            case .customGoal: return "target"
            case .pastRun: return "clock.arrow.circlepath"
            case .challengeGhost: return "flame.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .personalRecord: return .yellow
            case .stravaFriend: return .orange
            case .customGoal: return .purple
            case .pastRun: return .blue
            case .challengeGhost: return .red
            }
        }
        
        var badge: String? {
            switch self {
            case .stravaFriend: return "strava"
            default: return nil
            }
        }
    }
    
    var formattedDistance: String {
        let kilometers = distance / 1000
        return String(format: "%.1f km", kilometers)
    }
    
    var formattedTime: String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedPace: String {
        let minutesPerKm = pace / 60
        let minutes = Int(minutesPerKm)
        let seconds = Int((minutesPerKm - Double(minutes)) * 60)
        return String(format: "%d:%02d/km", minutes, seconds)
    }
    
    static let mockData: [Ghost] = [
        // Personal Records
        Ghost(
            name: "5K Personal Best",
            type: .personalRecord,
            distance: 5000,
            time: 1200, // 20:00
            pace: 240, // 4:00/km
            description: "Your fastest 5K time - beat it!",
            avatarImageURL: nil,
        ),
        Ghost(
            name: "10K Personal Best",
            type: .personalRecord,
            distance: 10000,
            time: 2700, // 45:00
            pace: 270, // 4:30/km
            description: "Your best 10K performance",
            avatarImageURL: nil,
        ),
        
        // Strava Friends
        Ghost(
            name: "Alex Rodriguez",
            type: .stravaFriend,
            distance: 5000,
            time: 1080, // 18:00
            pace: 216, // 3:36/km
            description: "Alex's morning 5K from last week",
            avatarImageURL: "alex_avatar",
        ),
        Ghost(
            name: "Sarah Chen",
            type: .stravaFriend,
            distance: 8000,
            time: 2400, // 40:00
            pace: 300, // 5:00/km
            description: "Sarah's tempo run",
            avatarImageURL: "sarah_avatar",
        ),
        Ghost(
            name: "Mike Thompson",
            type: .stravaFriend,
            distance: 10000,
            time: 2520, // 42:00
            pace: 252, // 4:12/km
            description: "Mike's weekend long run",
            avatarImageURL: "mike_avatar",
        ),
        
        // Custom Goals
        Ghost(
            name: "Sub-20 5K Goal",
            type: .customGoal,
            distance: 5000,
            time: 1200, // 20:00 exactly
            pace: 240, // 4:00/km
            description: "Break the 20-minute barrier",
            avatarImageURL: nil,
        ),
        Ghost(
            name: "Marathon Goal Pace",
            type: .customGoal,
            distance: 10000,
            time: 3000, // 50:00
            pace: 300, // 5:00/km
            description: "Practice your marathon target pace",
            avatarImageURL: nil,
        ),
        
        // Past Runs
        Ghost(
            name: "Yesterday's Run",
            type: .pastRun,
            distance: 6000,
            time: 1800, // 30:00
            pace: 300, // 5:00/km
            description: "Your run from yesterday - can you beat it?",
            avatarImageURL: nil,
        ),
        Ghost(
            name: "Last Week's Tempo",
            type: .pastRun,
            distance: 8000,
            time: 2280, // 38:00
            pace: 285, // 4:45/km
            description: "Your tempo run from last Tuesday",
            avatarImageURL: nil,
        ),
        
        // Challenge Ghosts
        Ghost(
            name: "Elite Runner",
            type: .challengeGhost,
            distance: 5000,
            time: 900, // 15:00
            pace: 180, // 3:00/km
            description: "Can you keep up with an elite pace?",
            avatarImageURL: nil,
        )
    ]
}

