import SwiftUI

enum FishingResult: String, Codable, CaseIterable, Identifiable, Equatable {
    case poor = "Poor"
    case good = "Good"
    case excellent = "Excellent"
    
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .poor: return .red
        case .good: return .yellow
        case .excellent: return .green
        }
    }
    var icon: String {
        switch self {
        case .poor: return "xmark.circle.fill"
        case .good: return "checkmark.circle.fill"
        case .excellent: return "star.circle.fill"
        }
    }
    var neonColor: Color {
        switch self {
        case .poor: return .pink
        case .good: return .orange
        case .excellent: return .cyan
        }
    }
    
    static func == (lhs: FishingResult, rhs: FishingResult) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}


struct CheckPermissionsPromptUseCase {
    let repo: MainFishRepository
    func perform() -> Bool {
        guard !repo.retrievePermsAccepted(),
              !repo.retrievePermsDenied() else {
            return false
        }
        if let previous = repo.retrieveLastPermRequest(),
           Date().timeIntervalSince(previous) < 259200 {
            return false
        }
        return true
    }
}
struct StartInitialSequenceUseCase {
    func perform() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
    }
}
struct ProcessSkipPermUseCase {
    let repo: MainFishRepository
    func perform() {
        repo.updateLastPermRequest(Date())
    }
}
struct ProcessGrantPermUseCase {
    let repo: MainFishRepository
    func perform(accepted: Bool) {
        repo.updatePermsAccepted(accepted)
        if !accepted {
            repo.updatePermsDenied(true)
        }
    }
}
struct RetrieveOrganicTrackingUseCase {
    let repo: MainFishRepository
    func perform(linkData: [String: Any]) async throws -> [String: Any] {
        try await repo.retrieveOrganicData(linkData: linkData)
    }
}
struct RetrieveLogConfigUseCase {
    let repo: MainFishRepository
    func perform(trackingData: [String: Any]) async throws -> URL {
        try await repo.retrieveServerLog(data: trackingData)
    }
}



let fishTypes: [(name: String, icon: String)] = [
    ("Pike", "fish.fill"),
    ("Carp", "fish.circle.fill"),
    ("Perch", "fish"),
    ("Trout", "fish.fill"),
    ("Bass", "fish.circle"),
    ("Salmon", "fish.fill"),
    ("Catfish", "fish"),
    ("Walleye", "fish.circle.fill")
]
