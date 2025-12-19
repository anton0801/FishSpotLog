import SwiftUI

struct StatsView: View {
    @Binding var spots: [Spot]
    
    var totalFishingDays: Int {
        Set(spots.map { Calendar.current.startOfDay(for: $0.date) }).count
    }
    
    var bestWaterType: WaterType? {
        Dictionary(grouping: spots, by: { $0.waterType })
            .max(by: { $0.value.count < $1.value.count })?.key
    }
    
    var mostFrequentFish: String? {
        spots.flatMap { $0.fishCaught }
            .reduce(into: [:]) { $0[$1, default: 0] += 1 }
            .max(by: { $0.value < $1.value })?.key
    }
    
    var mostSuccessfulSpot: Spot? {
        spots.max(by: { $0.result.color == .red && $1.result.color != .red ||
                        $0.result.color == .yellow && $1.result.color == .green ? true : false })
    }
    
    var fishingByMonths: [String: Int] {
        spots.reduce(into: [:]) { counts, spot in
            let month = spot.date.formatted(.dateTime.month(.wide).year())
            counts[month, default: 0] += 1
        }
    }
    
    var resultsCount: [FishingResult: Int] {
        spots.reduce(into: [:]) { $0[$1.result, default: 0] += 1 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StatsCard(title: "Total Fishing Days", value: "\(totalFishingDays)")
                    StatsCard(title: "Best Water Type", value: bestWaterType?.rawValue ?? "None")
                    StatsCard(title: "Most Frequent Fish", value: mostFrequentFish ?? "None")
                    StatsCard(title: "Most Successful Spot", value: mostSuccessfulSpot?.name ?? "None")
                    
                    Section(header: Text("Fishing by Months").font(.headline)) {
                        ForEach(fishingByMonths.sorted(by: { $0.key < $1.key }), id: \.key) { month, count in
                            HStack {
                                Text(month)
                                Spacer()
                                Text("\(count)")
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    Section(header: Text("Results").font(.headline)) {
                        ForEach(FishingResult.allCases) { res in
                            HStack {
                                Image(systemName: res.icon)
                                    .foregroundColor(res.color)
                                Text(res.rawValue)
                                Spacer()
                                Text("\(resultsCount[res] ?? 0)")
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Stats")
        }
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.title3)
                .bold()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}
