import SwiftUI
import MapKit

/// Podrobnosti postaje z živo razpoložljivostjo — analog ArrivalsView pri avtobusih.
struct StationDetailView: View {
    @State private var viewModel: StationDetailViewModel
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase

    init(station: BikeStation) {
        _viewModel = State(initialValue: StationDetailViewModel(station: station))
    }

    private var station: BikeStation { viewModel.station }

    var body: some View {
        List {
            availabilitySection
            detailsSection
            mapSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(station.name.capitalized)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState.toggleFavorite(station)
                } label: {
                    Image(systemName: appState.isFavorite(station) ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
                }
            }
        }
        .refreshable { await viewModel.refresh() }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.start() } else { viewModel.stop() }
        }
        .overlay(alignment: .bottom) {
            if let updated = viewModel.lastUpdated {
                lastUpdatedBar(updated)
            }
        }
    }

    // MARK: - Hero: razpoložljivost

    private var availabilitySection: some View {
        Section {
            VStack(spacing: 18) {
                HStack(alignment: .center, spacing: 0) {
                    statColumn(
                        value: station.freeBikes,
                        label: String(localized: "Available"),
                        sublabel: station.network.isElectric ? String(localized: "e-bikes") : String(localized: "bikes"),
                        icon: "bicycle",
                        color: station.availabilityColor
                    )
                    Divider().frame(height: 64)
                    statColumn(
                        value: station.emptySlots,
                        label: String(localized: "Free"),
                        sublabel: String(localized: "docks"),
                        icon: "parkingsign",
                        color: station.isFull ? .red : .brand
                    )
                }
                capacityBar
            }
            .padding(.vertical, 10)
            .animation(.snappy, value: station.freeBikes)
        } header: {
            liveHeader
        }
    }

    private func statColumn(value: Int, label: String, sublabel: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
            Text("\(value)")
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(sublabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var capacityBar: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                let total = max(station.totalDocks, 1)
                let width = geo.size.width * CGFloat(station.freeBikes) / CGFloat(total)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2))
                    Capsule()
                        .fill(station.availabilityColor)
                        .frame(width: max(0, min(geo.size.width, width)))
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(station.freeBikes) / \(station.totalDocks)")
                    .monospacedDigit()
                Spacer()
                Text("capacity")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private var liveHeader: some View {
        HStack {
            Text("Availability")
                .textCase(nil)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            HStack(spacing: 4) {
                Circle().fill(Color.green).frame(width: 6, height: 6)
                Text("LIVE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - Podrobnosti

    private var detailsSection: some View {
        Section("Details") {
            LabeledContent {
                NetworkBadge(network: station.network)
            } label: {
                Label("System", systemImage: "building.2")
            }

            if let address = station.address, !address.isEmpty {
                LabeledContent {
                    Text(address)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Address", systemImage: "mappin.and.ellipse")
                }
            }

            LabeledContent {
                Text("\(station.totalDocks)").foregroundStyle(.secondary).monospacedDigit()
            } label: {
                Label("Total docks", systemImage: "square.grid.2x2")
            }

            if station.network.isElectric {
                Label("Electric bikes", systemImage: "bolt.fill")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Karta

    private var mapSection: some View {
        Section {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: station.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
            ))) {
                Marker(station.name.capitalized,
                       systemImage: station.network.systemImage,
                       coordinate: station.coordinate)
                    .tint(station.network.color)
            }
            .frame(height: 180)
            .listRowInsets(EdgeInsets())
            .allowsHitTesting(false)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    station.openInMaps()
                } label: {
                    Label("Directions", systemImage: "bicycle")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .tint(.brand)
                .padding(10)
            }
        }
    }

    private func lastUpdatedBar(_ date: Date) -> some View {
        HStack(spacing: 6) {
            if viewModel.isRefreshing {
                ProgressView().controlSize(.mini)
            }
            Text("Updated \(date.formatted(date: .omitted, time: .shortened))")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.bottom, 20)
    }
}

#Preview {
    NavigationStack {
        StationDetailView(station: BikeStation(
            id: "preview",
            name: "CANKARJEVA UL.-NAMA",
            latitude: 46.0524,
            longitude: 14.5033,
            freeBikes: 12,
            emptySlots: 8,
            capacity: 20,
            address: "Cankarjeva cesta 1"
        ))
    }
    .environment(AppState())
}
