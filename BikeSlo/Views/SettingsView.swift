import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

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

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
