import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NearbyView()
                .tabItem {
                    Label("Nearby", systemImage: "location.fill")
                }
                .tag(0)

            StationSearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)

            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.brand)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .environment(LocationManager())
}
