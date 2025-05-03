import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// A custom Bezier curve shape for the white bottom region
struct BottomCurveShapetwo: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startY = rect.height * 0.3
        let endY = rect.height * 0.42
        path.move(to: CGPoint(x: 0, y: startY))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: endY),
            control: CGPoint(x: rect.width / 2, y: rect.height * 0.4)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct SignUpView: View {
    // MARK: - UI State
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showLoginView = false
    @State private var showSuccessAlert = false

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            BottomCurveShapetwo()
                .fill(Color.white)
                .ignoresSafeArea()

            // Content
            VStack(alignment: .center, spacing: 24) {
                // Logo & Subtitle
                VStack(spacing: 8) {
                    Image("FiTTTTLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 75)
                        .padding(.top, 60)
                    Text("Accountability in Fitness")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.leading, 110)
                }

                Text("Welcome!")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.top, 16)

                // Form fields
                VStack(alignment: .leading, spacing: 16) {
                    // Email field with gray placeholder
                    Group {
                        Text("Email")
                            .font(.title3)
                            .foregroundColor(.black)
                        ZStack(alignment: .leading) {
                            if email.isEmpty {
                                Text("example@gmail.com")
                                    .foregroundColor(.gray)
                            }
                            TextField("", text: $email)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .disableAutocorrection(true)
                                .foregroundColor(.black)
                        }
                        .padding(.bottom, 8)
                        .overlay(
                            Rectangle().frame(height: 1).foregroundColor(.black),
                            alignment: .bottom
                        )
                    }
                    // Username field
                    Group {
                        Text("Username")
                            .font(.title3)
                            .foregroundColor(.black)
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.bottom, 8)
                            .overlay(
                                Rectangle().frame(height: 1).foregroundColor(.black),
                                alignment: .bottom
                            )
                    }

                    // Password field
                    Group {
                        Text("Password")
                            .font(.title3)
                            .foregroundColor(.black)
                        SecureField("•••••••••••••••", text: $password)
                            .textContentType(.oneTimeCode)
                            .padding(.bottom, 8)
                            .overlay(
                                Rectangle().frame(height: 1).foregroundColor(.black),
                                alignment: .bottom
                            )
                    }

                    // Confirm Password field
                    Group {
                        Text("Confirm Password")
                            .font(.title3)
                            .foregroundColor(.black)
                        SecureField("•••••••••••••••", text: $confirmPassword)
                            .padding(.bottom, 8)
                            .overlay(
                                Rectangle().frame(height: 1).foregroundColor(.black),
                                alignment: .bottom
                            )
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)

                // Register Button
                Button(action: registerUser) {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(28)
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)

                // Already have account?
                HStack {
                    Spacer()
                    Text("Already have an account?")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Button(action: { showLoginView = true }) {
                        Text("Log In")
                            .font(.body)
                            .underline()
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)

                // NavigationLink to Login
                NavigationLink(isActive: $showLoginView) {
                    LoginScreen()
                } label: {
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .alert("Sign Up Successful", isPresented: $showSuccessAlert) {
                Button("OK") {
                    showLoginView = true
                }
            } message: {
                Text("Your account has been created. Please log in.")
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Validation & Registration Logic

    private func registerUser() {
        errorMessage = ""
        // Basic non-empty checks
        guard !email.isEmpty, !username.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        // Email format
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email."
            return
        }
        // Username rules
        if !isValidUsername(username) {
            errorMessage = "Invalid username. Use 6+ letters, numbers, '.', '_'"
            return
        }
        // Password strength
        if !isValidPassword(password) {
            errorMessage = "Password must be 12+ chars with upper, lower, number & special"
            return
        }
        // Confirm match
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match."
            return
        }

        let db = Firestore.firestore()
        // Check Firestore for username in 'usernames' collection
        db.collection("usernames").document(username).getDocument { document, error in
            if let error = error {
                errorMessage = "Error checking username: \(error.localizedDescription)"
                return
            }
            if document?.exists == true {
                errorMessage = "Username is already taken."
                return
            }

            // Create Firebase Auth user
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                guard let user = result?.user else {
                    errorMessage = "Failed to get user info."
                    return
                }

                // Write user profile to Firestore
                db.collection("users").document(user.uid).setData([
                    "uid": user.uid,
                    "email": user.email ?? "",
                    "username": username,
                    "createdAt": Timestamp()
                ]) { err in
                    if let err = err {
                        errorMessage = "Error saving user data: \(err.localizedDescription)"
                        return
                    }

                    // Claim username in its own collection for fast lookup
                    db.collection("usernames").document(username).setData([
                        "uid": user.uid
                    ]) { err in
                        if let err = err {
                            print("Warning: could not save username mapping: \(err.localizedDescription)")
                        }
                        showSuccessAlert = true
                    }
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    private func isValidUsername(_ username: String) -> Bool {
        let pattern = "^[a-zA-Z0-9._]{6,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: username)
    }

    private func isValidPassword(_ password: String) -> Bool {
        let pattern = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^a-zA-Z\\d]).{12,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: password)
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { SignUpView() }
            .previewDevice("iPhone 14")
    }
}
