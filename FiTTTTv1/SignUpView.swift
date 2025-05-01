// SignUpView.swift
import SwiftUI
import FirebaseAuth

struct SignUpView: View {
   @State private var email = ""
   @State private var password = ""
   @State private var confirmPassword = ""
   @State private var errorMessage = ""
   @State private var showLoginView = false
   
   var body: some View {
       VStack(spacing: 20) {
           Text("Create Account")
               .font(.largeTitle)
               .fontWeight(.bold)
               .padding(.bottom, 30)
           
           TextField("Email", text: $email)
               .padding()
               .background(Color.gray.opacity(0.1))
               .cornerRadius(10)
               .textContentType(.none)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
           
           SecureField("Password", text: $password)
               .padding()
               .background(Color.gray.opacity(0.1))
               .cornerRadius(10)
               .textContentType(.none)
                .disableAutocorrection(true)
                .autocapitalization(.none)
           
           SecureField("Confirm Password", text: $confirmPassword)
               .padding()
               .background(Color.gray.opacity(0.1))
               .cornerRadius(10)
               .padding(.bottom, 10)
               .textContentType(.none)
                .disableAutocorrection(true)
                .autocapitalization(.none)
           
           if !errorMessage.isEmpty {
               Text(errorMessage)
                   .foregroundColor(.red)
                   .padding(.bottom, 10)
           }
           
           Button(action: registerUser) {
               Text("Sign Up")
                   .foregroundColor(.white)
                   .frame(width: 250, height: 50)
                   .background(Color.blue)
                   .cornerRadius(10)
           }
           
           Button("Already have an account? Log In") {
               showLoginView = true
           }
           .foregroundColor(.blue)
           .padding(.top, 20)
           
           NavigationLink(isActive: $showLoginView) {
               LoginScreen(isLoggedIn: .constant(false))
           } label: {
               EmptyView()
           }
       }
       .padding()
   }
   
   // Creates a new user account with Firebase authentication
   private func registerUser() {
       if email.isEmpty || password.isEmpty {
           errorMessage = "Please fill in all fields"
           return
       }
       
       if !email.isValidEmail {
           errorMessage = "Please enter a valid email"
           return
       }
       
       if password != confirmPassword {
           errorMessage = "Passwords don't match"
           return
       }
       
       Auth.auth().createUser(withEmail: email, password: password) { result, error in
           if let error = error {
               errorMessage = "Error: \(error.localizedDescription)"
           } else {
               showLoginView = true
           }
       }
   }
}
