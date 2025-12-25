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
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.darkBackground, Color.futuristicCyan.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        StatsCard(title: "Total Fishing Days", value: "\(totalFishingDays)", gradient: .init(colors: [Color.futuristicBlue, .cyan]))
                        StatsCard(title: "Best Water Type", value: bestWaterType?.rawValue ?? "None", gradient: .init(colors: [Color.futuristicGreen, .green]))
                        StatsCard(title: "Most Frequent Fish", value: mostFrequentFish ?? "None", gradient: .init(colors: [Color.neonYellow, .yellow]))
                        StatsCard(title: "Most Successful Spot", value: mostSuccessfulSpot?.name ?? "None", gradient: .init(colors: [Color.futuristicCyan, .blue]))
                        
                        Section(header: FuturisticSectionHeader(text: "Fishing by Months")) {
                            ForEach(fishingByMonths.sorted(by: { $0.key < $1.key }), id: \.key) { month, count in
                                HStack {
                                    Text(month)
                                        .foregroundColor(Color.accentWhite.opacity(0.7))
                                    Spacer()
                                    Text("\(count)")
                                        .foregroundColor(Color.accentWhite)
                                }
                                .padding()
                                .background(Color.darkBackground.opacity(0.6))
                                .cornerRadius(15)
                            }
                        }
                        
                        Section(header: FuturisticSectionHeader(text: "Results")) {
                            ForEach(FishingResult.allCases) { res in
                                HStack {
                                    Image(systemName: res.icon)
                                        .foregroundColor(res.neonColor)
                                    Text(res.rawValue)
                                        .foregroundColor(Color.accentWhite.opacity(0.7))
                                    Spacer()
                                    Text("\(resultsCount[res] ?? 0)")
                                        .foregroundColor(Color.accentWhite)
                                }
                                .padding()
                                .background(Color.darkBackground.opacity(0.6))
                                .cornerRadius(15)
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Stats")
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let gradient: Gradient
    
    @State private var hover: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.accentWhite.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.accentWhite)
        }
        .padding()
        .background(Color.darkBackground.opacity(0.8))
        .cornerRadius(25)
        .overlay(RoundedRectangle(cornerRadius: 25).stroke(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2))
        .shadow(color: .futuristicCyan.opacity(hover ? 0.8 : 0.4), radius: 15)
        .scaleEffect(hover ? 1.05 : 1.0)
        .animation(.spring(), value: hover)
        .onHover { hover in
            self.hover = hover
        }
    }
}
