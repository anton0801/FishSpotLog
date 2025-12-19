import SwiftUI

struct SettingsView: View {
    @Binding var spots: [Spot]
    @Binding var generalNotes: GeneralNotes
    @Binding var units: String
    @State private var showNotes: Bool = false
    @State private var showExport: Bool = false
    @State private var showCalendar: Bool = false
    @State private var showFishBySpot: Bool = false
    @State private var showPrivacy: Bool = false
    @State private var showAbout: Bool = false
    @State private var showResetAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Preferences")) {
                    Picker("Units", selection: $units) {
                        Text("kg").tag("kg")
                        Text("lb").tag("lb")
                    }
                }
                
                Section(header: Text("Data")) {
                    Button("General Notes") { showNotes = true }
                    Button("Export Data") { showExport = true }
                    Button("Calendar") { showCalendar = true }
                    Button("Fish by Spot") { showFishBySpot = true }
                    Button("Reset Data") { showResetAlert = true }
                        .foregroundColor(.red)
                }
                
//                Section(header: Text("Info")) {
//                    Button("Privacy Policy") { showPrivacy = true }
//                    Button("About App") { showAbout = true }
//                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showNotes) {
                NotesView(notes: $generalNotes.notes)
            }
            .sheet(isPresented: $showCalendar) {
                CalendarView(spots: spots)
            }
            .sheet(isPresented: $showFishBySpot) {
                FishBySpotView(spots: spots)
            }
            .sheet(isPresented: $showPrivacy) {
                Text("Privacy Policy: We store data locally only.")
                    .padding()
            }
            .sheet(isPresented: $showAbout) {
                Text("Fish Spot Log v1.0 - Personal fishing journal.")
                    .padding()
            }
            .alert("Reset Data", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    spots = []
                    generalNotes.notes = ""
                }
            } message: {
                Text("Are you sure you want to reset all data?")
            }
        }
    }
}

