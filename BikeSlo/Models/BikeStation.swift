import Foundation
import CoreLocation

// Modeli so nonisolated, ker se dekodirajo znotraj actorja (CityBikesAPIService),
// projekt pa privzeto izolira na MainActor — sicer Codable ne prevede v Swift 6.

// MARK: - Bike Network

/// Sistemi izposoje koles v Ljubljani, ki jih aplikacija podpira.
nonisolated enum BikeNetwork: String, Codable, CaseIterable, Identifiable, Sendable {
    case bicikelj
    case nomago

    var id: String { rawValue }

    /// CityBikes network id — del poti v /v2/networks/{id}
    var apiId: String {
        switch self {
        case .bicikelj: return "bicikelj"
        case .nomago:   return "nomago-ljubljana"
        }
    }

    var displayName: String {
        switch self {
        case .bicikelj: return "BicikeLJ"
        case .nomago:   return "Nomago"
        }
    }

    /// Nomago Ljubljana je sistem električnih koles, BicikeLJ klasičnih.
    var isElectric: Bool { self == .nomago }
}

// MARK: - Bike Station

/// Postaja za izposojo koles z živo razpoložljivostjo.
/// CityDecode shrani kapaciteto/naslov v "extra"; "network" ni del API odgovora —
/// ga označimo po prenosu in shranimo skupaj s priljubljenimi.
nonisolated struct BikeStation: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let freeBikes: Int
    let emptySlots: Int
    let capacity: Int?
    let address: String?
    var network: BikeNetwork

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Skupno število mest na postaji (rezerva: kolesa + prosta mesta).
    var totalDocks: Int {
        if let capacity, capacity > 0 { return capacity }
        return freeBikes + emptySlots
    }

    /// Ni prostih mest za vračilo kolesa.
    var isFull: Bool { emptySlots == 0 && totalDocks > 0 }

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude
        case freeBikes = "free_bikes"
        case emptySlots = "empty_slots"
        case extra, network
    }

    enum ExtraKeys: String, CodingKey {
        case slots, address
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        latitude = (try? c.decode(Double.self, forKey: .latitude)) ?? 0
        longitude = (try? c.decode(Double.self, forKey: .longitude)) ?? 0
        freeBikes = (try? c.decode(Int.self, forKey: .freeBikes)) ?? 0
        emptySlots = (try? c.decode(Int.self, forKey: .emptySlots)) ?? 0
        // CityBikes JSON nima "network" — servis ga nastavi po prenosu. Iz shranjenih
        // priljubljenih pa se prebere normalno (tam ga zapišemo).
        network = (try? c.decode(BikeNetwork.self, forKey: .network)) ?? .bicikelj

        if let extra = try? c.nestedContainer(keyedBy: ExtraKeys.self, forKey: .extra) {
            capacity = try? extra.decode(Int.self, forKey: .slots)
            address = try? extra.decode(String.self, forKey: .address)
        } else {
            capacity = nil
            address = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(latitude, forKey: .latitude)
        try c.encode(longitude, forKey: .longitude)
        try c.encode(freeBikes, forKey: .freeBikes)
        try c.encode(emptySlots, forKey: .emptySlots)
        try c.encode(network, forKey: .network)
        var extra = c.nestedContainer(keyedBy: ExtraKeys.self, forKey: .extra)
        try extra.encodeIfPresent(capacity, forKey: .slots)
        try extra.encodeIfPresent(address, forKey: .address)
    }

    /// Ročni init za predoglede in testiranje.
    init(id: String, name: String, latitude: Double = 0, longitude: Double = 0,
         freeBikes: Int, emptySlots: Int, capacity: Int? = nil, address: String? = nil,
         network: BikeNetwork = .bicikelj) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.freeBikes = freeBikes
        self.emptySlots = emptySlots
        self.capacity = capacity
        self.address = address
        self.network = network
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: BikeStation, rhs: BikeStation) -> Bool { lhs.id == rhs.id }
}

// MARK: - API Response

/// CityBikes odgovor: { "network": { "stations": [...] } }
nonisolated struct NetworkDetailResponse: Decodable {
    let network: NetworkDetail

    nonisolated struct NetworkDetail: Decodable {
        let stations: [BikeStation]?
    }
}
