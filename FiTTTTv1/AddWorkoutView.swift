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
    @State private var workoutDay = ""
    @State private var duration = ""
    @State private var successMessage = ""
    
    // Days of the week for user to select from
    let daysOfWeek = [
        "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
    ]
    
    // Muscle Groups for the workout
    let muscleGroups = [
        "Chest", "Back", "Legs", "Arms", "Shoulders", "Core", "Full Body"
    ]
    
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
                    ForEach(muscleGroups, id: \.self) { group in
                        Text(group).tag(group)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.bottom, 10)
            }
            
            // Workout Day Picker
            VStack(alignment: .leading) {
                Text("Select Day of Workout")
                    .font(.subheadline)
                
                Picker("Workout Day", selection: $workoutDay) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day).tag(day)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.bottom, 10)
            }
            
            // Duration Text Field
            TextField("Duration (e.g., 1 hour, 45 minutes)", text: $duration)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.bottom, 10)
            
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
        guard !workoutName.isEmpty, !muscleGroup.isEmpty, !workoutDay.isEmpty, !duration.isEmpty else {
            successMessage = "Please fill in all fields."
            return
        }
        
        let userId = Auth.auth().currentUser?.uid
        let db = Firestore.firestore()
        
        // Calculate the date of the workout based on the selected day
        let workoutDate = getWorkoutDate(forDay: workoutDay)
        
        let workoutData: [String: Any] = [
            "workoutName": workoutName,
            "muscleGroup": muscleGroup,
            "workoutDay": workoutDay,
            "duration": duration,
            "workoutDate": workoutDate,
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
    
    // Get the actual date based on the selected workout day
    private func getWorkoutDate(forDay day: String) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today) // 1 = Sunday, 7 = Saturday
        
        var dayIndex: Int
        
        switch day {
        case "Sunday":
            dayIndex = 1
        case "Monday":
            dayIndex = 2
        case "Tuesday":
            dayIndex = 3
        case "Wednesday":
            dayIndex = 4
        case "Thursday":
            dayIndex = 5
        case "Friday":
            dayIndex = 6
        case "Saturday":
            dayIndex = 7
        default:
            dayIndex = weekday
        }
        
        let daysToAdd = (dayIndex - weekday + 7) % 7
        let workoutDate = calendar.date(byAdding: .day, value: daysToAdd, to: today)
        
        return workoutDate!
    }
}

struct LogWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        LogWorkoutView()
    }
}
