import Foundation
import Combine
import SwiftUI

struct DailyDistance: Identifiable {
    let id = UUID()
    let date: Date
    let distance: Double // in kilometers
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

/// View model for the Home screen
@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var latestRun: Run?
    @Published var analysisText: String = "Nice run! Keep it up."
    @Published var customGoals: [CustomGoalGhost] = []
    @Published var challenges: [Challenge] = []
    @Published var isLoadingRuns: Bool = false
    @Published var isLoadingGoals: Bool = false
    @Published var isLoadingChallenges: Bool = false
    @Published var errorMessage: String?
    @Published var weeklyChartData: [DailyDistance] = []
    @Published var currentWeekOffset: Int = 0 // 0 = current week, -1 = previous week, etc.
    private var allRuns: [Run] = []
    
    // MARK: - Properties
    private let logger = Logger.ui
    private let supabaseManager = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good morning!"
        case 12..<17:
            return "Good afternoon!"
        case 17..<21:
            return "Good evening!"
        default:
            return "Good night!"
        }
    }
    
    var userProfileImageURL: URL? {
        // TODO: Return actual user profile image URL
        return nil
    }
    
    var motivationalMessage: String {
        let messages = [
            "Every step counts towards your goal 🏃‍♂️",
            "Your next personal best is just a run away ⚡",
            "Time to chase those ghosts 👻",
            "Let's beat yesterday's you 🚀",
            "The track is calling your name 🏃‍♀️",
            "Turn your dreams into miles 💪",
            "Your running journey continues here 🌟"
        ]
        
        // Rotate message based on day of year to keep it fresh
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return messages[dayOfYear % messages.count]
    }
    
    // MARK: - Initialization
    init() {
    }
    
    // MARK: - Public Methods
    
    /// Load initial data for the home screen
    func loadData() {
        
        Task {
            await loadLatestRun()
            await loadAllRuns()
            await loadCustomGoals()
            await loadChallenges()
        }
    }
    
    /// Refresh all data
    func refreshData() async {
        logger.info("Refreshing home screen data")
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadLatestRun()
            }
            
            group.addTask {
                await self.loadAllRuns()
            }
            
            group.addTask {
                await self.loadCustomGoals()
            }
            
            group.addTask {
                await self.loadChallenges()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Load latest run for home screen
    private func loadLatestRun() async {
        isLoadingRuns = true
        errorMessage = nil
        
        do {
            guard let userId = supabaseManager.currentUser?.id else {
                logger.warning("No authenticated user found when loading latest run")
                isLoadingRuns = false
                return
            }
            
            latestRun = try await supabaseManager.fetchLatestRun(for: userId)
            
            // For now, use hardcoded analysis text as requested
            // Future: compute analysis from run data and recent runs
            analysisText = "Nice run! Keep it up."
            
            if latestRun != nil {
                logger.info("Successfully loaded latest run for home screen")
            } else {
                logger.info("No runs found for user")
                analysisText = "Ready for your first run?"
            }
        } catch {
            logger.error(String(describing: error))
            logger.error("Failed to load latest run", error: error)
            errorMessage = "Failed to load recent runs. Please try again."
        }
        
        isLoadingRuns = false
    }
    
    /// Load custom goal ghosts
    private func loadCustomGoals() async {
        isLoadingGoals = true
        errorMessage = nil
        
        do {
            // TODO: Replace with actual API call
            // try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
            
            let goals = CustomGoalGhost.mockData.prefix(2)
            customGoals = Array(goals)
        } catch {
            logger.error("Failed to load custom goals", error: error)
            errorMessage = "Failed to load training goals. Please try again."
        }
        
        isLoadingGoals = false
    }
    
    /// Load challenges
    private func loadChallenges() async {
        isLoadingChallenges = true
        errorMessage = nil
        
        do {
            // TODO: Replace with actual API call
            // try await Task.sleep(nanoseconds: 750_000_000) // Simulate network delay
            
            let loadedChallenges = Challenge.mockData.prefix(3)
            challenges = Array(loadedChallenges)
        } catch {
            logger.error("Failed to load challenges", error: error)
            errorMessage = "Failed to load challenges. Please try again."
        }
        
        isLoadingChallenges = false
    }
    
    /// Load all runs for chart data
    private func loadAllRuns() async {
        do {
            guard let userId = supabaseManager.currentUser?.id else {
                logger.warning("No authenticated user found when loading runs for chart")
                return
            }
            
            // Load all runs for the user
            allRuns = try await supabaseManager.fetchRuns(for: userId)
            
            // Generate weekly chart data for current week offset
            weeklyChartData = generateWeeklyChartData(from: allRuns, weekOffset: currentWeekOffset)
            
            logger.info("Successfully loaded \(allRuns.count) runs for chart data")
        } catch {
            logger.error("Failed to load runs for chart", error: error)
        }
    }
    
    // MARK: - Chart Navigation Methods
    
    func navigateToPreviousWeek() {
        currentWeekOffset -= 1
        withAnimation(.easeInOut(duration: 0.6)) {
            weeklyChartData = generateWeeklyChartData(from: allRuns, weekOffset: currentWeekOffset)
        }
        logger.info("Navigated to week offset: \(currentWeekOffset)")
    }
    
    func navigateToNextWeek() {
        // Don't allow navigating beyond current week
        if currentWeekOffset < 0 {
            currentWeekOffset += 1
            withAnimation(.easeInOut(duration: 0.6)) {
                weeklyChartData = generateWeeklyChartData(from: allRuns, weekOffset: currentWeekOffset)
            }
            logger.info("Navigated to week offset: \(currentWeekOffset)")
        }
    }
    
    var canNavigateToNextWeek: Bool {
        return currentWeekOffset < 0
    }
    
    var weekTitle: String {
        if currentWeekOffset == 0 {
            return "This Week"
        } else if currentWeekOffset == -1 {
            return "Last Week"
        } else {
            return "\(abs(currentWeekOffset)) Weeks Ago"
        }
    }
    
    var runCount: Int {
        return allRuns.count
    }
    
    var totalDistance: String {
        let total = allRuns.reduce(0) { $0 + $1.distance }
        let kilometers = total / 1000
        return String(format: "%.1f km", kilometers)
    }
    
    var totalDuration: String {
        let total = allRuns.reduce(into: 0) { $0 + $1.movingTime }
        let hours = Int(total) / 3600
        let minutes = Int(total) % 3600 / 60
        return String(format: "%dh %dm", hours, minutes)
    }
    
    private func generateWeeklyChartData(from runs: [Run], weekOffset: Int = 0) -> [DailyDistance] {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate the start date for the week we want to show
        guard let weekStartDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today) else {
            return []
        }
        
        // Create data for 7 days starting from the week start date
        var chartData: [DailyDistance] = []
        
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: weekStartDate) else { continue }
            
            // Get runs for this day
            let dayRuns = runs.filter { run in
                calendar.isDate(run.startedAt, inSameDayAs: date)
            }
            
            // Calculate total distance for this day in kilometers
            let totalDistance = dayRuns.reduce(0.0) { $0 + ($1.distance / 1000.0) }
            
            chartData.append(DailyDistance(date: date, distance: totalDistance))
        }
        
        return chartData
    }
}

// MARK: - Error Handling
extension HomeViewModel {
    
    /// Handle errors and show appropriate messages
    func handleError(_ error: Error) {
        logger.error("HomeViewModel error occurred", error: error)
        
        // Map specific errors to user-friendly messages
        switch error {
        case is URLError:
            errorMessage = "Network connection error. Please check your internet connection."
        default:
            errorMessage = "An unexpected error occurred. Please try again."
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
