//
//  ContentView.swift
//  FiTTTTv1
//


import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isLoggedIn = false
    // Track login state

    var body: some View {
        VStack {
            if isLoggedIn {
                // Show content after login
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Welcome to the app!")
                    // Add more content/features for logged users
                }
                .padding()
            } else {
                // Display LoginView if the user is not logged in
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
        .onAppear {
            // Check if user is logged in when the view appears
            checkIfUserIsLoggedIn()
        }
        .onChange(of: isLoggedIn) { newValue in
            // Handle changes in login state (for example, when the user logs in or out)
            if newValue {
                print("User is logged in")
            } else {
                print("User is logged out")
            }
        }
    }

    private func checkIfUserIsLoggedIn() {
        // Check if the user is already logged in
        if Auth.auth().currentUser != nil {
            isLoggedIn = true
        } else {
            isLoggedIn = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
