import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage: Int = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingPage(title: "Save your fishing spots", image: "map.pin")
                .tag(0)
            
            OnboardingPage(title: "Track fish and results", image: "fish")
                .tag(1)
            
            OnboardingPage(title: "Analyze your best places", image: "chart.line.uptrend.xyaxis")
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(.page)
        .frame(maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            HStack {
                if currentPage > 0 {
                    Button("Skip") {
                        onComplete()
                    }
                    .foregroundColor(.gray)
                }
                Spacer()
                if currentPage < 2 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .foregroundColor(.blue)
                } else {
                    Button("Start") {
                        onComplete()
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }
}

struct OnboardingPage: View {
    let title: String
    let image: String
    
    var body: some View {
        VStack {
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}

