import SwiftUI

struct NotesView: View {
    @Binding var notes: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.darkBackground, .futuristicGreen.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                TextEditor(text: $notes)
                    .padding()
                    .foregroundColor(.accentWhite)
                    .background(Color.darkBackground.opacity(0.5))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.futuristicGreen.opacity(0.5)))
                    .padding()
                
                .navigationTitle("General Notes")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                            .foregroundColor(.neonYellow)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
