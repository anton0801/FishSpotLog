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
            Form {
                Section(header: Text("Spot Details")) {
                    TextField("Spot Name", text: $name)
                    Picker("Water Type", selection: $waterType) {
                        ForEach(WaterType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    Picker("Fishing Result", selection: $result) {
                        ForEach(FishingResult.allCases) { res in
                            HStack {
                                Image(systemName: res.icon)
                                    .foregroundColor(res.color)
                                Text(res.rawValue)
                            }.tag(res)
                        }
                    }
                }
                
                Section(header: Text("Fish Types")) {
                    ForEach(fishTypes, id: \.self) { fish in
                        MultipleSelectionRow(title: fish, isSelected: selectedFish.contains(fish)) {
                            if selectedFish.contains(fish) {
                                selectedFish.remove(fish)
                            } else {
                                selectedFish.insert(fish)
                            }
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add New Spot")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newSpot = Spot(id: UUID(), name: name, waterType: waterType, result: result, fishCaught: Array(selectedFish), notes: notes, date: Date())
                        spots.append(newSpot)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
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

