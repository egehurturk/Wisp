import Foundation
import Combine

/// View model for the Home screen
@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var pastRuns: [PastRun] = []
    @Published var ghostResults: [GhostRaceResult] = []
    @Published var customGoals: [CustomGoalGhost] = []
    @Published var challenges: [Challenge] = []
    @Published var isLoadingRuns: Bool = false
    @Published var isLoadingGoals: Bool = false
    @Published var isLoadingChallenges: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Properties
    private let logger = Logger.ui
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
            await loadPastRuns()
            await loadCustomGoals()
            await loadChallenges()
        }
    }
    
    /// Refresh all data
    func refreshData() async {
        logger.info("Refreshing home screen data")
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadPastRuns()
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
    
    /// Load past runs with ghost results
    private func loadPastRuns() async {
        isLoadingRuns = true
        errorMessage = nil
        
        do {
            // TODO: Replace with actual API call
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
            
            let runs = PastRun.mockData.prefix(3)
            var results = GhostRaceResult.mockData.prefix(3)
            
            // Associate ghost results with specific runs
            for (index, run) in runs.enumerated() {
                if index < results.count {
                    results[index] = GhostRaceResult(
                        runId: run.id,
                        ghostName: results[index].ghostName,
                        didWin: results[index].didWin,
                        timeDifference: results[index].timeDifference
                    )
                }
            }
            
            pastRuns = Array(runs)
            ghostResults = Array(results)
        } catch {
            logger.error("Failed to load past runs", error: error)
            errorMessage = "Failed to load past runs. Please try again."
        }
        
        isLoadingRuns = false
    }
    
    /// Load custom goal ghosts
    private func loadCustomGoals() async {
        isLoadingGoals = true
        errorMessage = nil
        
        do {
            // TODO: Replace with actual API call
            try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
            
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
            try await Task.sleep(nanoseconds: 750_000_000) // Simulate network delay
            
            let loadedChallenges = Challenge.mockData.prefix(3)
            challenges = Array(loadedChallenges)
        } catch {
            logger.error("Failed to load challenges", error: error)
            errorMessage = "Failed to load challenges. Please try again."
        }
        
        isLoadingChallenges = false
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
