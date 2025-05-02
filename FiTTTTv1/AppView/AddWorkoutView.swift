import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DayButton: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

struct LogWorkoutView: View {
    // MARK: - Properties
    
    // Workout details
    @State private var workoutName = ""
    @State private var muscleGroup = ""
    @State private var selectedDays: Set<String> = []
    @State private var workoutDuration = ""
    @State private var notes = ""
    
    // Exercise management
    @State private var exercises: [ExerciseItem] = []
    @State private var editingExercise: ExerciseItem?
    @State private var isEditingExercise = false
    @State private var showingExerciseSheet = false
    
    // UI states
    @State private var isSaving = false
    @State private var showingSavedAlert = false
    @State private var errorMessage = ""
    @State private var showingDeleteAlert = false
    @State private var exerciseToDelete: ExerciseItem?
    
    // Environment
    @Environment(\.presentationMode) var presentationMode
    
    // Options
    let muscleGroups = ["Chest", "Back", "Legs", "Arms", "Shoulders", "Core", "Full Body", "Cardio"]
    let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    Text("Build Your Workout Session")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.horizontal)
                    
                    // Workout details section
                    workoutDetailsSection
                    
                    // Exercise list section
                    exerciseSection
                    
                    // Notes section
                    notesSection
                    
                    // Save button
                    saveButton
                }
                .padding(.vertical, 20)
            }
            
            // Bottom Tab Bar
            bottomTabBar
        }
        .background(Color(.systemGray6))
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingExerciseSheet) {
            ExerciseEditorView(
                exercise: editingExercise,
                onSave: { updatedExercise in
                    if let index = exercises.firstIndex(where: { $0.id == updatedExercise.id }) {
                        exercises[index] = updatedExercise
                    } else {
                        exercises.append(updatedExercise)
                    }
                }
            )
        }
        .alert(isPresented: $showingSavedAlert) {
            Alert(
                title: Text(errorMessage.isEmpty ? "Workout Saved" : "Error"),
                message: Text(errorMessage.isEmpty ? "Your workout has been successfully logged!" : errorMessage),
                dismissButton: .default(Text("OK")) {
                    if errorMessage.isEmpty {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
        .confirmationDialog(
            "Are you sure you want to delete this exercise?",
            isPresented: $showingDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let exercise = exerciseToDelete, let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                    exercises.remove(at: index)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - Component Views
    
    private var workoutDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Workout Details")
                .font(.headline)
                .padding(.horizontal)
            
            // Card background for details
            VStack(spacing: 16) {
                // Workout name
                inputField(
                    title: "Workout Session Name",
                    placeholder: "e.g. Morning Power Routine",
                    binding: $workoutName
                )
                
                // Muscle group selector
                VStack(alignment: .leading, spacing: 6) {
                    Text("Muscle Group")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Menu {
                        ForEach(muscleGroups, id: \.self) { group in
                            Button(group) {
                                muscleGroup = group
                            }
                        }
                    } label: {
                        HStack {
                            Text(muscleGroup.isEmpty ? "Select Muscle Group" : muscleGroup)
                                .foregroundColor(muscleGroup.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                    }
                }
                
                // Day selector - horizontal multi-select
                VStack(alignment: .leading, spacing: 6) {
                    Text("Workout Days")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(daysOfWeek, id: \.self) { day in
                                DayButton(
                                    day: day,
                                    isSelected: selectedDays.contains(day),
                                    action: {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(.horizontal, 4)
                }
                
                // Duration
                inputField(
                    title: "Duration",
                    placeholder: "e.g. 45 minutes",
                    binding: $workoutDuration
                )
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercises")
                .font(.headline)
                .padding(.horizontal)
            
            if exercises.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No exercises added yet")
                        .foregroundColor(.secondary)
                    
                    Text("Add exercises to track your workout performance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            } else {
                // Exercise list
                VStack(spacing: 0) {
                    ForEach(exercises) { exercise in
                        VStack(spacing: 0) {
                            exerciseRow(exercise)
                            
                            if exercise.id != exercises.last?.id {
                                Divider()
                                    .padding(.leading)
                            }
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
            
            // Add exercise button
            Button {
                editingExercise = nil
                showingExerciseSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("Add Exercise")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes")
                .font(.headline)
                .padding(.horizontal)
            
            TextEditor(text: $notes)
                .frame(height: 120)
                .padding(10)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
        }
    }
    
    private var saveButton: some View {
        Button(action: saveWorkout) {
            HStack {
                Spacer()
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .foregroundColor(.white)
                } else {
                    Text("Save Workout")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding()
            .background(
                isFormValid ? Color.accentColor : Color.gray
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
            .disabled(!isFormValid || isSaving)
        }
        .padding(.top, 16)
    }
    
    private var bottomTabBar: some View {
        HStack {
            Spacer()
            NavigationLink(destination: ContentView()) {
                Image(systemName: "house")
                    .font(.system(size: 24))
            }
            Spacer()
            Image(systemName: "dumbbell")
                .font(.system(size: 32))
            Spacer()
            NavigationLink(destination: FriendsView()) {
                Image(systemName: "person.2")
                    .font(.system(size: 24))
            }
            Spacer()
            NavigationLink(destination: CalendarView()) {
                Image(systemName: "calendar")
                    .font(.system(size: 24))
            }
            Spacer()
        }
        .padding()
        .background(Color.black)
        .foregroundColor(.white)
    }
    
    // MARK: - Helper Functions and Views
    
    private func inputField(title: String, placeholder: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: binding)
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(10)
        }
    }
    
    private func exerciseRow(_ exercise: ExerciseItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.headline)
                
                Text("\(exercise.sets) sets × \(exercise.reps) reps × \(exercise.weight)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Edit button
            Button {
                editingExercise = exercise
                showingExerciseSheet = true
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(.accentColor)
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            // Delete button
            Button {
                exerciseToDelete = exercise
                showingDeleteAlert = true
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    // Form validation
    var isFormValid: Bool {
        !workoutName.isEmpty && !muscleGroup.isEmpty && !selectedDays.isEmpty && !workoutDuration.isEmpty && !exercises.isEmpty
    }
    
    // MARK: - Firebase Functions
    
    // Save workout to Firebase
    func saveWorkout() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "You need to be logged in to save workouts"
            showingSavedAlert = true
            return
        }
        
        isSaving = true
        
        // Create Firestore reference
        let db = Firestore.firestore()
        let workoutId = UUID().uuidString
        
        // Workout data to save
        let workoutData: [String: Any] = [
            "workoutName": workoutName,
            "muscleGroup": muscleGroup,
            "workoutDays": Array(selectedDays),
            "duration": workoutDuration,
            "workoutDate": Timestamp(date: Date()),  // Current date automatically
            "notes": notes,
            "exerciseCount": exercises.count,
            "userId": userId,
            "createdAt": Timestamp(date: Date())
        ]
        
        // Save workout to Firestore
        db.collection("users").document(userId).collection("workouts").document(workoutId)
            .setData(workoutData) { error in
                if let error = error {
                    isSaving = false
                    errorMessage = "Error saving workout: \(error.localizedDescription)"
                    showingSavedAlert = true
                    return
                }
                
                // Now save all exercises for this workout
                let exercisesGroup = DispatchGroup()
                
                for exercise in exercises {
                    exercisesGroup.enter()
                    
                    let exerciseData: [String: Any] = [
                        "name": exercise.name,
                        "sets": exercise.sets,
                        "reps": exercise.reps,
                        "weight": exercise.weight,
                        "notes": exercise.notes,
                        "workoutId": workoutId
                    ]
                    
                    db.collection("users").document(userId).collection("workouts")
                        .document(workoutId).collection("exercises").document()
                        .setData(exerciseData) { error in
                            if let error = error {
                                print("Error saving exercise: \(error.localizedDescription)")
                            }
                            exercisesGroup.leave()
                        }
                }
                
                // Once all exercises are saved
                exercisesGroup.notify(queue: .main) {
                    // Update user streak
                    updateUserStreak(userId: userId)
                    
                    isSaving = false
                    errorMessage = ""
                    showingSavedAlert = true
                }
            }
    }
    
    // Update user's workout streak
    private func updateUserStreak(userId: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let userDocument: DocumentSnapshot
            do {
                try userDocument = transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            // Get the last workout date if available
            let lastWorkoutDate = userDocument.data()?["lastWorkoutDate"] as? Timestamp
            let currentStreak = userDocument.data()?["streak"] as? Int ?? 0
            
            let calendar = Calendar.current
            let now = Date()
            var newStreak = currentStreak
            
            if let lastDate = lastWorkoutDate?.dateValue() {
                // If last workout was yesterday, increment streak
                if calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now)!) {
                    newStreak += 1
                }
                // If last workout was more than a day ago, reset streak to 1
                else if !calendar.isDateInToday(lastDate) {
                    newStreak = 1
                }
                // If last workout was today, maintain streak
            } else {
                // First workout ever
                newStreak = 1
            }
            
            transaction.updateData([
                "streak": newStreak,
                "lastWorkoutDate": Timestamp(date: now)
            ], forDocument: userRef)
            
            return nil
        }) { (_, error) in
            if let error = error {
                print("Transaction failed: \(error)")
            }
        }
    }
}

// MARK: - Supporting Structs

struct ExerciseItem: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var sets: Int
    var reps: String
    var weight: String
    var notes: String = ""
    
    static func == (lhs: ExerciseItem, rhs: ExerciseItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct ExerciseEditorView: View {
    @State private var exerciseName: String
    @State private var sets: Int
    @State private var reps: String
    @State private var weight: String
    @State private var notes: String
    
    private var isNewExercise: Bool
    private var exerciseId: UUID
    private var onSave: (ExerciseItem) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    init(exercise: ExerciseItem? = nil, onSave: @escaping (ExerciseItem) -> Void) {
        let exercise = exercise ?? ExerciseItem(name: "", sets: 3, reps: "10", weight: "0")
        
        _exerciseName = State(initialValue: exercise.name)
        _sets = State(initialValue: exercise.sets)
        _reps = State(initialValue: exercise.reps)
        _weight = State(initialValue: exercise.weight)
        _notes = State(initialValue: exercise.notes)
        
        self.exerciseId = exercise.id
        self.isNewExercise = exercise.name.isEmpty
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Exercise Name", text: $exerciseName)
                    
                    Stepper("Sets: \(sets)", value: $sets, in: 1...10)
                    
                    HStack {
                        Text("Reps:")
                        TextField("10", text: $reps)
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        Text("Weight:")
                        TextField("0", text: $weight)
                            .keyboardType(.decimalPad)
                        Text("lbs")
                    }
                } header: {
                    Text("Exercise Details")
                }
                
                Section {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                } header: {
                    Text("Notes")
                }
                
                Section {
                    // Exercise suggestions based on muscle groups
                    Text("Popular Exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            exerciseSuggestion("Bench Press")
                            exerciseSuggestion("Squat")
                            exerciseSuggestion("Deadlift")
                            exerciseSuggestion("Pull Up")
                            exerciseSuggestion("Overhead Press")
                        }
                    }
                }
            }
            .navigationTitle(isNewExercise ? "Add Exercise" : "Edit Exercise")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let updatedExercise = ExerciseItem(
                        id: exerciseId,
                        name: exerciseName,
                        sets: sets,
                        reps: reps,
                        weight: weight,
                        notes: notes
                    )
                    onSave(updatedExercise)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(exerciseName.isEmpty)
            )
        }
    }
    
    private func exerciseSuggestion(_ name: String) -> some View {
        Button {
            exerciseName = name
        } label: {
            Text(name)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(16)
        }
    }
}

struct LogWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        LogWorkoutView()
    }
}
