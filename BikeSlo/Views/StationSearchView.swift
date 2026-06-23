import SwiftUI

struct StationSearchView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = StationsViewModel()
    @State private var selectedStation: BikeStation?

    private var stations: [BikeStation] {
        viewModel.filtered(visibleNetworks: appState.visibleNetworks)
    }

    var body: some View {
        NavigationStack {
            listContent
                .navigationTitle("Stations")
                .navigationDestination(item: $selectedStation) { station in
                    StationDetailView(station: station)
                }
        }
        .onAppear {
            if viewModel.allStations.isEmpty {
                viewModel.loadStations()
            }
        }
    }

    @ViewBuilder
    private var listContent: some View {
        @Bindable var vm = viewModel
        List {
            if viewModel.isLoading && viewModel.allStations.isEmpty {
                loadingRow
            } else if let error = viewModel.error {
                errorRow(error)
            } else if stations.isEmpty {
                emptyRow
            } else {
                ForEach(stations) { station in
                    StationRow(station: station)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedStation = station }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            let isFav = appState.isFavorite(station)
                            Button {
                                appState.toggleFavorite(station)
                            } label: {
                                Label(isFav ? "Unfavorite" : "Favorite",
                                      systemImage: isFav ? "star.slash.fill" : "star.fill")
                            }
                            .tint(isFav ? .gray : .yellow)
                        }
                        .stationContextMenu(station: station, appState: appState) {
                            selectedStation = station
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $vm.searchText, prompt: "Search stations…")
        .refreshable { viewModel.loadStations() }
    }

    private var loadingRow: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading stations…")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            Spacer()
        }
        .padding()
        .listRowBackground(Color.clear)
    }

    private func errorRow(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Loading error", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.headline)
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Try again") { viewModel.loadStations() }
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 8)
    }

    private var emptyRow: some View {
        HStack {
            Spacer()
            Text(viewModel.searchText.isEmpty ? "No stations" : "No results for «\(viewModel.searchText)»")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .listRowBackground(Color.clear)
    }
}

#Preview {
    StationSearchView()
        .environment(AppState())
}
