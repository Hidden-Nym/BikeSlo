import SwiftUI
import Observation

/// Globalno stanje aplikacije — priljubljene postaje (shranjene v UserDefaults).
@Observable
class AppState {
    // Posnetek postaje ob shranjevanju; živi števci se osvežijo šele v podrobnostih.
    var favoriteStations: [BikeStation] {
        didSet {
            if let data = try? JSONEncoder().encode(favoriteStations) {
                UserDefaults.standard.set(data, forKey: Self.favoritesKey)
            }
        }
    }

    /// Sistemi, ki naj bodo prikazani (preklopi v Nastavitvah).
    var visibleNetworks: Set<BikeNetwork> {
        didSet {
            let raw = visibleNetworks.map(\.rawValue)
            UserDefaults.standard.set(raw, forKey: Self.visibleNetworksKey)
        }
    }

    private static let favoritesKey = "favoriteStations"
    private static let visibleNetworksKey = "visibleNetworks"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.favoritesKey),
           let saved = try? JSONDecoder().decode([BikeStation].self, from: data) {
            self.favoriteStations = saved
        } else {
            self.favoriteStations = []
        }

        if let raw = UserDefaults.standard.array(forKey: Self.visibleNetworksKey) as? [String] {
            // Prazen ali pokvarjen shranjen nabor → pokaži vse sisteme, ne nobenega.
            let nets = Set(raw.compactMap(BikeNetwork.init(rawValue:)))
            self.visibleNetworks = nets.isEmpty ? Set(BikeNetwork.allCases) : nets
        } else {
            self.visibleNetworks = Set(BikeNetwork.allCases)
        }
    }

    func isVisible(_ network: BikeNetwork) -> Bool {
        visibleNetworks.contains(network)
    }

    func setNetwork(_ network: BikeNetwork, visible: Bool) {
        if visible {
            visibleNetworks.insert(network)
        } else {
            visibleNetworks.remove(network)
        }
    }

    func addFavorite(_ station: BikeStation) {
        if !favoriteStations.contains(where: { $0.id == station.id }) {
            favoriteStations.append(station)
        }
    }

    func removeFavorite(_ station: BikeStation) {
        favoriteStations.removeAll { $0.id == station.id }
    }

    func isFavorite(_ station: BikeStation) -> Bool {
        favoriteStations.contains { $0.id == station.id }
    }

    func toggleFavorite(_ station: BikeStation) {
        if isFavorite(station) { removeFavorite(station) } else { addFavorite(station) }
    }
}
