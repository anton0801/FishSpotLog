import SwiftUI
import Combine
import Firebase
import UserNotifications
import AppsFlyerLib
import AppTrackingTransparency

struct AppConstants {
    static let bundleId = "com.fishslogggd.FishSpotLog"
    static let appsFlyerAppID = "6756785970"
    static let appsFlyerDevKey = "FQvNTze2bNELpGS49BUYDR"
}

enum FishSpotLogStates { case setup, operational, legacy, disconnected }

@main
struct FishSpotLogApp: App {
    
    // @UIApplicationDelegateAdaptor(ApplicationDelegate.self) var delegateApplication
    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}

class ApplicationDelegate: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate, MessagingDelegate, UNUserNotificationCenterDelegate, DeepLinkDelegate {
    
    private var spotLogConversionData: [AnyHashable: Any] = [:]
    
    
    private var fishSpotingDeeplinks: [AnyHashable: Any] = [:]
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func activateTrackMonitoring() {
        if #available(iOS 14.0, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                }
            }
        }
    }
    
    var appMergedTimer: Timer?
    let trackingSentKey = "trackingDataSent"
    
    // Success receive conversion data
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        spotLogConversionData = data
        initiateCombineTimer()
        if !fishSpotingDeeplinks.isEmpty {
            sendCombinedInfo()
        }
    }
    
    func application(_ app: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        
        if let notificationInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            parseTrackFromNotification(notificationInfo)
        }
        
        AppsFlyerLib.shared().appsFlyerDevKey = AppConstants.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = AppConstants.appsFlyerAppID
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().deepLinkDelegate = self
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activateTrackMonitoring),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        parseTrackFromNotification(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    // Success receive deeplinks data
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status,
              let deeplinkObject = result.deepLink else { return }
        guard !UserDefaults.standard.bool(forKey: trackingSentKey) else { return }
        
        
        fishSpotingDeeplinks = deeplinkObject.clickEvent
        NotificationCenter.default.post(name: Notification.Name("deeplink_values"), object: nil, userInfo: ["deeplinksData": fishSpotingDeeplinks])
        appMergedTimer?.invalidate()
        
        
        if !spotLogConversionData.isEmpty {
            sendCombinedInfo()
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        parseTrackFromNotification(userInfo)
        completionHandler(.newData)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { [weak self] token, error in
            guard error == nil, let activeToken = token else { return }
            UserDefaults.standard.set(activeToken, forKey: "fcm_token")
            UserDefaults.standard.set(activeToken, forKey: "push_token")
        }
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let infoPayload = notification.request.content.userInfo
        parseTrackFromNotification(infoPayload)
        completionHandler([.banner, .sound])
    }
    
    // Fail receive conversion data
    func onConversionDataFail(_ error: Error) {
        sendInfo(data: [:])
    }
    
}


extension ApplicationDelegate {
    
    func initiateCombineTimer() {
       appMergedTimer?.invalidate()
       appMergedTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
           self?.sendCombinedInfo()
       }
   }
    
    func parseTrackFromNotification(_ info: [AnyHashable: Any]) {
        let pushExtractor = AppPushExtractor()
        if let l = pushExtractor.extract(info: info) {
            UserDefaults.standard.set(l, forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("LoadTempURL"),
                    object: nil,
                    userInfo: ["temp_url": l]
                )
            }
        }
    }
    
    func sendInfo(data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    func sendCombinedInfo() {
       var combinedData = spotLogConversionData
       for (k, v) in fishSpotingDeeplinks {
           if combinedData[k] == nil {
               combinedData[k] = v
           }
       }
       sendInfo(data: combinedData)
       UserDefaults.standard.set(true, forKey: trackingSentKey)
   }
    
    
}
