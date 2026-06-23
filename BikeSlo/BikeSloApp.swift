import SwiftUI

@main
struct BikeSloApp: App {
    @State private var appState = AppState()
    @State private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(locationManager)
        }
    }
}
