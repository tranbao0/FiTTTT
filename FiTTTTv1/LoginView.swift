//
//  LoginView.swift
//  FiTTTTv1
//
//


import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            Text("Welcome Back!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            // Email
            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.bottom, 10)
            
            // Password
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.bottom, 20)
            
            // Error Message
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
    
    // Login
    private func loginUser() {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in both fields."
            return
        }
        
        if !email.isValidEmail {
            errorMessage = "Please enter a valid email address."
            return
        }
        
        // Firebase log in attempt
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Error: \(error.localizedDescription)"
            } else {
                // Login success
                isLoggedIn = true  // Binding to true
            }
        }
    }
}

// Email Validation Extension
extension String {
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))  // Preview with false logged-in state
    }
}
