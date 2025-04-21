//
//  ContentView.swift
//  Fitness App

import SwiftUI

// User model
struct User: Identifiable {
    let id = UUID()
    var username: String
    var password: String
}

struct ContentView: View {
    
    @State private var users: [User] = [] // Stores registered users
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isRegistered: Bool = false // Switch between Sign-Up and Login
    @State private var isAuthenticated: Bool = false // Track successful login
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(isRegistered ? "Login" : "Sign Up")
                    .font(.largeTitle)
                    .bold()
                
                VStack(spacing: 10) {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                
                Button(action: {
                    isRegistered ? loginUser() : registerUser()
                }) {
                    Text(isRegistered ? "Login" : "Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                }
                .padding(.horizontal)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                
                Button(action: {
                    isRegistered.toggle() // Switch between Sign-Up and Login
                }) {
                    Text(isRegistered ? "Don't have an account? Sign Up" : "Already have an account? Login")
                        .foregroundColor(.blue)
                        .padding()
                }
                
                // Navigate to HomeScreen.swift after successful login
                NavigationLink(destination: HomeScreen(), isActive: $isAuthenticated) {
                    EmptyView()
                }
            }
            .padding()
            .navigationTitle("Fitness App")
        }
    }
    
    func registerUser() {
        if !username.isEmpty && !password.isEmpty {
            if users.contains(where: { $0.username == username }) {
                alertMessage = "Username already exists!"
            } else {
                users.append(User(username: username, password: password))
                alertMessage = "Account created successfully! Please log in."
                isRegistered = true // Switch to login screen
            }
        } else {
            alertMessage = "Please enter a valid username and password."
        }
        showAlert = true
    }
    
    func loginUser() {
        if users.contains(where: { $0.username == username && $0.password == password }) {
            isAuthenticated = true
        } else {
            alertMessage = "Invalid username or password!"
            showAlert = true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
