import SwiftUI

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
    
    static func == (lhs: WaterType, rhs: WaterType) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}
