import SwiftUI
import Charts

/// Runs screen displaying past run history with Strava-like card layout
struct RunsView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = RunsViewModel()
    @State private var showingFilterSheet = false
    @State private var showingSortSheet = false
    @State private var searchText = ""
    private let logger = Logger.ui
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with statistics
                if viewModel.hasRuns {
                    headerStatsView
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                // Search and filter bar
                searchAndFilterBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Main content
                mainContent
            }
            .navigationTitle("Runs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingSortSheet = true
                        }) {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                        }
                        
                        Button(action: {
                            showingFilterSheet = true
                        }) {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        }
                        
                        Button(action: {
                            viewModel.clearFilters()
                        }) {
                            Label("Clear All", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshRuns()
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(
                    selectedFilter: $viewModel.selectedFilterOption,
                    onDismiss: { showingFilterSheet = false }
                )
            }
            .sheet(isPresented: $showingSortSheet) {
                SortSheet(
                    selectedSort: $viewModel.selectedSortOption,
                    onDismiss: { showingSortSheet = false }
                )
            }
        }
        .onAppear {
            viewModel.loadRuns()
        }
        .onChange(of: searchText) { newValue in
            viewModel.searchText = newValue
        }
    }
    
    // MARK: - Header Stats View with Chart
    private var headerStatsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart title
            Text("Last 7 Days")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Chart
            Chart(viewModel.weeklyChartData) { data in
                BarMark(
                    x: .value("Day", data.dayName),
                    y: .value("Distance", data.distance)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 120)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let distance = value.as(Double.self) {
                            Text("\(distance, specifier: "%.1f")")
                        }
                    }
                    AxisGridLine()
                    AxisTick()
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                    AxisTick()
                }
            }
            .chartYAxisLabel("Distance (km)", position: .leading)
            
            // Summary stats below chart
            HStack(spacing: 16) {
                Text("Runs: \(viewModel.runCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Distance: \(viewModel.totalDistance)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Time: \(viewModel.totalDuration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Search and Filter Bar
    private var searchAndFilterBar: some View {
        HStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search runs...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
            )
            
            // Filter indicator
            if viewModel.selectedFilterOption != .all {
                Button(action: {
                    showingFilterSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        Text(viewModel.selectedFilterOption.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            } else if viewModel.filteredAndSortedRuns.isEmpty {
                emptyStateView
            } else {
                runsList
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading runs...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                viewModel.loadRuns()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No runs found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start your first run to see it here!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Runs List
    private var runsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredAndSortedRuns) { run in
                    RunCard(run: run)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Stat Card
private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Filter Sheet
private struct FilterSheet: View {
    @Binding var selectedFilter: RunsViewModel.FilterOption
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(RunsViewModel.FilterOption.allCases, id: \.self) { option in
                    Button(action: {
                        selectedFilter = option
                        onDismiss()
                    }) {
                        HStack {
                            Text(option.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedFilter == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Runs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Sort Sheet
private struct SortSheet: View {
    @Binding var selectedSort: RunsViewModel.SortOption
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(RunsViewModel.SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        selectedSort = option
                        onDismiss()
                    }) {
                        HStack {
                            Text(option.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedSort == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort Runs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    RunsView()
}
