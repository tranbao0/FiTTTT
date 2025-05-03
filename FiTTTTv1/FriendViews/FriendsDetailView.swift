import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// Add an enum for notification types
enum AppNotificationType: String {
    case remind
    case confront
}

struct FriendDetailView: View {
    let friend: Friend

    @State private var friendWorkouts: [Workout] = []
    @State private var isLoading = true
    @State private var error = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var hasUncompletedWorkoutToday: Bool {
        let today = Date()
        return friendWorkouts.contains { workout in
            guard let lastCompleted = workout.lastCompletedDate else { return true }
            return !Calendar.current.isDate(lastCompleted, inSameDayAs: today)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(radius: 5)
                    .foregroundColor(.gray)

                Text(friend.name)
                    .font(.largeTitle)
                    .bold()

                Text("Streak: \(friend.streak) days")
                    .font(.title2)
                    .foregroundColor(.gray)

                if hasUncompletedWorkoutToday {
                    if friend.streak == 0 {
                        Button(action: {
                            sendNotification(message: "WHY DID YOU SKIP YESTERDAY?!?!?!", type: .confront)
                        }) {
                            Text("CONFRONT")
                                .bold()
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            sendNotification(message: "Reminder to complete your workout today!", type: .remind)
                        }) {
                            Text("Remind")
                                .bold()
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                    }
                }

                Divider()

                // Today's Activities Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Today's Workouts")
                        .font(.headline)
                        .padding(.horizontal)

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if !error.isEmpty {
                        Text("Error loading workouts: \(error)")
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    } else if friendWorkouts.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 30))
                                .foregroundColor(.secondary)
                            Text("No activities")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        ForEach(friendWorkouts) { workout in
                            workoutCard(workout)
                        }
                    }
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding()
        }
        .navigationTitle(friend.name)
        .onAppear {
            fetchFriendWorkouts()
        }
        // Success popup (for successful notifications)
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(successMessage)
        }
        // Error popup (for failed notifications)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func workoutCard(_ workout: Workout) -> some View {
        let isWorkoutCompletedToday = workout.lastCompletedDate != nil &&
            Calendar.current.isDateInToday(workout.lastCompletedDate!)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(isWorkoutCompletedToday ? .gray : .primary)

                Spacer()

                if isWorkoutCompletedToday {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }

            HStack {
                Text(workout.muscleGroup)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(8)

                Spacer()

                Text(workout.duration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let days = workout.days, !days.isEmpty {
                HStack {
                    Text("Days:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }

            if isWorkoutCompletedToday {
                Text("Completed today")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }

    private func fetchFriendWorkouts() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            self.error = "Not logged in"
            self.isLoading = false
            return
        }

        let db = Firestore.firestore()

        db.collection("users").document(friend.id)
            .collection("friends").document(currentUserId)
            .getDocument { docSnapshot, error in
                if let error = error {
                    self.error = "Error checking friendship: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }

                guard let doc = docSnapshot, doc.exists else {
                    self.error = "You're not friends with this user"
                    self.isLoading = false
                    return
                }

                fetchTodayWorkouts(for: friend.id)
            }
    }

    private func fetchTodayWorkouts(for friendId: String) {
        let db = Firestore.firestore()
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        db.collection("users").document(friendId).collection("workouts")
            .whereField("workoutDate", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("workoutDate", isLessThan: Timestamp(date: endOfDay))
            .getDocuments { snapshot, error in
                self.isLoading = false

                if let error = error {
                    self.error = "Failed to load workouts: \(error.localizedDescription)"
                    return
                }

                if let snapshot = snapshot {
                    self.friendWorkouts = snapshot.documents.compactMap { doc in
                        if let workoutDate = (doc["workoutDate"] as? Timestamp)?.dateValue() {
                            let lastCompletedDate = (doc["lastCompletedDate"] as? Timestamp)?.dateValue()
                            return Workout(
                                id: doc.documentID,
                                name: doc["workoutName"] as? String ?? "",
                                muscleGroup: doc["muscleGroup"] as? String ?? "",
                                days: doc["workoutDays"] as? [String] ?? [],
                                duration: doc["duration"] as? String ?? "",
                                date: workoutDate,
                                lastCompletedDate: lastCompletedDate
                            )
                        }
                        return nil
                    }
                }
            }
    }

    private func sendNotification(message: String, type: AppNotificationType) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to send notifications"
            showingError = true
            return
        }
        
        let db = Firestore.firestore()
        
        // Get current user's username first
        db.collection("users").document(currentUserId).getDocument { snapshot, error in
            if let error = error {
                errorMessage = "Error getting user data: \(error.localizedDescription)"
                showingError = true
                return
            }
            
            let username = snapshot?.data()?["username"] as? String ?? "Unknown"
            
            let notification = [
                "message": message,
                "timestamp": FieldValue.serverTimestamp(),
                "read": false,
                "fromUserId": currentUserId,
                "fromUsername": username,
                "type": type.rawValue
            ] as [String: Any]
            
            db.collection("users")
                .document(friend.id)
                .collection("notifications")
                .addDocument(data: notification) { error in
                    if let error = error {
                        errorMessage = "Error sending notification: \(error.localizedDescription)"
                        showingError = true
                    } else {
                        // Show success message based on the type of notification
                        switch type {
                        case .remind:
                            successMessage = "Reminder sent to \(friend.name)!"
                        case .confront:
                            successMessage = "\(friend.name) has been confronted!"
                        }
                        showingSuccess = true
                    }
                }
        }
    }
}
