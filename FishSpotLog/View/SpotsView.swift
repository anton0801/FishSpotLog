import SwiftUI
import WebKit

struct SpotsView: View {
    @Binding var spots: [Spot]
    @State private var showAddSpot: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.darkBackground, .futuristicGreen.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
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
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                
                .navigationTitle("Spots")
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        FloatingAddButton(showAddSpot: $showAddSpot)
                    }
                }
                .sheet(isPresented: $showAddSpot) {
                    AddSpotView(spots: $spots)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SpotCard: View {
    let spot: Spot
    @State private var hover: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: spot.waterType.icon)
                .font(.system(size: 28))
                .foregroundStyle(LinearGradient(gradient: spot.waterType.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            
            VStack(alignment: .leading) {
                Text(spot.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.accentWhite)
                Text(spot.waterType.rawValue)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.accentWhite.opacity(0.7))
            }
            Spacer()
            Image(systemName: spot.result.icon)
                .font(.system(size: 24))
                .foregroundColor(spot.result.neonColor)
            Text(spot.date, style: .date)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.accentWhite.opacity(0.6))
        }
        .padding()
        .background(Color.darkBackground.opacity(0.8))
        .cornerRadius(25)
        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.futuristicCyan.opacity(0.5), lineWidth: 1))
        .shadow(color: .futuristicCyan.opacity(hover ? 0.8 : 0.3), radius: 10)
        .scaleEffect(hover ? 1.03 : 1.0)
        .animation(.easeInOut, value: hover)
        .onHover { hover in
            self.hover = hover
        }
    }
}


class SpotNavigationHandler: NSObject, WKNavigationDelegate, WKUIDelegate {
    
    private var navigationCounter = 0
    
    init(manager: SpotManager) {
        self.spotManager = manager
        super.init()
    }
    
    private var spotManager: SpotManager
    
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard action.targetFrame == nil else { return nil }
        
        let freshView = WKWebView(frame: .zero, configuration: configuration)
        configFreshView(freshView)
        setConstraintsFor(freshView)
        
        spotManager.extraSpotViews.append(freshView)
        
        let panRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(managePanGesture))
        panRecognizer.edges = .left
        freshView.addGestureRecognizer(panRecognizer)
        
        func validateActionRequest(_ request: URLRequest) -> Bool {
            guard let pathString = request.url?.absoluteString,
                  !pathString.isEmpty,
                  pathString != "about:blank" else { return false }
            return true
        }
        
        if validateActionRequest(action.request) {
            freshView.load(action.request)
        }
        
        return freshView
    }
    
    private var previousPath: URL?
    
    private let navigationCap = 70
    
    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trustValue = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trustValue))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    private func configFreshView(_ webView: WKWebView) {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        spotManager.mainSpotView.addSubview(webView)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let adjustmentCode = """
        (function() {
            const vpTag = document.createElement('meta');
            vpTag.name = 'viewport';
            vpTag.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.head.appendChild(vpTag);
            
            const styleTag = document.createElement('style');
            styleTag.textContent = 'body { touch-action: pan-x pan-y; } input, textarea { font-size: 16px !important; }';
            document.head.appendChild(styleTag);
            
            document.addEventListener('gesturestart', function(e) { e.preventDefault(); });
            document.addEventListener('gesturechange', function(e) { e.preventDefault(); });
        })();
        """
        
        webView.evaluateJavaScript(adjustmentCode) { _, err in
            if let err = err { print("Adjustment failed: \(err)") }
        }
    }
    
    @objc private func managePanGesture(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard recognizer.state == .ended,
              let viewUnderGesture = recognizer.view as? WKWebView else { return }
        
        if viewUnderGesture.canGoBack {
            viewUnderGesture.goBack()
        } else if spotManager.extraSpotViews.last === viewUnderGesture {
            spotManager.stepBackSpot(to: nil)
        }
    }
    
    private func preserveData(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            var dataCollection: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            
            for cookie in cookies {
                var group = dataCollection[cookie.domain] ?? [:]
                if let attrs = cookie.properties {
                    group[cookie.name] = attrs
                }
                dataCollection[cookie.domain] = group
            }
            
            UserDefaults.standard.set(dataCollection, forKey: "preserved_grains")
        }
    }
    
    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects,
           let fallbackPath = previousPath {
            webView.load(URLRequest(url: fallbackPath))
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        navigationCounter += 1
        
        if navigationCounter > navigationCap {
            webView.stopLoading()
            if let fallbackPath = previousPath {
                webView.load(URLRequest(url: fallbackPath))
            }
            return
        }
        
        previousPath = webView.url
        preserveData(from: webView)
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let path = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        previousPath = path
        
        let pathScheme = (path.scheme ?? "").lowercased()
        let pathString = path.absoluteString.lowercased()
        
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let allowedStarts = ["srcdoc", "about:blank", "about:srcdoc"]
        
        let isAllowed = allowedSchemes.contains(pathScheme) ||
        allowedStarts.contains { pathString.hasPrefix($0) } ||
        pathString == "about:blank"
        
        if isAllowed {
            decisionHandler(.allow)
            return
        }
        
        UIApplication.shared.open(path, options: [:]) { _ in }
        
        decisionHandler(.cancel)
    }
    
    private func setConstraintsFor(_ webView: WKWebView) {
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: spotManager.mainSpotView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: spotManager.mainSpotView.trailingAnchor),
            webView.topAnchor.constraint(equalTo: spotManager.mainSpotView.topAnchor),
            webView.bottomAnchor.constraint(equalTo: spotManager.mainSpotView.bottomAnchor)
        ])
    }
}


