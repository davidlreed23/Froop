//
//  FroopProofApp.swift
//  FroopProof
//
//  Created by David Reed on 1/18/23.
//



import Foundation
import MapKit
import UIKit
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import GoogleSignIn
import UserNotifications
import FirebaseCrashlytics
import FirebaseMessaging
import UserNotifications
import RevenueCatUI
import RevenueCat

class AppDelegate: NSObject, ObservableObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, FroopNotificationDelegate, MessagingDelegate {
    
    static private(set) var instance: AppDelegate! = nil
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        NSSetUncaughtExceptionHandler { exception in
            print("Uncaught exception: \(exception)")
            print("Stack trace: \(exception.callStackSymbols)")
        }
        Purchases.configure(withAPIKey: Secrets.apiKey)
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        
        PrintControl.shared.printAppDelegate("-AppDelegate: Function: application2 firing")
        // Request user authorization for notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                PrintControl.shared.printErrorMessages("Failed to request authorization for remote notifications with error: \(error.localizedDescription)")
                Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            } else if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User denied notification permissions."])
                Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            }
        }
        
       
        
        Purchases.logLevel = .debug
        
        Purchases.shared.logIn(Auth.auth().currentUser?.uid ?? "") { (purchaserInfo, created, error) in
            // Handle the result here
            if let error = error {
                // Handle error
                print("🚫Error logging in: \(error.localizedDescription)")
            } else if purchaserInfo != nil {
                // Use the purchaserInfo
                if created {
                    // This means a new anonymous user was created in RevenueCat
                } else {
                    // Existing user found and logged in
                }
            }
        }
        
        let myDataManager = MyData.shared
        myDataManager.updateSubscriptionStatus()
        
        UIApplication.shared.registerForRemoteNotifications()
        
        let locationManager = LocationManager.shared
           locationManager.requestAlwaysAuthorization() // Or requestAlwaysAuthorization()
           locationManager.startUpdating()
        
        FirebaseServices.requestBadgePermission { granted in
            if granted {
                PrintControl.shared.printNotifications("Badge permission granted")
            } else {
                PrintControl.shared.printNotifications("Badge permission denied")
            }
        }
        saveUserFcmToken()
        return true
    }
    
