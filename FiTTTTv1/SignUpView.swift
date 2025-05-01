// SignUpView.swift
import SwiftUI
import FirebaseAuth
import Firebase
import FirebaseFirestore


struct SignUpView: View {
   @State private var email = ""
   @State private var password = ""
   @State private var confirmPassword = ""
   @State private var errorMessage = ""
   @State private var username = ""
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
                .textContentType(.none)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            TextField("Username", text: $username)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .autocapitalization(.none)

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

    // Checks if email is in valid format
    func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

   // Checks if username is valid
   func isValidUsername(_ username: String) -> Bool {
        let pattern = "^[a-zA-Z0-9._]{6,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: username)
    }

    // Checks if username exists within Firestore
    func checkUsernameExists(_ username: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let error = error {
                print("Error checking username: \(error)")
                completion(true) // assume taken if there's an error
            } else {
                completion(snapshot?.documents.count ?? 0 > 0)
            }      
        }
    }

    // Check if password is valid
    func isValidPassword(_ password: String) -> Bool {
        let pattern = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^a-zA-Z\\d]).{12,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: password)
    }

   
   // Creates a new user account with Firebase authentication
   private func registerUser() {
        if email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            errorMessage = "Please fill in all fields"
            return
        }

        if !email.isValidEmail {
            errorMessage = "Please enter a valid email"
            return
        }

        if !isValidUsername(username) {
            errorMessage = "Invalid username. Use only letters, numbers, '.', '_' (6+ characters)"
            return
        }

        if !isValidPassword(password) {
            errorMessage = "Password must be 12+ chars with upper, lower, number, and special character"
            return
        }

        if password != confirmPassword {
            errorMessage = "Passwords don't match"
            return
        }

        // Check if username is taken
        checkUsernameExists(username) { exists in
            if exists {
                errorMessage = "Username is already taken"
                return
            }

            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    errorMessage = "Error: \(error.localizedDescription)"
                } else if let user = result?.user {
                    let db = Firestore.firestore()
                    db.collection("users").document(user.uid).setData([
                        "email": user.email ?? "",
                        "uid": user.uid,
                        "username": username,
                        "createdAt": Timestamp()
                    ]) { err in
                        if let err = err {
                            errorMessage = "Error saving user data: \(err.localizedDescription)"
                        } else {
                            showLoginView = true
                        }
                    }
                }
            }
        }
    }
}
