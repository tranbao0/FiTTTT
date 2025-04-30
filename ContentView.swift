//
//  ContentView.swift
//  FiTTTTv1
//
//  Created by Henry To on 4/30/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    // Track if the user is logged in
    @State private var isLoggedIn = false
    
    var body: some View {
        VStack {
            if isLoggedIn {
                // Show content after login
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Hello, world!")
                    // You can add more content here for logged-in users
                }
                .padding()
            } else {
                // Show the LoginView if not logged in
                LoginView(isLoggedIn: $isLoggedIn) // Pass the binding here
            }
        }
        .onAppear {
            // Check if the user is already logged in when the view appears
            if Auth.auth().currentUser != nil {
                isLoggedIn = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
