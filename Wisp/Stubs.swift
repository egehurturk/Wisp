import Foundation
import SwiftUI
import MapKit

// MARK: - Stub Data Models

/// Stub implementation for ghost race results
struct GhostRaceResult: Identifiable {
    let id = UUID()
    let runId: UUID
    let ghostName: String
    let didWin: Bool
    let timeDifference: String?
    
    var resultText: String {
        didWin ? "Won" : "Lost"
    }
    
    static let mockData: [GhostRaceResult] = [
        GhostRaceResult(runId: UUID(), ghostName: "Personal Best", didWin: true, timeDifference: "2:30"),
        GhostRaceResult(runId: UUID(), ghostName: "John's Run", didWin: false, timeDifference: "1:45"),
        GhostRaceResult(runId: UUID(), ghostName: "5K Goal", didWin: true, timeDifference: "0:15")
    ]
    
    static let extendedMockData: [GhostRaceResult] = [
        GhostRaceResult(runId: UUID(), ghostName: "Personal Best", didWin: true, timeDifference: "2:30"),
        GhostRaceResult(runId: UUID(), ghostName: "Sarah Chen", didWin: false, timeDifference: "1:45"),
        GhostRaceResult(runId: UUID(), ghostName: "Alex Rodriguez", didWin: true, timeDifference: "0:15"),
        GhostRaceResult(runId: UUID(), ghostName: "Sub-20 5K Goal", didWin: true, timeDifference: "0:45"),
        GhostRaceResult(runId: UUID(), ghostName: "Marathon Goal Pace", didWin: false, timeDifference: "3:20"),
        GhostRaceResult(runId: UUID(), ghostName: "Yesterday's Run", didWin: true, timeDifference: "1:10"),
        GhostRaceResult(runId: UUID(), ghostName: "Mike Thompson", didWin: false, timeDifference: "2:05"),
        GhostRaceResult(runId: UUID(), ghostName: "Elite Runner", didWin: false, timeDifference: "5:30"),
        GhostRaceResult(runId: UUID(), ghostName: "Personal Best", didWin: true, timeDifference: "0:35"),
        GhostRaceResult(runId: UUID(), ghostName: "Last Week's Tempo", didWin: false, timeDifference: "0:55")
    ]
}

