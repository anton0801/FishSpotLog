import SwiftUI

struct AddSpotView: View {
    @Binding var spots: [Spot]
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var waterType: WaterType = .lake
    @State private var result: FishingResult = .good
    @State private var selectedFish: Set<String> = []
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.darkBackground, .futuristicBlue.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                Form {
                    Section(header: FuturisticSectionHeader(text: "Spot Details")) {
                        FuturisticTextField(text: $name, placeholder: "Spot Name")
                        Picker("Water Type", selection: $waterType) {
                            ForEach(WaterType.allCases) { type in
                                HStack {
                                    Image(systemName: type.icon)
                                    Text(type.rawValue)
                                }.tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.accentWhite)
                        
                        Picker("Fishing Result", selection: $result) {
                            ForEach(FishingResult.allCases) { res in
                                HStack {
                                    Image(systemName: res.icon)
                                        .foregroundColor(res.neonColor)
                                    Text(res.rawValue)
                                }.tag(res)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.accentWhite)
                    }
                    .listRowBackground(Color.darkBackground.opacity(0.7))
                    
                    Section(header: FuturisticSectionHeader(text: "Fish Types")) {
                        ForEach(fishTypes, id: \.name) { fish in
                            FuturisticToggleRow(title: fish.name, icon: fish.icon, isSelected: selectedFish.contains(fish.name)) {
                                if selectedFish.contains(fish.name) {
                                    selectedFish.remove(fish.name)
                                } else {
                                    selectedFish.insert(fish.name)
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.darkBackground.opacity(0.7))
                    
                    Section(header: FuturisticSectionHeader(text: "Notes")) {
                        TextEditor(text: $notes)
                            .frame(minHeight: 150)
                            .foregroundColor(.accentWhite)
                            .background(Color.darkBackground.opacity(0.5))
                            .cornerRadius(15)
                    }
                    .listRowBackground(Color.darkBackground.opacity(0.7))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add New Spot")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.accentWhite.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newSpot = Spot(id: UUID(), name: name, waterType: waterType, result: result, fishCaught: Array(selectedFish), notes: notes, date: Date())
                        spots.append(newSpot)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(.neonYellow)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                if isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
        .foregroundColor(.primary)
    }
}


struct FuturisticSectionHeader: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.futuristicCyan)
            .padding(.bottom, 5)
    }
}

struct FuturisticTextField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .foregroundColor(.accentWhite)
            .padding()
            .background(Color.darkBackground.opacity(0.5))
            .cornerRadius(15)
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.futuristicCyan.opacity(0.5), lineWidth: 1))
    }
}


struct CurrentPhaseScreenFishSpot: View {
    @ObservedObject var viewModel: SplashViewFishViewModel
    
    var body: some View {
        Group {
            switch viewModel.currentScreenState {
            case .setup:
                EmptyView()
                
            case .operational:
                if viewModel.fishSpotLog != nil {
                    FishSpotLogMainView()
                } else {
                    ContentView()
                }
                
            case .legacy:
                ContentView()
                
            case .disconnected:
                FishSpotIssueWifiView()
            }
        }
    }
}

struct FuturisticToggleRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.futuristicCyan)
                Text(title)
                    .foregroundColor(.accentWhite)
                if isSelected {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.neonYellow)
                }
            }
        }
    }
}

struct ActivateLegacyUseCase {
    let repo: MainFishRepository
    func perform() {
        repo.updateAppState("Inactive")
        repo.markAsRun()
    }
}
struct RetrieveCachedLogUseCase {
    let repo: MainFishRepository
    func perform() -> URL? {
        repo.retrieveStoredLog()
    }
}
struct CacheSuccessfulLogUseCase {
    let repo: MainFishRepository
    func perform(log: String) {
        repo.storeLog(log)
        repo.updateAppState("LogView")
        repo.markAsRun()
    }
}
