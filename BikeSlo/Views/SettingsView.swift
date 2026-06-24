import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                Section {
                    networkToggle(.bicikelj)
                    networkToggle(.nomago)
                } header: {
                    Text("Bike systems")
                } footer: {
                    Text("Choose which systems appear in the Nearby, Search and map views.")
                }

                Section {
                    Button {
                        reactivateLocation()
                    } label: {
                        Label("Reactivate location access", systemImage: "location.fill")
                    }
                } header: {
                    Text("Location")
                } footer: {
                    Text(locationFooter)
                }

                Section("About") {
                    LabeledContent("App", value: "BikeSlo")
                    LabeledContent("Version", value: appVersion)
                    Link(destination: URL(string: "https://citybik.es")!) {
                        Label("Data source: CityBikes", systemImage: "link")
                    }
                }

                Section {
                    Text("Live bike availability for BicikeLJ and Nomago in Ljubljana. This is not an official app of either operator.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func networkToggle(_ network: BikeNetwork) -> some View {
        Toggle(isOn: Binding(
            get: { appState.isVisible(network) },
            set: { appState.setNetwork(network, visible: $0) }
        )) {
            Label {
                Text(network.isElectric ? "\(network.displayName) (e-bikes)" : network.displayName)
            } icon: {
                Image(systemName: network.systemImage).foregroundStyle(network.color)
            }
        }
        .tint(network.color)
    }

    /// Če dovoljenje še ni bilo vprašano, prikažemo sistemski poziv;
    /// sicer uporabnika pošljemo v Nastavitve, kjer ga lahko ponovno omogoči.
    private func reactivateLocation() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestPermission()
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }

    private var locationFooter: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Allow location access to show the nearest bike stations."
        case .denied, .restricted:
            return "Location access is off. Tap to open Settings and turn it back on."
        default:
            return "Location access is on. Tap to manage it in Settings."
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(LocationManager())
}
