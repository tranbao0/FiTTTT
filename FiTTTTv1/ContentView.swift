import SwiftUI
import FirebaseAuth

// User model for local representation
struct User: Identifiable {
   let id = UUID()
   var username: String
   var password: String
}

struct ContentView: View {
   @State private var users: [User] = []
   @State private var username = ""
   @State private var password = ""
   @State private var isRegistered = false
   @State private var isAuthenticated = false
   @State private var showAlert = false
   @State private var alertMessage = ""
   
   var body: some View {
       NavigationStack {
           VStack(spacing: 20) {
               // Header text changes based on authentication mode
               Text(isRegistered ? "Login" : "Sign Up")
                   .font(.largeTitle).bold()
               
               VStack(spacing: 10) {
                   TextField("Username", text: $username)
                       .textFieldStyle(.roundedBorder)
                   
                   SecureField("Password", text: $password)
                       .textFieldStyle(.roundedBorder)
               }
               .padding(.horizontal)
               
               // Main action button for login/signup
               Button(isRegistered ? "Login" : "Sign Up") {
                   isRegistered ? loginUser() : registerUser()
               }
               .font(.headline)
               .foregroundColor(.white)
               .padding()
               .frame(maxWidth: .infinity)
               .background(.blue)
               .cornerRadius(10)
               .shadow(radius: 2)
               .padding(.horizontal)
               .alert(alertMessage, isPresented: $showAlert) {
                   Button("OK", role: .cancel) { }
               }
               
               // Toggle between registration and login modes
               Button(isRegistered
                      ? "Don't have an account? Sign Up"
                      : "Already have an account? Login") {
                   isRegistered.toggle()
               }
               .foregroundColor(.blue)
               
               // Navigation link activated on successful authentication
               NavigationLink(
                   destination: SplashScreenView(),
                   isActive: $isAuthenticated
               ) {
                   EmptyView()
               }
               .hidden()
           }
           .padding()
           .navigationTitle("Fitness App")
       }
   }
   
   // Creates a new user account with Firebase authentication
   func registerUser() {
       if !username.isEmpty && !password.isEmpty {
           // Firebase authentication call to create new user
           Auth.auth().createUser(withEmail: username, password: password) { authResult, error in
               if let error = error {
                   alertMessage = "Registration error: \(error.localizedDescription)"
                   showAlert = true
               } else {
                   // Store user in local array and show success message
                   users.append(User(username: username, password: password))
                   alertMessage = "Account created successfully! Please log in."
                   isRegistered = true
                   showAlert = true
               }
           }
       } else {
           alertMessage = "Please enter a valid username and password."
           showAlert = true
       }
   }
   
   // Authenticates existing user with Firebase
   func loginUser() {
       // Firebase authentication call to sign in
       Auth.auth().signIn(withEmail: username, password: password) { authResult, error in
           if let error = error {
               alertMessage = "Login error: \(error.localizedDescription)"
               showAlert = true
           } else {
               // Successful authentication triggers navigation
               isAuthenticated = true
           }
       }
   }
   
   // Helper function to validate email format
   func isValidEmail(_ email: String) -> Bool {
       let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
       let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
       return emailPred.evaluate(with: email)
   }
}

struct ContentView_Previews: PreviewProvider {
   static var previews: some View {
       ContentView()
   }
}
