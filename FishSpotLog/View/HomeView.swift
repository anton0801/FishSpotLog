import SwiftUI

struct HomeView: View {
    @Binding var spots: [Spot]
    @State private var showAddSpot: Bool = false
    
    var totalSpots: Int { spots.count }
    var bestSpot: Spot? {
        spots.max(by: { $0.result.color == .red && $1.result.color != .red ||
                        $0.result.color == .yellow && $1.result.color == .green ? true : false })
    }
    var lastSpot: Spot? { spots.max(by: { $0.date < $1.date }) }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    OverviewCard(title: "Total Spots", value: "\(totalSpots)", icon: "map.pin")
                    if let best = bestSpot {
                        OverviewCard(title: "Best Spot", value: best.name, icon: "star.fill")
                    }
                    if let last = lastSpot {
                        OverviewCard(title: "Last Fishing Spot", value: last.name, icon: "clock.fill")
                    }
                }
                .padding()
            }
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: { showAddSpot = true }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showAddSpot) {
                AddSpotView(spots: $spots)
            }
        }
    }
}

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title2)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.title3)
                    .bold()
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

