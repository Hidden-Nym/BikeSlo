import SwiftUI
import MapKit

// MARK: - Network badge

/// Majhna obarvana oznaka sistema (BicikeLJ / Nomago).
struct NetworkBadge: View {
    let network: BikeNetwork

    var body: some View {
        HStack(spacing: 3) {
            if network.isElectric {
                Image(systemName: "bolt.fill").font(.system(size: 7, weight: .bold))
            }
            Text(network.displayName)
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .lineLimit(1)
        .padding(.horizontal, 5)
        .padding(.vertical, 1)
        .background(network.color, in: RoundedRectangle(cornerRadius: 4))
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Availability pill (kolesa · prosta mesta)

/// Kompakten prikaz: razpoložljiva kolesa in prosta mesta, obarvan po stanju.
struct AvailabilityPill: View {
    let station: BikeStation

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "bicycle").font(.system(size: 9, weight: .bold))
            Text("\(station.freeBikes)").monospacedDigit()
            Text("·").foregroundStyle(.secondary)
            Image(systemName: "parkingsign").font(.system(size: 9, weight: .bold))
            Text("\(station.emptySlots)").monospacedDigit()
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(station.availabilityColor)
        .lineLimit(1)
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(station.availabilityColor.opacity(0.12), in: Capsule())
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Station row

/// Vrstica postaje za sezname (Nearby, Search, Favorites).
struct StationRow: View {
    let station: BikeStation
    var distance: String? = nil
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 12) {
            iconTile

            VStack(alignment: .leading, spacing: 4) {
                Text(station.name.capitalized)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    NetworkBadge(network: station.network)
                    AvailabilityPill(station: station)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            trailing

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }

    private var iconTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(station.network.color.opacity(0.15))
                .frame(width: 38, height: 38)
            Image(systemName: station.network.systemImage)
                .foregroundStyle(station.network.color)
                .font(.system(size: 16, weight: .medium))
        }
    }

    @ViewBuilder
    private var trailing: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let distance {
                Text(distance)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.brand)
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize()
            }
            if appState.isFavorite(station) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption2)
            }
        }
    }
}

// MARK: - Context menu

private struct StationContextMenu: ViewModifier {
    let station: BikeStation
    let appState: AppState
    let onOpen: () -> Void

    func body(content: Content) -> some View {
        content.contextMenu {
            Button {
                onOpen()
            } label: {
                Label("Open", systemImage: "arrow.up.forward.app")
            }

            Button {
                appState.toggleFavorite(station)
            } label: {
                let fav = appState.isFavorite(station)
                Label(fav ? "Remove favorite" : "Add to favorites",
                      systemImage: fav ? "star.slash" : "star")
            }

            Button {
                station.openInMaps()
            } label: {
                Label("Directions", systemImage: "map")
            }
        }
    }
}

extension View {
    func stationContextMenu(station: BikeStation, appState: AppState, onOpen: @escaping () -> Void) -> some View {
        modifier(StationContextMenu(station: station, appState: appState, onOpen: onOpen))
    }
}
