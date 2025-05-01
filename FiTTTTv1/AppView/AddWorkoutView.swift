//
//  AddWorkoutView.swift
//  FiTTTTv1
//
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct LogWorkoutView: View {
    @State private var workoutName = ""
    @State private var muscleGroup = ""
    @State private var selectedDate = Date()  // DatePicker for selecting workout date
    @State private var duration = 15  // Default duration is 15 minutes
    @State private var successMessage = ""

    // Duration options (increments of 15 minutes, max 120 minutes)
    private let durationOptions = Array(stride(from: 15, to: 121, by: 15))

    var body: some View {
        VStack {
            Text("Log a New Workout")
                .font(.title)
                .padding()

            // Workout Name
            TextField("Workout Name (e.g., Leg Day)", text: $workoutName)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.bottom, 10)

            // Muscle Group Picker
            VStack(alignment: .leading) {
                Text("Select Muscle Group")
                    .font(.subheadline)

                Picker("Muscle Group", selection: $muscleGroup) {
                    ForEach(["Chest", "Back", "Legs", "Arms", "Shoulders", "Core", "Full Body"], id: \.self) { group in
                        Text(group).tag(group)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.bottom, 10)
            }

            // Date Picker for workout date
            DatePicker("Select Workout Date", selection: $selectedDate, displayedComponents: .date)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.bottom, 10)

            // Duration Picker (in increments of 15 minutes)
            Picker("Duration", selection: $duration) {
                ForEach(durationOptions, id: \.self) { duration in
                    Text("\(duration) min")
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.bottom, 20)

            // Save Button
            Button(action: saveWorkout) {
                Text("Save Workout")
                    .foregroundColor(.white)
                    .frame(width: 250, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)

            // Success/Error Message
            if !successMessage.isEmpty {
                Text(successMessage)
                    .foregroundColor(successMessage == "Workout saved!" ? .green : .red)
                    .padding(.top, 10)
            }

            Spacer()
        }
        .padding()
    }

    // Save the workout details to Firestore
    private func saveWorkout() {
        guard !workoutName.isEmpty, !muscleGroup.isEmpty else {
            successMessage = "Please fill in all fields."
            return
        }

        let userId = Auth.auth().currentUser?.uid
        let db = Firestore.firestore()

        let workoutData: [String: Any] = [
            "workoutName": workoutName,
            "muscleGroup": muscleGroup,
            "workoutDate": selectedDate,
            "duration": duration,
            "userId": userId ?? ""
        ]

        // Save to Firestore
        db.collection("users").document(userId!).collection("workouts").addDocument(data: workoutData) { error in
            if let error = error {
                successMessage = "Error saving workout: \(error.localizedDescription)"
            } else {
                successMessage = "Workout saved!"
            }
        }
    }
}

struct LogWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        LogWorkoutView()
    }
}
