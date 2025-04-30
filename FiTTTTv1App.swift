//
//  FiTTTTv1App.swift
//  FiTTTTv1
//
//  Created by Henry To on 4/30/25.
//
import SwiftUI
import FirebaseCore

// AppDelegate class for Firebase setup
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct FiTTTTv1App: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView() // The starting view of your app
            }
        }
    }
}
