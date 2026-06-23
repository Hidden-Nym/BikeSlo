import SwiftUI
import CoreLocation
import MapKit

private enum NearbyDisplayMode: String, CaseIterable, Identifiable {
    case list, map
    var id: String { rawValue }
}

struct NearbyView: View {
    @Environment(AppState.self) private var appState
    @Environment(LocationManager.self) private var locationManager
    @State private var viewModel = StationsViewModel()
    @State private var selectedStation: BikeStation?

    @State private var nearbyStations: [BikeStation] = []
    @State private var lastSortLocation: CLLocation?
    @State private var displayMode: NearbyDisplayMode = .list
    @State private var cameraPosition: MapCameraPosition = .userLocation(
        fallback: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 46.0569, longitude: 14.5058),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        )
    )
    @State private var visibleRegion: MKCoordinateRegion?

    /// Posodobi seznam najbližjih le ob premiku >25 m ali spremembi vhodnih podatkov.
    private func recomputeNearbyIfNeeded() {
        guard let current = locationManager.userLocation else {
            if !nearbyStations.isEmpty { nearbyStations = [] }
            return
        }
        if let last = lastSortLocation, current.distance(from: last) < 25, !nearbyStations.isEmpty {
            return
        }
        let visible = viewModel.allStations.filter { appState.isVisible($0.network) }
        let sorted = visible
            .compactMap { station -> (BikeStation, Double)? in
                guard let dist = locationManager.distance(to: station) else { return nil }
                return (station, dist)
            }
            .sorted { $0.1 < $1.1 }
            .prefix(25)
            .map { $0.0 }
        nearbyStations = Array(sorted)
        lastSortLocation = current
    }

    var body: some View {
        NavigationStack {
            Group {
                if !locationManager.isAuthorized {
                    permissionView
                } else if viewModel.isLoading && viewModel.allStations.isEmpty {
                    loadingView
                } else if nearbyStations.isEmpty {
                    emptyView
                } else {
                    switch displayMode {
                    case .list: stationsList
                    case .map: stationsMap
                    }
                }
            }
            .navigationTitle(displayMode == .map ? Text(verbatim: "") : Text("Nearby"))
            .navigationBarTitleDisplayMode(displayMode == .map ? .inline : .large)
            .toolbar {
                if locationManager.isAuthorized && !nearbyStations.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                displayMode = (displayMode == .list) ? .map : .list
                            }
                        } label: {
                            Image(systemName: displayMode == .list ? "map.fill" : "list.bullet")
                        }
                        .accessibilityLabel(displayMode == .list ? "Show map" : "Show list")
                    }
                }
            }
            .navigationDestination(item: $selectedStation) { station in
                StationDetailView(station: station)
            }
        }
        .onAppear {
            locationManager.requestPermission()
            locationManager.startUpdating()
            if viewModel.allStations.isEmpty {
                viewModel.loadStations()
            }
            recomputeNearbyIfNeeded()
        }
        .onChange(of: locationManager.userLocation) { _, _ in
            recomputeNearbyIfNeeded()
        }
        .onChange(of: viewModel.allStations) { _, _ in
            lastSortLocation = nil
            recomputeNearbyIfNeeded()
        }
        .onChange(of: appState.visibleNetworks) { _, _ in
            lastSortLocation = nil
            recomputeNearbyIfNeeded()
        }
    }

    private var permissionView: some View {
        ContentUnavailableView {
            Label("Location", systemImage: "location.slash.fill")
        } description: {
            Text("Allow location access to show the nearest bike stations.")
        } actions: {
            Button("Allow Location") {
                locationManager.requestPermission()
            }
            .buttonStyle(.borderedProminent)
            .tint(.brand)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text("Finding nearby stations…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No stations", systemImage: "bicycle")
        } description: {
            Text("No stations found nearby. Pull to refresh or check your filters.")
        }
    }

    private var stationsList: some View {
        List {
            ForEach(nearbyStations) { station in
                StationRow(station: station, distance: locationManager.formattedDistance(to: station))
                    .contentShape(Rectangle())
                    .onTapGesture { selectedStation = station }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        favoriteButton(for: station)
                    }
                    .stationContextMenu(station: station, appState: appState) {
                        selectedStation = station
                    }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { viewModel.loadStations() }
    }

    /// Vse postaje (glede na vidne sisteme) v trenutno prikazanem območju karte —
    /// tako se ob premiku/zoom-u karte pokažejo postaje povsod, ne le najbližje uporabniku.
    private var stationsInVisibleRegion: [BikeStation] {
        let pool = viewModel.allStations.filter { appState.isVisible($0.network) }
        guard let region = visibleRegion else {
            return nearbyStations  // pred prvim premikom kamere pokažemo najbližje
        }
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        let filtered = pool.lazy.filter { station in
            station.latitude >= minLat && station.latitude <= maxLat &&
            station.longitude >= minLon && station.longitude <= maxLon
        }
        return Array(filtered.prefix(400))
    }

    private var stationsMap: some View {
        Map(position: $cameraPosition, selection: $selectedStation) {
            UserAnnotation()
            ForEach(stationsInVisibleRegion) { station in
                Marker(station.name.capitalized,
                       systemImage: station.network.systemImage,
                       coordinate: station.coordinate)
                    .tint(station.availabilityColor)
                    .tag(station)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            visibleRegion = context.region
        }
    }

    @ViewBuilder
    private func favoriteButton(for station: BikeStation) -> some View {
        let isFav = appState.isFavorite(station)
        Button {
            appState.toggleFavorite(station)
        } label: {
            Label(isFav ? "Unfavorite" : "Favorite",
                  systemImage: isFav ? "star.slash.fill" : "star.fill")
        }
        .tint(isFav ? .gray : .yellow)
    }
}

#Preview {
    NearbyView()
        .environment(AppState())
        .environment(LocationManager())
}
