import Foundation

// CityBikes API — agregator izposoje koles, brez ključa.
// GET /v2/networks/{id} vrne postaje sistema z živo razpoložljivostjo.
// Ljubljana: "bicikelj" (BicikeLJ) in "nomago-ljubljana" (Nomago, e-kolesa).
// Postaja že nosi free_bikes/empty_slots, zato ni ločenega klica kot pri prihodih avtobusov.

enum CityBikesError: LocalizedError {
    case badURL
    case networkError(Error)
    case httpError(Int)
    case decodingError(String)
    case allFailed([String])

    var errorDescription: String? {
        switch self {
        case .badURL:
            return String(localized: "Invalid request.")
        case .networkError(let e):
            return String(localized: "Network error: \(e.localizedDescription)")
        case .httpError(let code):
            return String(localized: "Server error (\(code)).")
        case .decodingError(let raw):
            return String(localized: "Couldn't read data. \(raw.prefix(120))")
        case .allFailed(let errors):
            return String(localized: "No data available.\n\(errors.joined(separator: "\n"))")
        }
    }
}

actor CityBikesAPIService {
    static let shared = CityBikesAPIService()

    private let base = "https://api.citybik.es/v2/networks"
    private let session: URLSession

    /// Sendable rezultat enega sistema (za task group).
    private struct NetworkResult: Sendable {
        let stations: [BikeStation]
        let error: String?
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 25
        session = URLSession(configuration: config)
    }

    /// Prenese postaje iz vseh podprtih sistemov sočasno in jih združi.
    func fetchAllStations() async throws -> [BikeStation] {
        var all: [BikeStation] = []
        var errors: [String] = []

        // Oba sistema sočasno — rezultat task groupa mora biti Sendable.
        await withTaskGroup(of: NetworkResult.self) { group in
            for network in BikeNetwork.allCases {
                group.addTask {
                    do {
                        let stations = try await self.fetchStations(for: network)
                        return NetworkResult(stations: stations, error: nil)
                    } catch {
                        return NetworkResult(stations: [], error: "[\(network.displayName)] \(error.localizedDescription)")
                    }
                }
            }
            for await result in group {
                all.append(contentsOf: result.stations)
                if let error = result.error { errors.append(error) }
            }
        }

        // Vržemo napako le, če nismo dobili NIČESAR.
        if all.isEmpty && !errors.isEmpty {
            throw CityBikesError.allFailed(errors)
        }
        return all
    }

    /// Prenese postaje enega sistema in jih označi z njegovo mrežo.
    func fetchStations(for network: BikeNetwork) async throws -> [BikeStation] {
        guard let url = URL(string: "\(base)/\(network.apiId)") else {
            throw CityBikesError.badURL
        }
        let data = try await performRequest(url)
        do {
            let response = try JSONDecoder().decode(NetworkDetailResponse.self, from: data)
            let stations = response.network.stations ?? []
            return stations.map { station in
                var tagged = station
                tagged.network = network
                return tagged
            }
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw CityBikesError.decodingError(raw)
        }
    }

    private func performRequest(_ url: URL) async throws -> Data {
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                throw CityBikesError.networkError(URLError(.badServerResponse))
            }
            guard (200...299).contains(http.statusCode) else {
                throw CityBikesError.httpError(http.statusCode)
            }
            return data
        } catch let e as CityBikesError {
            throw e
        } catch {
            throw CityBikesError.networkError(error)
        }
    }
}
