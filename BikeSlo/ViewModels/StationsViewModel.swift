import SwiftUI
import Observation

/// Naloži in filtrira vse postaje. Uporabljajo ga Nearby in Search zavihki.
@Observable
class StationsViewModel {
    var allStations: [BikeStation] = []
    var searchText: String = ""
    var isLoading: Bool = false
    var error: String? = nil
    var lastUpdated: Date? = nil

    /// Postaje, filtrirane po vidnih sistemih in iskalnem nizu.
    func filtered(visibleNetworks: Set<BikeNetwork>) -> [BikeStation] {
        var result = allStations.filter { visibleNetworks.contains($0.network) }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                ($0.address?.lowercased().contains(query) ?? false)
            }
        }
        return result
    }

    private var loadTask: Task<Void, Never>?

    func loadStations() {
        loadTask?.cancel()
        loadTask = Task { await performLoad() }
    }

    @MainActor
    private func performLoad() async {
        if allStations.isEmpty { isLoading = true }
        error = nil

        do {
            let stations = try await CityBikesAPIService.shared.fetchAllStations()
            if !Task.isCancelled {
                allStations = stations.sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                lastUpdated = Date()
            }
        } catch {
            if !Task.isCancelled {
                self.error = error.localizedDescription
            }
        }

        isLoading = false
    }
}
