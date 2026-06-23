import Foundation
import CoreLocation
import Observation

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    var userLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    /// Razdalja od uporabnika do postaje v metrih (nil, če ni lokacije).
    func distance(to station: BikeStation) -> Double? {
        guard let userLocation else { return nil }
        let stationLocation = CLLocation(latitude: station.latitude, longitude: station.longitude)
        return userLocation.distance(from: stationLocation)
    }

    /// Oblikovana razdalja za prikaz.
    func formattedDistance(to station: BikeStation) -> String? {
        guard let meters = distance(to: station) else { return nil }
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if isAuthorized {
            manager.startUpdatingLocation()
        }
    }
}
