import SwiftUI

struct CalendarView: View {
    let spots: [Spot]
    
    var fishingDays: [Date: [Spot]] {
        Dictionary(grouping: spots, by: { Calendar.current.startOfDay(for: $0.date) })
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(fishingDays.keys.sorted(), id: \.self) { day in
                    Section(header: Text(day.formatted(date: .long, time: .omitted))) {
                        ForEach(fishingDays[day] ?? [], id: \.id) { spot in
                            Text(spot.name)
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
        }
    }
}

// Fish by Spot View
struct FishBySpotView: View {
    let spots: [Spot]
    
    var fishStats: [String: (count: Int, spots: [String])] {
        var stats: [String: (count: Int, spots: [String])] = [:]
        for spot in spots {
            for fish in spot.fishCaught {
                var current = stats[fish] ?? (0, [])
                current.count += 1
                current.spots.append(spot.name)
                stats[fish] = current
            }
        }
        return stats
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(fishStats.keys.sorted(), id: \.self) { fish in
                    VStack(alignment: .leading) {
                        Text(fish)
                            .font(.headline)
                        Text("Count: \(fishStats[fish]?.count ?? 0)")
                        Text("Spots: \(fishStats[fish]?.spots.joined(separator: ", ") ?? "")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Fish by Spot")
        }
    }
}

