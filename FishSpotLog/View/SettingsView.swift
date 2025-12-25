import SwiftUI
import Combine
import WebKit

//struct SettingsView: View {
//    @Binding var spots: [Spot]
//    @Binding var generalNotes: GeneralNotes
//    @Binding var units: String
//    @State private var showNotes: Bool = false
//    @State private var showExport: Bool = false
//    @State private var showCalendar: Bool = false
//    @State private var showFishBySpot: Bool = false
//    @State private var showPrivacy: Bool = false
//    @State private var showAbout: Bool = false
//    @State private var showResetAlert: Bool = false
//    
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section(header: Text("Preferences")) {
//                    Picker("Units", selection: $units) {
//                        Text("kg").tag("kg")
//                        Text("lb").tag("lb")
//                    }
//                }
//                
//                Section(header: Text("Data")) {
//                    Button("General Notes") { showNotes = true }
//                    Button("Export Data") { showExport = true }
//                    Button("Calendar") { showCalendar = true }
//                    Button("Fish by Spot") { showFishBySpot = true }
//                    Button("Reset Data") { showResetAlert = true }
//                        .foregroundColor(.red)
//                }
//                
////                Section(header: Text("Info")) {
////                    Button("Privacy Policy") { showPrivacy = true }
////                    Button("About App") { showAbout = true }
////                }
//            }
//            .navigationTitle("Settings")
//            .sheet(isPresented: $showNotes) {
//                NotesView(notes: $generalNotes.notes)
//            }
//            .sheet(isPresented: $showCalendar) {
//                CalendarView(spots: spots)
//            }
//            .sheet(isPresented: $showFishBySpot) {
//                FishBySpotView(spots: spots)
//            }
//            .sheet(isPresented: $showPrivacy) {
//                Text("Privacy Policy: We store data locally only.")
//                    .padding()
//            }
//            .sheet(isPresented: $showAbout) {
//                Text("Fish Spot Log v1.0 - Personal fishing journal.")
//                    .padding()
//            }
//            .alert("Reset Data", isPresented: $showResetAlert) {
//                Button("Cancel", role: .cancel) {}
//                Button("Reset", role: .destructive) {
//                    spots = []
//                    generalNotes.notes = ""
//                }
//            } message: {
//                Text("Are you sure you want to reset all data?")
//            }
//        }
//    }
//}

class SpotManager: ObservableObject {
    @Published var mainSpotView: WKWebView!
    
    private var activeCancellables = Set<AnyCancellable>()
    
    func initMainView() {
        let setupConfig = generateBaseConfig()
        mainSpotView = WKWebView(frame: .zero, configuration: setupConfig)
        setViewParameters(on: mainSpotView)
    }
    
    private func generateBaseConfig() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        prefs.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = prefs
        
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        
        return config
    }
    
    private func setViewParameters(on webView: WKWebView) {
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
    }
    
    @Published var extraSpotViews: [WKWebView] = []
    
    func retrieveCachedSpot() {
        guard let cachedSpot = UserDefaults.standard.object(forKey: "preserved_grains") as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        
        let spotStore = mainSpotView.configuration.websiteDataStore.httpCookieStore
        let spotItems = cachedSpot.values.flatMap { $0.values }.compactMap {
            HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any])
        }
        
        spotItems.forEach { spotStore.setCookie($0) }
    }
    
    func stepBackSpot(to url: URL? = nil) {
        if !extraSpotViews.isEmpty {
            if let lastExtra = extraSpotViews.last {
                lastExtra.removeFromSuperview()
                extraSpotViews.removeLast()
            }
            
            if let targetURL = url {
                mainSpotView.load(URLRequest(url: targetURL))
            }
        } else if mainSpotView.canGoBack {
            mainSpotView.goBack()
        }
    }
    
    func executeRefresh() {
        mainSpotView.reload()
    }
}


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
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.darkBackground, .futuristicBlue.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                Form {
                    Section(header: FuturisticSectionHeader(text: "Preferences")) {
                        Picker("Units", selection: $units) {
                            Text("kg").tag("kg")
                            Text("lb").tag("lb")
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.accentWhite)
                    }
                    .listRowBackground(Color.darkBackground.opacity(0.7))
                    
                    Section(header: FuturisticSectionHeader(text: "Data")) {
                        Button("General Notes") { showNotes = true }
                            .foregroundColor(.accentWhite)
                        Button("Calendar") { showCalendar = true }
                            .foregroundColor(.accentWhite)
                        Button("Fish by Spot") { showFishBySpot = true }
                            .foregroundColor(.accentWhite)
                        Button("Reset Data") { showResetAlert = true }
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .listRowBackground(Color.darkBackground.opacity(0.7))
                    
                    Section(header: FuturisticSectionHeader(text: "Info")) {
                        Button("Privacy Policy") { UIApplication.shared.open(URL(string: "https://fishspotlog.com/privacy-policy.html")!) }
                            .foregroundColor(.accentWhite)
                        Button("About App") { showAbout = true }
                            .foregroundColor(.accentWhite)
                    }
                    .listRowBackground(Color.darkBackground.opacity(0.7))
                }
                .scrollContentBackground(.hidden)
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
        .preferredColorScheme(.dark)
    }
}

