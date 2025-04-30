//
//  LoginView.swift
//  FiTTTTv1
//
//  Created by Henry To on 4/30/25.
//


import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Binding var isLoggedIn: Bool // Expecting a binding
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            Text("Welcome Back!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            // Email Text Field
            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.bottom, 10)
            
            // Password Text Field
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.bottom, 20)
            
            // Error Message (if any)
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.bottom, 10)
            }
            
            // Login Button
            Button(action: loginUser) {
                Text("Login")
                    .foregroundColor(.white)
                    .frame(width: 250, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            NavigationLink(destination: SignUpView()) {
                Text("Don't have an account? Sign Up")
                    .foregroundColor(.blue)
                    .padding(.top, 20)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // Login Action
    private func loginUser() {
        // Check if fields are empty
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in both fields."
            return
        }
        
        // Attempt to sign in using Firebase Authentication
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Error: \(error.localizedDescription)"
            } else {
                // Successfully logged in, update the state
                isLoggedIn = true // Set the binding value to true
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))  // Preview with false logged in state
    }
}
