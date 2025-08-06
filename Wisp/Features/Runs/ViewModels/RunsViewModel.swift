import Foundation
import Combine

/// View model for the Runs screen displaying past run history
@MainActor
final class RunsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var runs: [PastRun] = []
    @Published var ghostResults: [GhostRaceResult] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedSortOption: SortOption = .dateDescending
    @Published var selectedFilterOption: FilterOption = .all
    
    // MARK: - Properties
    private let logger = Logger.ui
    private var cancellables = Set<AnyCancellable>()
    private var allRuns: [PastRun] = []
    private var allGhostResults: [GhostRaceResult] = []
    
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
    var filteredAndSortedRuns: [PastRun] {
        var filtered = allRuns
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { run in
                run.generatedTitle.localizedCaseInsensitiveContains(searchText) ||
                run.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        switch selectedFilterOption {
        case .all:
            break
        case .won:
            let wonRunIds = allGhostResults.filter { $0.didWin }.map { $0.runId }
            filtered = filtered.filter { wonRunIds.contains($0.id) }
        case .lost:
            let lostRunIds = allGhostResults.filter { !$0.didWin }.map { $0.runId }
            filtered = filtered.filter { lostRunIds.contains($0.id) }
        case .thisWeek:
            let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date >= oneWeekAgo }
        case .thisMonth:
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date >= oneMonthAgo }
        case .thisYear:
            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date >= oneYearAgo }
        }
        
        // Apply sorting
        switch selectedSortOption {
        case .dateDescending:
            filtered.sort { $0.date > $1.date }
        case .dateAscending:
            filtered.sort { $0.date < $1.date }
        case .distanceDescending:
            filtered.sort { $0.distance > $1.distance }
        case .distanceAscending:
            filtered.sort { $0.distance < $1.distance }
        case .durationDescending:
            filtered.sort { $0.duration > $1.duration }
        case .durationAscending:
            filtered.sort { $0.duration < $1.duration }
        case .paceAscending:
            filtered.sort { $0.averagePace < $1.averagePace }
        case .paceDescending:
            filtered.sort { $0.averagePace > $1.averagePace }
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
        let total = allRuns.reduce(0) { $0 + $1.duration }
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
    
    /// Get ghost result for a specific run
    func getGhostResult(for run: PastRun) -> GhostRaceResult? {
        return allGhostResults.first { $0.runId == run.id }
    }
    
    /// Update run title
    func updateRunTitle(for run: PastRun, newTitle: String) {
        logger.info("Updating run title for run \(run.id)")
        
        // Find the run in allRuns and update it
        if let index = allRuns.firstIndex(where: { $0.id == run.id }) {
            allRuns[index].updateTitle(newTitle)
            
            // Update the published runs array
            if let filteredIndex = runs.firstIndex(where: { $0.id == run.id }) {
                runs[filteredIndex].updateTitle(newTitle)
            }
            
            // TODO: Persist the change to backend
            logger.info("Run title updated successfully")
        }
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
            // TODO: Replace with actual API call
            // try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
            
            // Load extended mock data
            let loadedRuns = PastRun.extendedMockData
            let loadedGhostResults = GhostRaceResult.extendedMockData
            
            allRuns = loadedRuns
            allGhostResults = loadedGhostResults
            
            // Update filtered runs
            updateFilteredRuns()
        } catch {
            logger.error("Failed to load runs", error: error)
            errorMessage = "Failed to load runs. Please try again."
        }
        
        isLoading = false
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
