import SwiftUI
import Observation

/// Osvežuje živo razpoložljivost ene postaje vsakih 30 sekund.
@Observable
class StationDetailViewModel {
    var station: BikeStation
    var isRefreshing: Bool = false
    var lastUpdated: Date? = nil

    private let refreshInterval: TimeInterval = 30
    private var refreshTimer: Timer?

    init(station: BikeStation) {
        self.station = station
    }

    deinit {
        refreshTimer?.invalidate()
    }

    func start() {
        Task { await refresh() }

        stop()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.refresh() }
        }
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    @MainActor
    func refresh() async {
        isRefreshing = true
        do {
            // Cel sistem se osveži z enim klicem; izberemo svojo postajo.
            let stations = try await CityBikesAPIService.shared.fetchStations(for: station.network)
            if let updated = stations.first(where: { $0.id == station.id }) {
                station = updated
                lastUpdated = Date()
            }
        } catch {
            // Ob napaki obdržimo prejšnje vrednosti — ni potrebe po prekinitvi.
        }
        isRefreshing = false
    }
}
