import SwiftUI

struct ContentView: View {
    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @AppStorage("spotsData") private var spotsData: Data = Data()
    @AppStorage("generalNotesData") private var generalNotesData: Data = Data()
    @AppStorage("units") private var units: String = "kg"
    
    @State private var spots: [Spot] = []
    @State private var generalNotes: GeneralNotes = GeneralNotes()
    @State private var showOnboarding: Bool = true
    @State private var showSplash: Bool = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                showSplash = false
                                showOnboarding = isFirstLaunch
                            }
                        }
                    }
            } else if showOnboarding {
                OnboardingView {
                    isFirstLaunch = false
                    showOnboarding = false
                }
            } else {
                TabView {
                    HomeView(spots: $spots)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                    
                    SpotsView(spots: $spots)
                        .tabItem {
                            Label("Spots", systemImage: "map.fill")
                        }
                    
                    StatsView(spots: $spots)
                        .tabItem {
                            Label("Stats", systemImage: "chart.bar.fill")
                        }
                    
                    SettingsView(spots: $spots, generalNotes: $generalNotes, units: $units)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                .accentColor(.blue)
                .onAppear {
                    loadData()
                }
                .onChange(of: spots) { _ in
                    saveData()
                }
                .onChange(of: generalNotes) { _ in
                    saveData()
                }
            }
        }
    }
    
    private func loadData() {
        if let decodedSpots = try? JSONDecoder().decode([Spot].self, from: spotsData) {
            spots = decodedSpots
        }
        if let decodedNotes = try? JSONDecoder().decode(GeneralNotes.self, from: generalNotesData) {
            generalNotes = decodedNotes
        }
    }
    
    private func saveData() {
        if let encodedSpots = try? JSONEncoder().encode(spots) {
            spotsData = encodedSpots
        }
        if let encodedNotes = try? JSONEncoder().encode(generalNotes) {
            generalNotesData = encodedNotes
        }
    }
}

#Preview {
    ContentView()
}
