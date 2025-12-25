import SwiftUI


protocol MainFishRepository {
    func storeLog(_ url: String)
    func updateAppState(_ state: String)
    func markAsRun()
    var isInitialRun: Bool { get }
    func retrieveStoredLog() -> URL?
    func retrieveAppState() -> String?
    func updateLastPermRequest(_ date: Date)
    func updatePermsAccepted(_ accepted: Bool)
    func retrieveLastPermRequest() -> Date?
    func retrievePushToken() -> String?
    func retrieveLanguageCode() -> String
    func retrieveAppIdentifier() -> String
    func retrieveFirebaseID() -> String?
    func retrieveAppStoreID() -> String
    func retrieveTrackingID() -> String
    func updatePermsDenied(_ denied: Bool)
    func retrievePermsAccepted() -> Bool
    func retrievePermsDenied() -> Bool
    func retrieveOrganicData(linkData: [String: Any]) async throws -> [String: Any]
    func retrieveServerLog(data: [String: Any]) async throws -> URL
}

enum WaterType: String, Codable, CaseIterable, Identifiable, Equatable {
    case river = "River"
    case lake = "Lake"
    case pond = "Pond"
    case sea = "Sea"
    
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .river: return "waveform.path"
        case .lake: return "drop.fill"
        case .pond: return "drop.circle.fill"
        case .sea: return "water.waves"
        }
    }
    var gradient: Gradient {
        switch self {
        case .river: return Gradient(colors: [.blue, .cyan])
        case .lake: return Gradient(colors: [.teal, .blue])
        case .pond: return Gradient(colors: [.green, .teal])
        case .sea: return Gradient(colors: [.indigo, .blue])
        }
    }
    
    static func ==(lhs: WaterType, rhs: WaterType) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}


struct PhaseRegulatorUseCase {
    let repo: MainFishRepository
    func perform(trackingData: [String: Any], initial: Bool, currentURL: URL?, interimURL: String?) -> FishSpotLogStates {
        if trackingData.isEmpty {
            return .legacy
        }
        if repo.retrieveAppState() == "Inactive" {
            return .legacy
        }
        if initial && (trackingData["af_status"] as? String == "Organic") {
            return .setup
        }
        if let interim = interimURL, let url = URL(string: interim), currentURL == nil {
            return .operational
        }
        return .setup
    }
}

extension Color {
    static let futuristicBlue = Color.blue.opacity(0.7)
    static let futuristicGreen = Color.green.opacity(0.6)
    static let futuristicCyan = Color.cyan
    static let neonYellow = Color.yellow
    static let darkBackground = Color.black.opacity(0.9)
    static let accentWhite = Color.white.opacity(0.9)
}

struct AppPushExtractor {
    
    func extract(info: [AnyHashable: Any]) -> String? {
        var parsedLink: String?
        if let link = info["url"] as? String {
            parsedLink = link
        } else if let subInfo = info["data"] as? [String: Any],
                  let subLink = subInfo["url"] as? String {
            parsedLink = subLink
        }
        if let activeLink = parsedLink {
            return activeLink
        }
        return nil
    }
    
}

