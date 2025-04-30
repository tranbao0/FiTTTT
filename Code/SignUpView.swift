//
//  SignUpView.swift
//  FiTTTTv1
//
//  Created by Henry To on 4/30/25.
//

import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            Text("Create an Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
    
            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.bottom, 10)
      
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.bottom, 10)
            
      
            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.bottom, 20)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.bottom, 10)
            }
            
     
            Button(action: signUpUser) {
                Text("Sign Up")
                    .foregroundColor(.white)
                    .frame(width: 250, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
    }
    
 
    private func signUpUser() {
        if email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            errorMessage = "Please fill in all fields."
            return
        }
        
        if password != confirmPassword {
            errorMessage = "Passwords do not match."
            return
        }
        
     //fire base new user attempt
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Error: \(error.localizedDescription)"
            } else {
                // account created
                errorMessage = ""
                print("Sign-Up successful!")
           
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
