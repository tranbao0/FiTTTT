import SwiftUI
import FirebaseAuth

// Creates a curved shape for the bottom section of the login screen
struct BottomCurveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startY = rect.height * 0.3
        let endY = rect.height * 0.45
        path.move(to: CGPoint(x: 0, y: startY))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: endY),
            control: CGPoint(x: rect.width / 2, y: rect.height * 0.47)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct LoginScreen: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var showSignUpView = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                BottomCurveShape()
                    .fill(Color.white)
                    .ignoresSafeArea()

                VStack(alignment: .center, spacing: 24) {
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

                    Text("Welcome Back!")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.title3)
                                .foregroundColor(.black)
                            TextField("example@gmail.com", text: $email)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .disableAutocorrection(true)
                                .padding(.bottom, 8)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(.black),
                                    alignment: .bottom
                                )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.title3)
                                .foregroundColor(.black)
                            SecureField("••••••••••••••••", text: $password)
                                .padding(.bottom, 8)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(.black),
                                    alignment: .bottom
                                )
                        }

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 17)

                    Button(action: loginUser) {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(28)
                    }
                    .padding(.horizontal, 32)

                    HStack {
                        Spacer()
                        Text("Don't have an account?")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign Up")
                                .font(.body)
                                .underline()
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 26)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $isLoggedIn) {
                CalendarView()
            }
        }
    }

    // Authenticates user with Firebase and navigates on success
    private func loginUser() {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in both fields."
            return
        }

        if !email.isValidEmail {
            errorMessage = "Please enter a valid email address."
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Error: \(error.localizedDescription)"
            } else {
                isLoggedIn = true
            }
        }
    }
}

// Email validation extension
extension String {
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
}

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
    }
}