/// Stub implementation for custom goal ghosts
struct CustomGoalGhost: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let distance: Double // in meters
    let targetTime: TimeInterval // in seconds
    let difficulty: Difficulty
    let category: Category
    let progress: Double? // 0.0 to 1.0, nil if not attempted
    
    enum Difficulty: Int, CaseIterable {
        case beginner = 1
        case intermediate = 2
        case advanced = 3
        case expert = 4
        case elite = 5
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .yellow
            case .advanced: return .orange
            case .expert: return .red
            case .elite: return .purple
            }
        }
    }
    
    enum Category: String, CaseIterable {
        case speed = "Speed"
        case endurance = "Endurance"
        case interval = "Interval"
        case recovery = "Recovery"
        
        var displayName: String {
            rawValue
        }
        
        var color: Color {
            switch self {
            case .speed: return .red
            case .endurance: return .blue
            case .interval: return .orange
            case .recovery: return .green
            }
        }
    }
    
    var formattedDistance: String {
        let kilometers = distance / 1000
        return String(format: "%.1f km", kilometers)
    }
    
    var formattedTargetTime: String {
        let minutes = Int(targetTime) / 60
        let seconds = Int(targetTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedTargetPace: String {
        let pacePerKm = (targetTime / (distance / 1000)) / 60
        let minutes = Int(pacePerKm)
        let seconds = Int((pacePerKm - Double(minutes)) * 60)
        return String(format: "%d:%02d/km", minutes, seconds)
    }
    
    static let mockData: [CustomGoalGhost] = [
        CustomGoalGhost(
            name: "5K Sub-20",
            description: "Break the 20-minute barrier for 5K",
            distance: 5000,
            targetTime: 1200,
            difficulty: .advanced,
            category: .speed,
            progress: 0.75
        ),
        CustomGoalGhost(
            name: "10K Endurance",
            description: "Complete 10K at steady pace",
            distance: 10000,
            targetTime: 3000,
            difficulty: .intermediate,
            category: .endurance,
            progress: 0.4
        ),
        CustomGoalGhost(
            name: "Half Marathon",
            description: "Complete your first half marathon",
            distance: 21097,
            targetTime: 7200,
            difficulty: .expert,
            category: .endurance,
            progress: nil
        )
    ]
}

/// Stub implementation for challenges
struct Challenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: ChallengeType
    let progress: Double // 0.0 to 1.0
    let endDate: Date
    let participantCount: Int
    let isJoined: Bool
    
    enum ChallengeType: String, CaseIterable {
        case distance = "Distance"
        case time = "Time"
        case streak = "Streak"
        case speed = "Speed"
        case community = "Community"
        
        var icon: String {
            switch self {
            case .distance: return "location"
            case .time: return "clock"
            case .streak: return "flame"
            case .speed: return "speedometer"
            case .community: return "person.3"
            }
        }
        
        var color: Color {
            switch self {
            case .distance: return .blue
            case .time: return .green
            case .streak: return .orange
            case .speed: return .red
            case .community: return .purple
            }
        }
    }
    
    var progressText: String {
        switch type {
        case .distance:
            let current = Int(progress * 100) // Mock current distance
            return "\(current) / 100 km"
        case .time:
            let current = Int(progress * 60) // Mock current time
            return "\(current) / 60 minutes"
        case .streak:
            let current = Int(progress * 30) // Mock current streak
            return "\(current) / 30 days"
        case .speed:
            let current = Int(progress * 10) // Mock current speed goals
            return "\(current) / 10 runs"
        case .community:
            let current = Int(progress * 500) // Mock current community points
            return "\(current) / 500 points"
        }
    }
    
    var timeRemainingText: String {
        let now = Date()
        let timeInterval = endDate.timeIntervalSince(now)
        let days = Int(timeInterval / 86400)
        
        if days > 0 {
            return "\(days) days left"
        } else if timeInterval > 0 {
            let hours = Int(timeInterval / 3600)
            return "\(hours) hours left"
        } else {
            return "Ended"
        }
    }
    
    static let mockData: [Challenge] = [
        Challenge(
            title: "Summer Distance Challenge",
            description: "Run 100km this month and earn exclusive badges",
            type: .distance,
            progress: 0.65,
            endDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
            participantCount: 2847,
            isJoined: true
        ),
        Challenge(
            title: "Daily Runner",
            description: "Run every day for 30 days straight",
            type: .streak,
            progress: 0.43,
            endDate: Calendar.current.date(byAdding: .day, value: 17, to: Date()) ?? Date(),
            participantCount: 1205,
            isJoined: true
        ),
        Challenge(
            title: "Speed Demon",
            description: "Complete 10 runs faster than 5:00/km pace",
            type: .speed,
            progress: 0.8,
            endDate: Calendar.current.date(byAdding: .day, value: 8, to: Date()) ?? Date(),
            participantCount: 589,
            isJoined: false
        ),
        Challenge(
            title: "Community Champion",
            description: "Earn 500 points by encouraging other runners",
            type: .community,
            progress: 0.32,
            endDate: Calendar.current.date(byAdding: .day, value: 22, to: Date()) ?? Date(),
            participantCount: 3421,
            isJoined: false
        ),
        Challenge(
            title: "Weekend Warrior",
            description: "Run for 60 minutes every weekend",
            type: .time,
            progress: 0.75,
            endDate: Calendar.current.date(byAdding: .day, value: 12, to: Date()) ?? Date(),
            participantCount: 967,
            isJoined: true
        )
    ]
}

// MARK: - Stub View Controllers

/// Stub implementations for other views
// RunsView implementation is now in Features/Runs/Views/RunsView.swift

struct StatisticsView: View {
    var body: some View {
        NavigationView {
            Text("Statistics View - Coming Soon")
                .navigationTitle("Statistics")
        }
    }
}

struct GhostsView: View {
    var body: some View {
        NavigationView {
            Text("Ghosts View - Coming Soon")
                .navigationTitle("Ghosts")
        }
    }
}

struct GroupsView: View {
    var body: some View {
        NavigationView {
            Text("Groups View - Coming Soon")
                .navigationTitle("Groups")
        }
    }
}
