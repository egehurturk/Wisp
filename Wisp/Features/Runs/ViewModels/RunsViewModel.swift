import Foundation
import Combine

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

/// View model for the Runs screen displaying past run history
@MainActor
final class RunsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var runs: [Run] = []
    @Published var weeklyChartData: [DailyDistance] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedSortOption: SortOption = .dateDescending
    @Published var selectedFilterOption: FilterOption = .all
    
    // MARK: - Properties
    private let logger = Logger.ui
    private let supabaseManager = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var allRuns: [Run] = []
    
    // MARK: - Sorting and Filtering Options
    enum SortOption: String, CaseIterable {
        case dateDescending = "Latest First"
        case dateAscending = "Oldest First"
        case distanceDescending = "Longest Distance"
        case distanceAscending = "Shortest Distance"
        case durationDescending = "Longest Duration"
        case durationAscending = "Shortest Duration"
        case paceAscending = "Fastest Pace"
        case paceDescending = "Slowest Pace"
        
        var displayName: String {
            return rawValue
        }
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All Runs"
        case won = "Won Against Ghost"
        case lost = "Lost Against Ghost"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisYear = "This Year"
        
        var displayName: String {
            return rawValue
        }
    }
    
    // MARK: - Computed Properties
    var filteredAndSortedRuns: [Run] {
        var filtered = allRuns
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { run in
                (run.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (run.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply category filter
        switch selectedFilterOption {
        case .all:
            break
        case .won, .lost:
            // TODO: Implement ghost result filtering when ghost results are available
            break
        case .thisWeek:
            let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.startedAt >= oneWeekAgo }
        case .thisMonth:
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.startedAt >= oneMonthAgo }
        case .thisYear:
            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.startedAt >= oneYearAgo }
        }
        
        // Apply sorting
        switch selectedSortOption {
        case .dateDescending:
            filtered.sort { $0.startedAt > $1.startedAt }
        case .dateAscending:
            filtered.sort { $0.startedAt < $1.startedAt }
        case .distanceDescending:
            filtered.sort { $0.distance > $1.distance }
        case .distanceAscending:
            filtered.sort { $0.distance < $1.distance }
        case .durationDescending:
            filtered.sort { $0.movingTime > $1.movingTime }
        case .durationAscending:
            filtered.sort { $0.movingTime < $1.movingTime }
        case .paceAscending:
            filtered.sort { ($0.averagePace ?? Double.greatestFiniteMagnitude) < ($1.averagePace ?? Double.greatestFiniteMagnitude) }
        case .paceDescending:
            filtered.sort { ($0.averagePace ?? 0) > ($1.averagePace ?? 0) }
        }
        
        return filtered
    }
    
    var hasRuns: Bool {
        return !filteredAndSortedRuns.isEmpty
    }
    
    var runCount: Int {
        return filteredAndSortedRuns.count
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
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Load runs data
    func loadRuns() {
        logger.info("Loading runs data")
        
        Task {
            await loadRunsData()
        }
    }
    
    /// Refresh runs data
    func refreshRuns() async {
        logger.info("Refreshing runs data")
        await loadRunsData()
    }
    
    /// Update run title
    func updateRunTitle(for runId: UUID, newTitle: String) {
        logger.info("Updating run title for run \(runId)")
        
        // TODO: Implement run title update in backend
        logger.info("Run title update not yet implemented")
    }
    
    /// Clear search and filters
    func clearFilters() {
        searchText = ""
        selectedFilterOption = .all
        selectedSortOption = .dateDescending
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Update filtered runs when search text, sort, or filter changes
        Publishers.CombineLatest3($searchText, $selectedSortOption, $selectedFilterOption)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.updateFilteredRuns()
            }
            .store(in: &cancellables)
    }
    
    private func updateFilteredRuns() {
        runs = filteredAndSortedRuns
    }
    
    private func loadRunsData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userId = supabaseManager.currentUser?.id else {
                logger.warning("No authenticated user found when loading runs")
                isLoading = false
                return
            }
            
            // Load all runs for the user
            allRuns = try await supabaseManager.fetchRuns(for: userId)
            
            // Generate weekly chart data for last 7 days
            weeklyChartData = generateWeeklyChartData(from: allRuns)
            
            // Update filtered runs
            updateFilteredRuns()
            
            logger.info("Successfully loaded \(allRuns.count) runs")
        } catch {
            logger.error("Failed to load runs", error: error)
            errorMessage = "Failed to load runs. Please try again."
        }
        
        isLoading = false
    }
    
    private func generateWeeklyChartData(from runs: [Run]) -> [DailyDistance] {
        let calendar = Calendar.current
        let today = Date()
        
        // Create data for last 7 days (including today)
        var chartData: [DailyDistance] = []
        
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
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
extension RunsViewModel {
    
    /// Handle errors and show appropriate messages
    func handleError(_ error: Error) {
        logger.error("RunsViewModel error occurred", error: error)
        
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
