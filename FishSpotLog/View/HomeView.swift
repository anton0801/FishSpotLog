import SwiftUI
import WebKit
import Combine

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
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.darkBackground, .futuristicBlue.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        OverviewCard(title: "Total Spots", value: "\(totalSpots)", icon: "map.pin", gradient: .init(colors: [.futuristicCyan, .blue]))
                        if let best = bestSpot {
                            OverviewCard(title: "Best Spot", value: best.name, icon: "star.fill", gradient: .init(colors: [.neonYellow, .yellow]))
                        }
                        if let last = lastSpot {
                            OverviewCard(title: "Last Fishing Spot", value: last.name, icon: "clock.fill", gradient: .init(colors: [.futuristicGreen, .green]))
                        }
                    }
                    .padding()
                }
                .navigationTitle("Overview")
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        FloatingAddButton(showAddSpot: $showAddSpot)
                    }
                }
                .sheet(isPresented: $showAddSpot) {
                    AddSpotView(spots: $spots)
                }
            }
        }
    }
}

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: Gradient
    
    @State private var hover: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .futuristicCyan, radius: 5)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.accentWhite.opacity(0.7))
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.accentWhite)
            }
            Spacer()
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

struct FloatingAddButton: View {
    @Binding var showAddSpot: Bool
    
    var body: some View {
        Button(action: { showAddSpot = true }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.darkBackground)
                .frame(width: 60, height: 60)
                .background(LinearGradient(gradient: Gradient(colors: [.futuristicCyan, .neonYellow]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(Circle())
                .shadow(color: .futuristicCyan, radius: 10)
        }
    }
}

struct FishSpotLogMainView: View {
    
    @State private var activeSpotLink: String? = nil
    
    var body: some View {
        ZStack {
            if let activeSpotLink = activeSpotLink {
                if let spotLink = URL(string: activeSpotLink) {
                    SpotHostView(spotLink: spotLink)
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: configureSpotLink)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempUrl"))) { _ in
            if let tempSpot = UserDefaults.standard.string(forKey: "temp_url"), !tempSpot.isEmpty {
                activeSpotLink = nil
                activeSpotLink = tempSpot
                UserDefaults.standard.removeObject(forKey: "temp_url")
            }
        }
    }
    
    private func configureSpotLink() {
        let tempSpot = UserDefaults.standard.string(forKey: "temp_url")
        let storedSpot = UserDefaults.standard.string(forKey: "stored_log") ?? ""
        activeSpotLink = tempSpot ?? storedSpot
        
        if tempSpot != nil {
            UserDefaults.standard.removeObject(forKey: "temp_url")
        }
    }
}
