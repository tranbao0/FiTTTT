import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import Combine

struct ProfileView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @State private var username = ""
    @State private var email = ""
    @State private var streak = 0
    @State private var lastCheckIn: Date?
    @State private var completedSessions = 0
    @State private var error = ""
    @State private var isLoading = true
    
    @State private var selectedImage: UIImage? = nil
    @State private var pickerItem: PhotosPickerItem? = nil
    
    // For navigation
    @Environment(\.presentationMode) var presentationMode
    
    // Stats
    @State private var totalWorkouts = 0
    @State private var completedThisWeek = 0
    
    // path to store profile image locally
    private let imagePath = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("profile.jpg")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header and profile image
                ZStack(alignment: .bottom) {
                    // Background gradient
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.black, Color.black.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(height: 180)
                    
                    // Profile image and username
                    VStack(spacing: 8) {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    .shadow(radius: 5)
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.white)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
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
                        
                        // Username - Fixed the display issue
                        Text(username.isEmpty ? "Loading..." : username)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                    }
                    .offset(y: 60)
                }
                .padding(.bottom, 70)
                .overlay(alignment: .topLeading) {
                    // Back button that actually works
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                            .padding(.top, 40)
                            .padding(.leading, 16)
                    }
                }
                
                // Error message if any
                if !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.top, 20)
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding(.top, 30)
                } else {
                    // Stats Cards Section
                    VStack(spacing: 20) {
                        HStack(spacing: 15) {
                            // Streak card
                            statsCard(
                                icon: "flame.fill",
                                iconColor: .orange,
                                title: "Current Streak",
                                value: "\(streak)",
                                subtitle: lastCheckInText()
                            )
                            
                            // Completed Sessions card
                            statsCard(
                                icon: "checkmark.circle.fill",
                                iconColor: .green,
                                title: "Sessions Completed",
                                value: "\(completedSessions)",
                                subtitle: "All time"
                            )
                        }
                        
                        HStack(spacing: 15) {
                            // This week card
                            statsCard(
                                icon: "calendar",
                                iconColor: .blue,
                                title: "This Week",
                                value: "\(completedThisWeek)",
                                subtitle: "Sessions completed"
                            )
                            
                            // Email card
                            statsCard(
                                icon: "envelope.fill",
                                iconColor: .purple,
                                title: "Email",
                                value: email,
                                subtitle: "Account"
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 15)
                    
                    // Logout button
                    Button(action: {
                        try? Auth.auth().signOut()
                        isLoggedIn = false
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 30)
                    .padding(.bottom, 50)
                    
                    // Bottom nav bar spacer
                    Spacer(minLength: 80)
                }
            }
        }
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            loadImageFromDisk()
            loadProfile()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
    private func statsCard(icon: String, iconColor: Color, title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                
                Spacer()
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if title == "Email" {
                Text(value)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func lastCheckInText() -> String {
        guard let lastCheckIn = lastCheckIn else {
            return "No check-ins yet"
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(lastCheckIn) {
            return "Checked in today"
        } else if calendar.isDateInYesterday(lastCheckIn) {
            return "Last check-in: Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return "Last check-in: \(formatter.string(from: lastCheckIn))"
        }
    }
    
    // load user profile info from firestore
    func loadProfile() {
        isLoading = true
        
        guard let uid = Auth.auth().currentUser?.uid else {
            error = "No logged in user"
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, err in
            if let err = err {
                error = "Failed to load profile: \(err.localizedDescription)"
                isLoading = false
                return
            }
            
            if let data = snapshot?.data() {
                // Debug: Check what data is being received
                print("Raw data from Firebase: \(data)")
                
                // Try to get username with different possible field names
                let possibleUsername = data["username"] as? String ??
                                      data["userName"] as? String ??
                                      data["name"] as? String
                
                print("Username from Firebase: '\(possibleUsername ?? "nil")'")
                
                DispatchQueue.main.async {
                    self.username = possibleUsername ?? "Unknown"
                    self.email = data["email"] as? String ?? "Unknown"
                    self.streak = data["streak"] as? Int ?? 0
                    self.completedSessions = data["completedSessions"] as? Int ?? 0
                    
                    print("Final username: '\(self.username)'")
                    
                    // Get the last check-in date
                    if let lastCheckInTimestamp = data["lastCheckIn"] as? Timestamp {
                        self.lastCheckIn = lastCheckInTimestamp.dateValue()
                    }
                    
                    self.isLoading = false
                }
                
                // Now fetch additional data in background
                countTotalWorkouts(uid: uid)
                countCompletedSessionsThisWeek(uid: uid)
            } else {
                DispatchQueue.main.async {
                    self.error = "User data not found"
                    self.isLoading = false
                }
            }
        }
    }

    private func countTotalWorkouts(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("workouts")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching workout count: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.totalWorkouts = snapshot?.documents.count ?? 0
                    }
                }
            }
    }

    private func countCompletedSessionsThisWeek(uid: String) {
        let db = Firestore.firestore()
        let calendar = Calendar.current
        
        // Get start of current week
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        // Look for workouts with lastCompletedDate in this week
        db.collection("users").document(uid).collection("workouts")
            .whereField("lastCompletedDate", isGreaterThanOrEqualTo: Timestamp(date: startOfWeek))
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching weekly completed sessions: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.completedThisWeek = 0
                    }
                } else {
                    DispatchQueue.main.async {
                        self.completedThisWeek = snapshot?.documents.count ?? 0
                    }
                }
            }
    }
    
    // Save profile image to local file
    func saveImageLocally(image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: imagePath)
        }
    }
    
    // Load profile image from local file
    func loadImageFromDisk() {
        if FileManager.default.fileExists(atPath: imagePath.path) {
            selectedImage = UIImage(contentsOfFile: imagePath.path)
        }
    }
}
