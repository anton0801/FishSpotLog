import SwiftUI

struct SpotsView: View {
    @Binding var spots: [Spot]
    @State private var showAddSpot: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach($spots) { $spot in
                    NavigationLink(destination: SpotDetailsView(spot: $spot, spots: $spots)) {
                        SpotCard(spot: spot)
                    }
                }
                .onDelete { indices in
                    spots.remove(atOffsets: indices)
                }
            }
            .navigationTitle("Spots")
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

struct SpotCard: View {
    let spot: Spot
    
    var body: some View {
        HStack {
            Image(systemName: spot.waterType.icon)
                .foregroundColor(.blue)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(spot.name)
                    .font(.headline)
                Text(spot.waterType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: spot.result.icon)
                .foregroundColor(spot.result.color)
                .font(.title3)
            Text(spot.date, style: .date)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct SpotDetailsView: View {
    @Binding var spot: Spot
    @Binding var spots: [Spot]
    @State private var showEdit: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var timesFished: Int = 1
    var overallResult: FishingResult { spot.result }
    var lastDate: Date { spot.date }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(spot.name)
                    .font(.largeTitle)
                    .bold()
                
                HStack {
                    Image(systemName: spot.waterType.icon)
                    Text(spot.waterType.rawValue)
                }
                .font(.title3)
                .foregroundColor(.blue)
                
                Section(header: Text("Information").font(.headline)) {
                    InfoRow(title: "Overall Result", value: spot.result.rawValue, icon: spot.result.icon, color: spot.result.color)
                    InfoRow(title: "Times Fished", value: "\(timesFished)", icon: "calendar")
                    InfoRow(title: "Last Date", value: lastDate.formatted(date: .abbreviated, time: .omitted), icon: "clock")
                }
                
                Section(header: Text("Fish Caught").font(.headline)) {
                    ForEach(spot.fishCaught, id: \.self) { fish in
                        Text(fish)
                    }
                }
                
                Section(header: Text("Notes").font(.headline)) {
                    Text(spot.notes)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Spot Details")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button("Edit Spot") {
                        showEdit = true
                    }
                    .foregroundColor(.blue)
                    Spacer()
                    Button("Delete Spot") {
                        if let index = spots.firstIndex(where: { $0.id == spot.id }) {
                            spots.remove(at: index)
                        }
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditSpotView(spot: $spot)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

struct EditSpotView: View {
    @Binding var spot: Spot
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var waterType: WaterType
    @State private var result: FishingResult
    @State private var selectedFish: Set<String>
    @State private var notes: String
    
    init(spot: Binding<Spot>) {
        _name = State(initialValue: spot.wrappedValue.name)
        _waterType = State(initialValue: spot.wrappedValue.waterType)
        _result = State(initialValue: spot.wrappedValue.result)
        _selectedFish = State(initialValue: Set(spot.wrappedValue.fishCaught))
        _notes = State(initialValue: spot.wrappedValue.notes)
        self._spot = spot
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Same as AddSpotView
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
            .navigationTitle("Edit Spot")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        spot.name = name
                        spot.waterType = waterType
                        spot.result = result
                        spot.fishCaught = Array(selectedFish)
                        spot.notes = notes
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
