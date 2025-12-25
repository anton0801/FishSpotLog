import SwiftUI
import WebKit

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage: Int = 0
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.darkBackground, .futuristicBlue.opacity(0.5)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                OnboardingPage(title: "Save your fishing spots", image: "map.pin", gradient: .init(colors: [.futuristicCyan, .blue]))
                    .tag(0)
                
                OnboardingPage(title: "Track fish and results", image: "fish", gradient: .init(colors: [.neonYellow, .yellow]))
                    .tag(1)
                
                OnboardingPage(title: "Analyze your best places", image: "chart.line.uptrend.xyaxis", gradient: .init(colors: [.futuristicGreen, .green]))
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
                        .font(.headline)
                        .foregroundColor(.accentWhite.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.futuristicBlue.opacity(0.3))
                        .cornerRadius(20)
                        .shadow(color: .futuristicCyan, radius: 5)
                    }
                    Spacer()
                    if currentPage < 2 {
                        Button("Next") {
                            withAnimation(.easeInOut) {
                                currentPage += 1
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.accentWhite)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(LinearGradient(gradient: Gradient(colors: [.futuristicCyan, .blue]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(20)
                        .shadow(color: .futuristicCyan, radius: 10)
                    } else {
                        Button("Start") {
                            onComplete()
                        }
                        .font(.headline)
                        .foregroundColor(.accentWhite)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(LinearGradient(gradient: Gradient(colors: [.neonYellow, .yellow]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(20)
                        .shadow(color: .neonYellow, radius: 10)
                    }
                }
                .padding()
            }
        }
    }
}

struct OnboardingPage: View {
    let title: String
    let image: String
    let gradient: Gradient
    
    @State private var rotation: Double = 0.0
    
    var body: some View {
        VStack {
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .foregroundStyle(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .futuristicCyan.opacity(0.5), radius: 15)
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
                .onAppear {
                    withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            
            Text(title)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(.accentWhite)
                .multilineTextAlignment(.center)
                .padding()
                .shadow(color: .futuristicBlue, radius: 5)
        }
        .padding()
        .background(Color.darkBackground.opacity(0.2))
        .cornerRadius(30)
        .shadow(color: .futuristicCyan.opacity(0.3), radius: 20)
        .padding(.horizontal, 20)
    }
}

struct SpotHostView: UIViewRepresentable {
    let spotLink: URL
    
    @StateObject private var spotManager = SpotManager()
    
    func makeCoordinator() -> SpotNavigationHandler {
        SpotNavigationHandler(manager: spotManager)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        spotManager.initMainView()
        spotManager.mainSpotView.uiDelegate = context.coordinator
        spotManager.mainSpotView.navigationDelegate = context.coordinator
        
        spotManager.retrieveCachedSpot()
        spotManager.mainSpotView.load(URLRequest(url: spotLink))
        
        return spotManager.mainSpotView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