//    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
//        // Ensure the activity type is for opening a URL
//        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let incomingURL = userActivity.webpageURL else {
//            print("returning false")
//            return false
//        }
//        print("firing handleIncomingURL: \(incomingURL)")
//        // Handle the incoming URL
//        handleIncomingURL(incomingURL)
//
//        return true
//    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Called when the user quits the application and it begins to transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and save application state.
        // If your app supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        // Your code to handle the app entering the background
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate.
        // This is also the time to invalidate your timers.
        
        // Your code to handle app termination
        ListenerStateService.shared.deactivateAll()

    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PrintControl.shared.printAppDelegate("-function application firing")
        UNUserNotificationCenter.current().delegate = self
        
        Messaging.messaging().apnsToken = deviceToken
        // Get FCM token
        Messaging.messaging().token { fcmToken, error in
            if let error = error {
                PrintControl.shared.printErrorMessages("Error fetching FCM registration token: \(error)")
                Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            } else if let fcmToken = fcmToken {
                PrintControl.shared.printAppDelegate("FCM registration token: \(fcmToken)")
                self.updateFCMTokenInFirestore(fcmToken)
            }
        }
    }

    private func updateFCMTokenInFirestore(_ fcmToken: String) {
        PrintControl.shared.printAppDelegate("🚦 UPDATING FCM TOKEN FUNCTION FIRING 🚦")
            guard let uid = Auth.auth().currentUser?.uid else {
                // User not authenticated
                return
            }

            let db = Firestore.firestore()
            let userRef = db.collection("users").document(uid)
            userRef.updateData(["fcmToken": fcmToken]) { error in
                if let error = error {
                    Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
                } else {
                    PrintControl.shared.printAppDelegate("🪙 fcmToken Updated")
                }
            }
        }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification notification: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        PrintControl.shared.printAppDelegate("-function application firing")
        PrintControl.shared.printAppDelegate("\(#function)")
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }
        
        // Handle your custom navigation here
        if let data = notification["data"] as? [String: Any] {
            if let selectedTab = data["selectedTab"] as? String,
               let selectedFroopTabString = data["selectedFroopTab"] as? String,
               let selectedFroopTabInt = Int(selectedFroopTabString) {
                LocationServices.shared.selectedTab = Tab(rawValue: selectedTab) ?? .froop
                LocationServices.shared.selectedFroopTab = FroopTab(rawValue: selectedFroopTabInt) ?? .map
            }
        }
        
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PrintControl.shared.printAppDelegate("-AppDelegate: Function: application1 firing")
        PrintControl.shared.printErrorMessages("Failed to register for remote notifications with error: \(error.localizedDescription)")
    }
    

    //MARK: Reset Badge Count
    func applicationDidBecomeActive(_ application: UIApplication) {
        PrintControl.shared.printNotifications("--> applicatoinDidBecomeActive firing")
        
        // Reset application badge count
                
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
               print("🚫Error setting badge count: \(error)")
            } else {
                print("--> application.applicationsIconBadgeNumber = 0 is firing")
                print("badge number is now reset to 0")
            }
        }

        UserDefaults.standard.set(0, forKey: "badgeCount")
        
        // Assuming you have a reference to the currently logged in user's Firestore document
        let db = Firestore.firestore()
        if let user = Auth.auth().currentUser {
            db.collection("users").document(user.uid).updateData([
                "badgeCount": 0
            ]) { err in
                if let err = err {
                    print("🚫Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
        }
    }
  
    // MARK: - FroopNotificationDelegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print(">> FCM TOKEN:", fcmToken)
        let dataDict: [String: String] = ["fcmToken": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMTokenNotification"), object: fcmToken, userInfo: dataDict)
        UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
        self.updateFCMTokenInFirestore(fcmToken)

    }
    
    func froopParticipantsChanged(_ froopHistory: FroopHistory) {
        PrintControl.shared.printAppDelegate("-AppDelegate: Function: froopParticipantsChanged is firing")
        // Handle participants change event
    }
    
    func froopStatusChanged(_ froopHistory: FroopHistory) {
        // Handle status change event
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        PrintControl.shared.printAppDelegate("-AppDelegate: Function: userNotificationCenter firing")
        let userInfo = response.notification.request.content.userInfo
        let notificationIdentifier = response.notification.request.identifier
        
        // Check if the notification is the location tracking notification
        if notificationIdentifier == "LocationTrackingNotification" {
            // Present the alert asking for location sharing permission
            DispatchQueue.main.async {
                guard let window = self.window,
                      let rootViewController = window.rootViewController
                else {
                    completionHandler()
                    return
                }
                
                let alertController = UIAlertController(title: "Share Your Location", message: "Would you like to share your location to receive accurate arrival time notifications?", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Share Location", style: .default, handler: { _ in
                    // Enable location sharing and start tracking
                    // ...
                }))
                alertController.addAction(UIAlertAction(title: "Not Now", style: .cancel, handler: nil))
                
                rootViewController.present(alertController, animated: true, completion: nil)
            }
        }
        
        // Check if the notification is related to user arrival
        if notificationIdentifier == "UserArrivalNotification" {
            // Extract relevant information from the notification payload
            let arrivedUserName = userInfo["arrivedUserName"] as? String ?? "Unknown user"
            let froopName = userInfo["froopName"] as? String ?? "Unknown Froop event"
            
            // Display an alert or update the UI with the arrival information
            DispatchQueue.main.async {
                guard let window = self.window,
                      let rootViewController = window.rootViewController
                else {
                    completionHandler()
                    return
                }
                
                let alertController = UIAlertController(title: "User Arrived", message: "\(arrivedUserName) has arrived at \(froopName).", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                rootViewController.present(alertController, animated: true, completion: nil)
            }
        }
        
        
        completionHandler()
    }
    
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        PrintControl.shared.printAppDelegate("-AppDelegate: Function: application3 firing")
        
        // Handle Google Sign-In
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        } else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Google sign-in failed or was cancelled by the user."])
            Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
        }
        
        // Handle your app's custom URL scheme
        if url.scheme == "froopproof" {
            PrintControl.shared.printAppDelegate("Opened app with URL: \(url)")
            // Here, you can parse the URL and navigate the user to the appropriate screen or perform the desired action.
            // For example, if your URL is froopproof://event?id=123, you can extract the id parameter and use it as needed.
            return true
        }
        
        // Return false if the URL was not handled by any of the above cases
        return false
    }
    
