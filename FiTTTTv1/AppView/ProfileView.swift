import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI

struct ProfileView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @State private var username = ""
    @State private var email = ""
    @State private var streak = 0
    @State private var error = ""

    @State private var selectedImage: UIImage? = nil
    @State private var pickerItem: PhotosPickerItem? = nil

    // path to store profile image locally
    private let imagePath = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("profile.jpg")

    var body: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.largeTitle)
                .bold()
            
            if !error.isEmpty {
                Text(error)
                    .foregroundColor(.red)
            }
            
            PhotosPicker(selection: $pickerItem, matching: .images) {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                }
            }
            .onChange(of: pickerItem) { _ in
                Task {
                    if let data = try? await pickerItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        saveImageLocally(image: image)
                    }
                }
            }
            
            Text("Username: \(username)")
            Text("Email: \(email)")
            Text("Workout Streak: \(streak) 🔥")
            
            Button(action: {
                try? Auth.auth().signOut()
                isLoggedIn = false
            }) {
                Text("Log Out")
                    .foregroundColor(.red)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(12)
            }
            .padding(.top, 24)
        }
    }

    // load user profile info from firestore
    func loadProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            error = "no logged in user"
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, err in
            if let err = err {
                error = "failed to load profile: \(err.localizedDescription)"
                return
            }

            let data = snapshot?.data()
            username = data?["username"] as? String ?? "unknown"
            email = data?["email"] as? String ?? "unknown"
            streak = data?["streak"] as? Int ?? 0
        }
    }

    // save profile image to local file
    func saveImageLocally(image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: imagePath)
        }
    }

    // load profile image from local file
    func loadImageFromDisk() {
        if FileManager.default.fileExists(atPath: imagePath.path) {
            selectedImage = UIImage(contentsOfFile: imagePath.path)
        }
    }
}
