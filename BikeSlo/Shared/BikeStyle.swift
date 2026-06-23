import SwiftUI
import MapKit

extension Color {
    /// Glavna barva aplikacije — vijolična, usklajena z ikono (Bike.icon gradient).
    static let brand = Color(red: 0.582, green: 0.216, blue: 1.0)
}

extension BikeNetwork {
    /// Barva blagovne znamke sistema.
    var color: Color {
        switch self {
        case .bicikelj: return Color(red: 0.00, green: 0.62, blue: 0.60) // teal
        case .nomago:   return Color(red: 0.18, green: 0.66, blue: 0.33) // zelena
        }
    }

    /// Oba sistema uporabljata "bicycle"; Nomagova električnost je nakazana
    /// z ločeno bolt oznako, ne z drugo ikono.
    var systemImage: String {
        switch self {
        case .bicikelj: return "bicycle"
        case .nomago:   return "bicycle"
        }
    }
}

extension BikeStation {
    /// Barvno stanje glede na število razpoložljivih koles.
    var availabilityColor: Color {
        switch freeBikes {
        case 0:      return .red
        case 1...2:  return .orange
        default:     return .green
        }
    }

    /// Odpre kolesarsko navigacijo do postaje v aplikaciji Zemljevidi.
    func openInMaps() {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = name.capitalized
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeCycling])
    }
}
