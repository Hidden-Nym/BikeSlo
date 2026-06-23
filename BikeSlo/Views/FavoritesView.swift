import SwiftUI

struct FavoritesView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedStation: BikeStation?

    var body: some View {
        NavigationStack {
            Group {
                if appState.favoriteStations.isEmpty {
                    emptyState
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favorites")
            .navigationDestination(item: $selectedStation) { station in
                StationDetailView(station: station)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No favorites", systemImage: "star.slash")
        } description: {
            Text("Find a station and tap the star ☆ to save it here.")
        }
    }

    private var favoritesList: some View {
        List {
            ForEach(appState.favoriteStations) { station in
                StationRow(station: station)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedStation = station }
                    .stationContextMenu(station: station, appState: appState) {
                        selectedStation = station
                    }
            }
            .onDelete { indexSet in
                var favorites = appState.favoriteStations
                favorites.remove(atOffsets: indexSet)
                appState.favoriteStations = favorites
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    FavoritesView()
        .environment(AppState())
}