//    private func handleIncomingURL(_ url: URL) {
//        print("Incoming URL: \(url)")
//        // Assuming your URL format is https://froop.me/invite/<UID>
//        let pathComponents = url.pathComponents
//        if let inviteIndex = pathComponents.firstIndex(of: "invite"), inviteIndex + 1 < pathComponents.count {
//            let inviteUID = pathComponents[inviteIndex + 1]
//            // Now you have the UID, you can use it as needed in your app
//            print("🍊 Extracted UID: \(inviteUID)")
//            MyData.shared.inviteUrlUid = inviteUID
//            // For example, navigate to a specific view controller or perform an action with the UID
//            navigateToInvite(withUID: inviteUID)
//        }
//    }
    
    private func navigateToInvite(withUID uid: String) {
        print("Navigate to the part of the app related to the UID: \(uid)")
        // Example: Posting a notification that can be observed where appropriate to handle the navigation
        NotificationCenter.default.post(name: Notification.Name("NavigateToInviteNotification"), object: nil, userInfo: ["UID": uid])
    }
    
    func saveUserFcmToken() {
        // Check if the user is authenticated
        guard let uid = Auth.auth().currentUser?.uid, !uid.isEmpty else {
            PrintControl.shared.printErrorMessages("User is not authenticated. fcmToken not saved to user document.")
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated. fcmToken not saved to user document."])
            Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            return
        }
        
        // Get the FCM token form user defaults
        guard let fcmToken = UserDefaults.standard.value(forKey: "FCMTokenNotification") else {
            return
        }
        
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        
        // Update the user document with the fcmToken
        docRef.updateData(["fcmToken": fcmToken]) { error in
            if let error = error {
                PrintControl.shared.printErrorMessages("Error updating user document with fcmToken: \(error)")
                Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            } else {
                PrintControl.shared.printAppDelegate("fcmToken saved to user document successfully")
            }
        }
    }
}

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var authState = AuthState()
    @StateObject var myData = MyData.shared
    @StateObject var inviteManager = InviteManager.shared
    @Environment(\.scenePhase) var scenePhase
    @State private var overlayWindow: UIWindow?
    @StateObject var listenerStateService = ListenerStateService.shared
    
    
    
    var body: some Scene {
        
        WindowGroup {
            
            if authState.isFirebaseAuthDone {
                if authState.isAuthenticated {
                    RootView(friendData: UserData(), photoData: PhotoData(), appDelegate: AppDelegate(), confirmedFroopsList: ConfirmedFroopsList())
                        .onAppear(perform:  {
                            
                            Purchases.shared.getOfferings { (offerings, error) in
                                if let packages = offerings?.current?.availablePackages {
                                    print(packages.map( {$0.offeringIdentifier }))
                                    print(packages.map( {$0.localizedPriceString }))                                }
                            }
                            if overlayWindow == nil {
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    let overlayWindow = PassThroughWindow(windowScene: windowScene)
                                    overlayWindow.backgroundColor = .clear
                                    overlayWindow.tag = 0320
                                    let controller = StatusBarBasedController()
                                    controller.view.backgroundColor = .clear
                                    overlayWindow.rootViewController = controller
                                    overlayWindow.isHidden = false
                                    overlayWindow.isUserInteractionEnabled = true
                                    self.overlayWindow = overlayWindow
                                    PrintControl.shared.printAppDelegate("Overlay Window Created")
                                }
                            }
                            PrintControl.shared.printAppDelegate("LOADING ROOT VIEW")
                        })
                        .onOpenURL { url in
                            print("Received URL: \(url)")
                            // Here you can parse the URL and navigate accordingly within your app
                            // For example:
                            handleIncomingURL(url)
                        }
                } else {
                    Login().environmentObject(authState)
                }
            } else {
                Text("Authenticating...")
            }
        }
    }
    private func handleIncomingURL(_ url: URL) {
        let pathComponents = url.pathComponents
        if let inviteIndex = pathComponents.firstIndex(of: "invite"), inviteIndex + 1 < pathComponents.count {
            let inviteUid = pathComponents[inviteIndex + 1]
            print("🍎 Extracted UID: \(inviteUid)")
            Task {
                await inviteManager.handleInvitation(inviteUid: inviteUid)
                // actions to update view here
            }
        }
    }

}

class StatusBarBasedController: UIViewController {
    var statusBarStyle: UIStatusBarStyle = .default
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
}

fileprivate class PassThroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event) else { return nil }
        return rootViewController?.view == view ? nil : view
    }
}

class AuthState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isFirebaseAuthDone: Bool = false
    @ObservedObject var myData = MyData.shared
    private var authHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        authHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            self.isFirebaseAuthDone = true

            if let user = user, !user.uid.isEmpty {
                self.isAuthenticated = true
            } else {
                self.isAuthenticated = false
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User became unauthenticated or UID is missing."])
                Crashlytics.crashlytics().record(error: error)
            }
        }
    }
    
    func signOut() {
        ListenerStateService.shared.deactivateAll()
        FroopManager.shared.removeListeners()
        PrintControl.shared.printStartUp("-AuthState: Function: signOut firing")
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            if let uid = firebaseAuth.currentUser?.uid, !uid.isEmpty {
                // Perform Firestore operations here with the non-empty user ID.
            } else {
                PrintControl.shared.printErrorMessages("User ID is empty or nil.")
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User ID is empty or nil."])
                Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            }
        } catch let signOutError as NSError {
            print("🚫Error signing out: %@", signOutError)
            Crashlytics.crashlytics().record(error: signOutError) // Log error to Crashlytics
        }
    }
    
    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}



