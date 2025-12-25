import SwiftUI

struct SplashView: View {
    
    @StateObject private var viewModel = SplashViewFishViewModel()
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.currentScreenState == .setup || viewModel.visibleNotificationsPushPrompt {
                SplashLogView()
            }
            
            CurrentPhaseScreenFishSpot(viewModel: viewModel)
                .opacity(viewModel.visibleNotificationsPushPrompt ? 0 : 1)
            
            if viewModel.visibleNotificationsPushPrompt {
                CheckPermissionsView(
                    onAllow: viewModel.processGrantPerm,
                    onSkip: viewModel.processSkipPerm
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SplashLogView: View {
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var progress: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotation: Double = 0.0
    @State private var waveOffset: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            ZStack {
                RadialGradient(gradient: Gradient(colors: [.darkBackground, .futuristicBlue]), center: .center, startRadius: 0, endRadius: 500)
                    .ignoresSafeArea()
                
                Image("background_main")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                
                VStack {
                    ZStack {
                        // Pulsing circle behind icon
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [.futuristicCyan.opacity(0.3), .clear]), startPoint: .center, endPoint: .bottomTrailing))
                            .frame(width: 250, height: 250)
                            .scaleEffect(pulseScale)
                            .opacity(0.5)
                        
                        // Fish icon with rotation and scale
                        Image(systemName: "fish.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.futuristicCyan, .neonYellow]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: .futuristicCyan.opacity(0.8), radius: 20, x: 0, y: 0)
                            .scaleEffect(scale)
                            .opacity(opacity)
                            .rotationEffect(.degrees(rotation))
                        
                        // Circular progress bar around icon
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(LinearGradient(gradient: Gradient(colors: [.neonYellow, .futuristicCyan]), startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: .neonYellow.opacity(0.8), radius: 10)
                            .opacity(opacity)
                    }
                }
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.5)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                    
                    // Progress bar animation
                    withAnimation(.linear(duration: 2.0)) {
                        progress = 1.0
                    }
                    
                    // Pulse animation
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseScale = 1.2
                    }
                    
                    // Slow rotation for icon
                    withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
                        rotation = 360.0
                    }
                    
                    // Wave offset animation
                    withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                        waveOffset = 1000
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct WaveBackground: View {
    let offset: CGFloat
    
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [.darkBackground, .futuristicBlue]), center: .center, startRadius: 0, endRadius: 500)
            
            WaveShape(offset: offset)
                .fill(LinearGradient(gradient: Gradient(colors: [.futuristicCyan.opacity(0.2), .futuristicBlue.opacity(0.3)]), startPoint: .leading, endPoint: .trailing))
                .frame(height: 1000)
            
            WaveShape(offset: offset + 200)
                .fill(LinearGradient(gradient: Gradient(colors: [.neonYellow.opacity(0.1), .futuristicCyan.opacity(0.2)]), startPoint: .leading, endPoint: .trailing))
                .frame(height: 1000)
                .opacity(0.5)
        }
    }
}

// Wave Shape
struct WaveShape: Shape {
    
    var offset: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let frequency: CGFloat = 0.01
        let amplitude: CGFloat = 50
        
        path.move(to: CGPoint(x: 0, y: rect.height))
        
        for x in stride(from: 0, to: rect.width + 10, by: 10) {
            let y = sin(x * frequency + offset * frequency) * amplitude + rect.height / 2
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
}

