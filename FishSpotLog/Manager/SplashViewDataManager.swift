import Foundation
import Combine
import Network
import UserNotifications
import Firebase
import AppsFlyerLib

final class SplashViewFishViewModel: ObservableObject {
    @Published var visibleNotificationsPushPrompt = false
    private var trackingData: [String: Any] = [:]
    private var linkData: [String: Any] = [:]
    private let mainRepository: MainFishRepository
    init(repo: MainFishRepository = FishRepositoryImpl()) {
        self.mainRepository = repo
        NotificationCenter.default
            .publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { [weak self] data in
                self?.trackingData = data
                self?.assessMode()
            }
            .store(in: &cancellables)
        NotificationCenter.default
            .publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { [weak self] data in
                self?.linkData = data
            }
            .store(in: &cancellables)
        monitorNetwork()
        setUpDeadlines()
    }
    private func setUpDeadlines() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            if self.trackingData.isEmpty && self.linkData.isEmpty && self.currentScreenState == .setup {
                self.assignMode(to: .legacy)
            }
        }
    }
    deinit {
        networkWatcher.cancel()
    }
    @Published var currentScreenState: FishSpotLogStates = .setup
    @Published var fishSpotLog: URL?
    private var cancellables = Set<AnyCancellable>()
    private let networkWatcher = NWPathMonitor()
    
    private func isDateValid() -> Bool {
        let currentCalendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 12
        dateComponents.day = 29
        if let comparisonDate = currentCalendar.date(from: dateComponents) {
            return Date() >= comparisonDate
        }
        return false
    }
    private func cacheSuccessfulLog(_ log: String, targetURL: URL) {
        let cacher = CacheSuccessfulLogUseCase(repo: mainRepository)
        cacher.perform(log: log)
        let checker = CheckPermissionsPromptUseCase(repo: mainRepository)
        if checker.perform() {
            fishSpotLog = targetURL
            visibleNotificationsPushPrompt = true
        } else {
            fishSpotLog = targetURL
            assignMode(to: .operational)
        }
    }
    
    @objc private func assessMode() {
        if !isDateValid() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.activateLegacy()
            }
            return
        }
        if trackingData.isEmpty {
            retrieveCachedLog()
            return
        }
        if mainRepository.retrieveAppState() == "Inactive" {
            activateLegacy()
            return
        }
        let assessor = PhaseRegulatorUseCase(repo: mainRepository)
        let mode = assessor.perform(trackingData: trackingData, initial: mainRepository.isInitialRun, currentURL: fishSpotLog, interimURL: UserDefaults.standard.string(forKey: "temp_url"))
        if mode == .setup && mainRepository.isInitialRun {
            startMainApp()
            return
        }
        if let logStr = UserDefaults.standard.string(forKey: "temp_url"),
           let log = URL(string: logStr) {
            fishSpotLog = log
            assignMode(to: .operational)
            return
        }
        if fishSpotLog == nil {
            let checker = CheckPermissionsPromptUseCase(repo: mainRepository)
            if checker.perform() {
                visibleNotificationsPushPrompt = true
            } else {
                fishAppConfigSetUp()
            }
        }
    }
    func processSkipPerm() {
        let processor = ProcessSkipPermUseCase(repo: mainRepository)
        processor.perform()
        visibleNotificationsPushPrompt = false
        fishAppConfigSetUp()
    }
    
    private func activateLegacy() {
        let activator = ActivateLegacyUseCase(repo: mainRepository)
        activator.perform()
        assignMode(to: .legacy)
    }
    private func retrieveOrganicTracking() async {
        do {
            let retriever = RetrieveOrganicTrackingUseCase(repo: mainRepository)
            let merged = try await retriever.perform(linkData: linkData)
            await MainActor.run {
                self.trackingData = merged
                self.fishAppConfigSetUp()
            }
        } catch {
            activateLegacy()
        }
    }
    func processGrantPerm() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] accepted, _ in
            DispatchQueue.main.async {
                let processor = ProcessGrantPermUseCase(repo: self?.mainRepository ?? FishRepositoryImpl())
                processor.perform(accepted: accepted)
                if accepted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                self?.visibleNotificationsPushPrompt = false
                if self?.fishSpotLog != nil {
                    self?.assignMode(to: .operational)
                } else {
                    self?.fishAppConfigSetUp()
                }
            }
        }
    }
    private func fishAppConfigSetUp() {
        Task { [weak self] in
            do {
                let retriever = RetrieveLogConfigUseCase(repo: self?.mainRepository ?? FishRepositoryImpl())
                let targetURL = try await retriever.perform(trackingData: self?.trackingData ?? [:])
                let logStr = targetURL.absoluteString
                await MainActor.run {
                    self?.cacheSuccessfulLog(logStr, targetURL: targetURL)
                }
            } catch {
                self?.retrieveCachedLog()
            }
        }
    }
}

extension SplashViewFishViewModel {
    func assignMode(to mode: FishSpotLogStates) {
        DispatchQueue.main.async {
            self.currentScreenState = mode
        }
    }
    func monitorNetwork() {
        networkWatcher.pathUpdateHandler = { [weak self] path in
            if path.status != .satisfied {
                DispatchQueue.main.async {
                    if self?.mainRepository.retrieveAppState() == "LogView" {
                        self?.assignMode(to: .disconnected)
                    } else {
                        self?.activateLegacy()
                    }
                }
            }
        }
        networkWatcher.start(queue: .global())
    }
    func retrieveCachedLog() {
        let retriever = RetrieveCachedLogUseCase(repo: mainRepository)
        if let log = retriever.perform() {
            fishSpotLog = log
            assignMode(to: .operational)
        } else {
            activateLegacy()
        }
    }
    func startMainApp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            Task { [weak self] in
                await self?.retrieveOrganicTracking()
            }
        }
    }
}
