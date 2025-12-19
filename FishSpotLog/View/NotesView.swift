import SwiftUI

struct NotesView: View {
    @Binding var notes: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            TextEditor(text: $notes)
                .padding()
                .navigationTitle("General Notes")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

