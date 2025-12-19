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
    
    static func == (lhs: FishingResult, rhs: FishingResult) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

let fishTypes: [String] = ["Pike", "Carp", "Perch", "Trout", "Bass", "Salmon", "Catfish", "Walleye"]
