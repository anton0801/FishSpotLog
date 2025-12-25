import Foundation
import AppsFlyerLib
import Firebase
import FirebaseMessaging


struct TrackingBuilder {
    private var appID = ""
    private var devKey = ""
    private var uid = ""
    private let endpoint = "https://gcdsdk.appsflyer.com/install_data/v4.0/"
    func assignAppID(_ id: String) -> Self { duplicate(appID: id) }
    func assignUID(_ id: String) -> Self { duplicate(uid: id) }
    func assignDevKey(_ key: String) -> Self { duplicate(devKey: key) }
    func generate() -> URL? {
        guard !appID.isEmpty, !devKey.isEmpty, !uid.isEmpty else { return nil }
        var parts = URLComponents(string: endpoint + "id" + appID)!
        parts.queryItems = [
            URLQueryItem(name: "devkey", value: devKey),
            URLQueryItem(name: "device_id", value: uid)
        ]
        return parts.url
    }
    private func duplicate(appID: String = "", devKey: String = "", uid: String = "") -> Self {
        var instance = self
        if !appID.isEmpty { instance.appID = appID }
        if !devKey.isEmpty { instance.devKey = devKey }
        if !uid.isEmpty { instance.uid = uid }
        return instance
    }
}

struct Spot: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var waterType: WaterType
    var result: FishingResult
    var fishCaught: [String]
    var notes: String
    var date: Date
    
    static func == (lhs: Spot, rhs: Spot) -> Bool {
        lhs.id == rhs.id
    }
}

// General Notes model
struct GeneralNotes: Codable, Equatable {
    var notes: String = ""
    
    static func == (lhs: GeneralNotes, rhs: GeneralNotes) -> Bool {
        lhs.notes == rhs.notes
    }
}


class FishRepositoryImpl: MainFishRepository {
    private let defaults: UserDefaults
    private let tracker: AppsFlyerLib
    init(defaults: UserDefaults = .standard, tracker: AppsFlyerLib = .shared()) {
        self.defaults = defaults
        self.tracker = tracker
    }
    func storeLog(_ url: String) {
        defaults.set(url, forKey: "stored_log")
    }
    func updateAppState(_ state: String) {
        defaults.set(state, forKey: "app_state")
    }
    func markAsRun() {
        defaults.set(true, forKey: "hasRunPreviously")
    }
    var isInitialRun: Bool {
        !defaults.bool(forKey: "hasRunPreviously")
    }
    func retrieveStoredLog() -> URL? {
        if let stored = defaults.string(forKey: "stored_log"),
           let url = URL(string: stored) {
            return url
        }
        return nil
    }
    func retrieveAppState() -> String? {
        defaults.string(forKey: "app_state")
    }
    func updateLastPermRequest(_ date: Date) {
        defaults.set(date, forKey: "last_perm_request")
    }
    func updatePermsAccepted(_ accepted: Bool) {
        defaults.set(accepted, forKey: "perms_accepted")
    }
    func retrieveLastPermRequest() -> Date? {
        defaults.object(forKey: "last_perm_request") as? Date
    }
    func retrievePushToken() -> String? {
        defaults.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
    }
    func retrieveLanguageCode() -> String {
        Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
    }
    func retrieveAppIdentifier() -> String {
        AppConstants.bundleId
    }
    func retrieveFirebaseID() -> String? {
        FirebaseApp.app()?.options.gcmSenderID
    }
    func retrieveAppStoreID() -> String {
        "id(AppConstants.appsFlyerAppID)"
    }
    func retrieveTrackingID() -> String {
        tracker.getAppsFlyerUID()
    }
    func updatePermsDenied(_ denied: Bool) {
        defaults.set(denied, forKey: "perms_denied")
    }
    func retrievePermsAccepted() -> Bool {
        defaults.bool(forKey: "perms_accepted")
    }
    func retrievePermsDenied() -> Bool {
        defaults.bool(forKey: "perms_denied")
    }
    func retrieveOrganicData(linkData: [String: Any]) async throws -> [String: Any] {
        let builder = TrackingBuilder()
            .assignAppID(AppConstants.appsFlyerAppID)
            .assignDevKey(AppConstants.appsFlyerDevKey)
            .assignUID(retrieveTrackingID())
            .generate()
        guard let url = builder else {
            throw NSError(domain: "TrackingError", code: 0)
        }
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let httpResp = resp as? HTTPURLResponse,
              httpResp.statusCode == 200,
              let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "TrackingError", code: 1)
        }
        var merged = jsonData
        for (k, v) in linkData where merged[k] == nil {
            merged[k] = v
        }
        return merged
    }
    func retrieveServerLog(data: [String: Any]) async throws -> URL {
        guard let endpoint = URL(string: "https://fishspotlog.com/config.php") else {
            throw NSError(domain: "LogError", code: 0)
        }
        var requestData = data
        requestData["os"] = "iOS"
        requestData["af_id"] = retrieveTrackingID()
        requestData["bundle_id"] = retrieveAppIdentifier()
        requestData["firebase_project_id"] = retrieveFirebaseID()
        requestData["store_id"] = retrieveAppStoreID()
        requestData["push_token"] = retrievePushToken()
        requestData["locale"] = retrieveLanguageCode()
        guard let body = try? JSONSerialization.data(withJSONObject: requestData) else {
            throw NSError(domain: "LogError", code: 1)
        }
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        let (responseData, _) = try await URLSession.shared.data(for: req)
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let success = json["ok"] as? Bool, success,
              let logStr = json["url"] as? String,
              let logURL = URL(string: logStr) else {
            throw NSError(domain: "LogError", code: 2)
        }
        return logURL
    }
}