struct SpotDetailsView: View {
    @Binding var spot: Spot
    @Binding var spots: [Spot]
    @State private var showEdit: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var timesFished: Int = 1 // Extend if multiple sessions per spot
    var overallResult: FishingResult { spot.result }
    var lastDate: Date { spot.date }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.darkBackground, .futuristicBlue.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    Text(spot.name)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.accentWhite, .futuristicCyan]), startPoint: .leading, endPoint: .trailing))
                        .shadow(color: Color.futuristicCyan, radius: 5)
                    
                    HStack {
                        Image(systemName: spot.waterType.icon)
                            .font(.system(size: 24))
                        Text(spot.waterType.rawValue)
                            .font(.system(size: 22, design: .rounded))
                    }
                    .foregroundStyle(LinearGradient(gradient: spot.waterType.gradient, startPoint: .top, endPoint: .bottom))
                    
                    Section(header: FuturisticSectionHeader(text: "Information")) {
                        InfoRow(title: "Overall Result", value: spot.result.rawValue, icon: spot.result.icon, color: spot.result.neonColor)
                        InfoRow(title: "Times Fished", value: "\(timesFished)", icon: "calendar", color: Color.futuristicCyan)
                        InfoRow(title: "Last Date", value: lastDate.formatted(date: .abbreviated, time: .omitted), icon: "clock", color: Color.futuristicCyan)
                    }
                    
                    Section(header: FuturisticSectionHeader(text: "Fish Caught")) {
                        ForEach(spot.fishCaught, id: \.self) { fish in
                            HStack {
                                Image(systemName: fishTypes.first { $0.name == fish }?.icon ?? "fish.fill")
                                    .foregroundColor(Color.neonYellow)
                                Text(fish)
                                    .foregroundColor(Color.accentWhite)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    
                    Section(header: FuturisticSectionHeader(text: "Notes")) {
                        Text(spot.notes)
                            .foregroundColor(Color.accentWhite.opacity(0.8))
                            .padding()
                            .background(Color.darkBackground.opacity(0.5))
                            .cornerRadius(15)
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.futuristicGreen.opacity(0.5)))
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
                        .font(.headline)
                        .foregroundColor(Color.futuristicCyan)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.darkBackground.opacity(0.7))
                        .cornerRadius(20)
                        
                        Spacer()
                        
                        Button("Delete Spot") {
                            if let index = spots.firstIndex(where: { $0.id == spot.id }) {
                                spots.remove(at: index)
                            }
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.darkBackground.opacity(0.7))
                        .cornerRadius(20)
                    }
                }
            }
            .sheet(isPresented: $showEdit) {
                EditSpotView(spot: $spot)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    var color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
            Text(title)
                .foregroundColor(.accentWhite.opacity(0.7))
                .font(.system(size: 18, design: .rounded))
            Spacer()
            Text(value)
                .foregroundColor(.accentWhite)
                .font(.system(size: 18, weight: .bold, design: .rounded))
        }
        .padding()
        .background(Color.darkBackground.opacity(0.6))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(color.opacity(0.5), lineWidth: 1))
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
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.darkBackground, .futuristicGreen.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
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
            .navigationTitle("Edit Spot")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.accentWhite.opacity(0.7))
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
                    .foregroundColor(.neonYellow)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct FishSpotIssueWifiView: View {
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            ZStack {
                Image("issue_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                
                Image("issue_wifi")
                    .resizable()
                    .frame(width: 270, height: 210)
            }
        }
        .ignoresSafeArea()
    }
}
