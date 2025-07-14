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
    let route: RunRoute?
    let heartRateData: [HeartRatePoint]?
    let paceData: [PacePoint]?
    
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
            route: RunRoute.mockData[0],
            heartRateData: HeartRatePoint.mockData,
            paceData: PacePoint.mockData
        ),
        Ghost(
            name: "10K Personal Best",
            type: .personalRecord,
            distance: 10000,
            time: 2700, // 45:00
            pace: 270, // 4:30/km
            description: "Your best 10K performance",
            avatarImageURL: nil,
            route: RunRoute.mockData[1],
            heartRateData: HeartRatePoint.mockData,
            paceData: PacePoint.mockData
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
            route: RunRoute.mockData[0],
            heartRateData: HeartRatePoint.mockData,
            paceData: PacePoint.mockData
        ),
        Ghost(
            name: "Sarah Chen",
            type: .stravaFriend,
            distance: 8000,
            time: 2400, // 40:00
            pace: 300, // 5:00/km
            description: "Sarah's tempo run",
            avatarImageURL: "sarah_avatar",
            route: RunRoute.mockData[2],
            heartRateData: HeartRatePoint.mockData,
            paceData: PacePoint.mockData
        ),
        Ghost(
            name: "Mike Thompson",
            type: .stravaFriend,
            distance: 10000,
            time: 2520, // 42:00
            pace: 252, // 4:12/km
            description: "Mike's weekend long run",
            avatarImageURL: "mike_avatar",
            route: RunRoute.mockData[1],
            heartRateData: HeartRatePoint.mockData,
            paceData: PacePoint.mockData
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
            route: RunRoute.mockData[0],
            heartRateData: HeartRatePoint.mockData,
            paceData: PacePoint.mockData
        ),
        Ghost(
            name: "Marathon Goal Pace",
            type: .customGoal,
            distance: 10000,
            time: 3000, // 50:00
            pace: 300, // 5:00/km
            description: "Practice your marathon target pace",
            avatarImageURL: nil,
            route: RunRoute.mockData[3],
            heartRateData: HeartRatePoint.mockData,
            paceData: PacePoint.mockData
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
            route: RunRoute.mockData[2],
            heartRateData: HeartRatePoint.mockData,
            paceData: PacePoint.mockData
        ),
        Ghost(
            name: "Last Week's Tempo",
            type: .pastRun,
            distance: 8000,
            time: 2280, // 38:00
            pace: 285, // 4:45/km
            description: "Your tempo run from last Tuesday",
            avatarImageURL: nil,
            route: RunRoute.mockData[1],
            heartRateData: HeartRatePoint.mockData,
            paceData: PacePoint.mockData
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
            route: RunRoute.mockData[0],
            heartRateData: HeartRatePoint.mockData,
            paceData: PacePoint.mockData
        )
    ]
}

/// Heart rate data point for ghost comparison
struct HeartRatePoint: Identifiable, Hashable {
    let id = UUID()
    let timestamp: TimeInterval
    let heartRate: Int
    
    static let mockData: [HeartRatePoint] = [
        HeartRatePoint(timestamp: 0, heartRate: 120),
        HeartRatePoint(timestamp: 60, heartRate: 140),
        HeartRatePoint(timestamp: 120, heartRate: 160),
        HeartRatePoint(timestamp: 180, heartRate: 170),
        HeartRatePoint(timestamp: 240, heartRate: 175),
        HeartRatePoint(timestamp: 300, heartRate: 165),
        HeartRatePoint(timestamp: 360, heartRate: 155)
    ]
}

/// Pace data point for ghost comparison
struct PacePoint: Identifiable, Hashable {
    let id = UUID()
    let distance: Double // meters
    let pace: Double // seconds per km
    
    static let mockData: [PacePoint] = [
        PacePoint(distance: 1000, pace: 240), // 4:00/km
        PacePoint(distance: 2000, pace: 250), // 4:10/km
        PacePoint(distance: 3000, pace: 235), // 3:55/km
        PacePoint(distance: 4000, pace: 245), // 4:05/km
        PacePoint(distance: 5000, pace: 230)  // 3:50/km
    ]
}