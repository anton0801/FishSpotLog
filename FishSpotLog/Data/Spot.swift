import Foundation

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
