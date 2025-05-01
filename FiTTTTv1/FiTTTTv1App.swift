//
//  FiTTTTv1App.swift
//  FiTTTTv1
//
//  Created by Henry To on 4/30/25.
//
import SwiftUI
import FirebaseCore

// firebase set up
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
    // firebase set up delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                OnboardingView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
