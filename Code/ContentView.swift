//
//  ContentView.swift
//  FiTTTTv1
//
//  Created by Henry To on 4/30/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isLoggedIn = false
    // if user is logged in or not
    
    var body: some View {
        VStack {
            if isLoggedIn {
                // Show content after login
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Hello, world!")
                    // more features for logged users
                }
                .padding()
            } else {
                // preview for not logged in user
                LoginView(isLoggedIn: $isLoggedIn) // Pass the binding here
            }
        }
        .onAppear {
            // checks to see if user is logged in
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
