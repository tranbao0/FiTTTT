import SwiftUI
import FSCalendar
import FirebaseFirestore
import FirebaseAuth

// First, let's enhance our Workout model to track completion status
struct Workout: Identifiable {
    var id: String
    var name: String
    var muscleGroup: String
    var days: [String]?  // Multiple days for the workout
    var duration: String
    var date: Date
    var isCompleted: Bool = false  // Track completion status
    var lastCompletedDate: Date?   // Track when it was last completed
}

struct CalendarView: View {
    @State private var workouts: [Workout] = []  // Stores workouts
    @State private var selectedDate: Date?
    @State private var selectedDateWorkouts: [Workout] = []
    @State private var allWorkoutsOnSelectedDay: [Workout] = []
    @State private var showingCheckInAlert = false
    @State private var checkInMessage = ""
    
    let calendar = FSCalendar()
    
    // Check if the selected date is today
    private var isSelectedDateToday: Bool {
        guard let selectedDate = selectedDate else { return false }
        return Calendar.current.isDateInToday(selectedDate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView()
            // Calendar content
            FSCalendarView(workouts: workouts, selectedDate: $selectedDate, getWorkoutsForDate: getWorkoutsForDate)
                .onAppear {
                    fetchWorkouts()
                }
                .padding()
                .frame(height: 300)
            
            // Workouts for selected date
            if let selectedDate = selectedDate {
                VStack(alignment: .leading, spacing: 15) {
                    Text(formatDate(selectedDate))
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if allWorkoutsOnSelectedDay.isEmpty {
                        Text("No workouts for this date")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                    } else {
                        // Let user know they can only mark workouts as complete on the current day
                        if !isSelectedDateToday && !allWorkoutsSelectedDayCompleted() {
                            Text("You can only mark workouts as completed for today")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(allWorkoutsOnSelectedDay.indices, id: \.self) { index in
                                    let workout = allWorkoutsOnSelectedDay[index]
                                    workoutCard(workout, index: index)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top)
            }

            Spacer()

            // Bottom Tab Bar
            HStack {
                Spacer()
                NavigationLink(destination: ContentView()) {
                    Image(systemName: "house")
                        .font(.system(size: 24))
                }
                Spacer()
                NavigationLink(destination: LogWorkoutView()) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 24))
                }
                Spacer()
                NavigationLink(destination: FriendsView()) {
                    Image(systemName: "person.2")
                        .font(.system(size: 24))
                }
                Spacer()
                Image(systemName: "calendar")
                    .font(.system(size: 32))
                Spacer()
            }
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden(true)
        .onChange(of: selectedDate) { newDate in
            if let date = newDate {
                updateSelectedDateWorkouts(date)
            }
        }
        .alert(isPresented: $showingCheckInAlert) {
            Alert(
                title: Text("Workout Completed"),
                message: Text(checkInMessage),
                dismissButton: .default(Text("Great!"))
            )
        }
    }
    
    // Check if all workouts for the selected day are completed
    private func allWorkoutsSelectedDayCompleted() -> Bool {
        guard !allWorkoutsOnSelectedDay.isEmpty else { return false }
        return allWorkoutsOnSelectedDay.allSatisfy {
            if let lastCompleted = $0.lastCompletedDate {
                return Calendar.current.isDate(lastCompleted, inSameDayAs: selectedDate ?? Date())
            }
            return false
        }
    }
    
    private func workoutCard(_ workout: Workout, index: Int) -> some View {
        let isWorkoutCompletedToday = workout.lastCompletedDate != nil &&
                                      Calendar.current.isDateInToday(workout.lastCompletedDate!)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(isWorkoutCompletedToday ? .gray : .primary)
                
                Spacer()
                
                // Show completion checkmark only for today's workouts
                if isSelectedDateToday {
                    Button(action: {
                        if !isWorkoutCompletedToday {
                            markWorkoutAsCompleted(at: index)
                        }
                    }) {
                        Image(systemName: isWorkoutCompletedToday ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isWorkoutCompletedToday ? .green : .gray)
                            .font(.title2)
                    }
                    .disabled(isWorkoutCompletedToday)
                }
            }
            
            HStack {
                Text(workout.muscleGroup)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(isWorkoutCompletedToday ? 0.1 : 0.2))
                    .cornerRadius(8)
                    .foregroundColor(isWorkoutCompletedToday ? .gray : .primary)
                
                Spacer()
                
                Text(workout.duration)
                    .font(.subheadline)
                    .foregroundColor(isWorkoutCompletedToday ? .gray : .secondary)
            }
            
            if let days = workout.days, !days.isEmpty {
                HStack {
                    Text("Days:")
                        .font(.subheadline)
                        .foregroundColor(isWorkoutCompletedToday ? .gray : .secondary)
                    
                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(isWorkoutCompletedToday ? 0.1 : 0.2))
                            .cornerRadius(4)
                            .foregroundColor(isWorkoutCompletedToday ? .gray : .primary)
                    }
                }
            }
            
            // Show "Completed today" badge if workout was completed today
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
        .opacity(isWorkoutCompletedToday ? 0.8 : 1.0)
    }
    
    // Mark a workout as completed
    private func markWorkoutAsCompleted(at index: Int) {
        guard index < allWorkoutsOnSelectedDay.count else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let workoutId = allWorkoutsOnSelectedDay[index].id
        let today = Date()
        
        // Update in local state
        var updatedWorkout = allWorkoutsOnSelectedDay[index]
        updatedWorkout.lastCompletedDate = today
        
        // Find index of this workout in the main workouts array
        if let mainIndex = workouts.firstIndex(where: { $0.id == workoutId }) {
            workouts[mainIndex].lastCompletedDate = today
        }
        
        // Update in Firestore
        db.collection("users").document(userId).collection("workouts").document(workoutId)
            .updateData([
                "lastCompletedDate": Timestamp(date: today)
            ]) { error in
                if let error = error {
                    print("Error updating workout completion: \(error.localizedDescription)")
                } else {
                    // Refresh local data
                    if let date = selectedDate {
                        updateSelectedDateWorkouts(date)
                    }
                    
                    // Check if user has already checked in today
                    checkIfUserCheckedInToday { hasCheckedIn in
                        if !hasCheckedIn {
                            // Auto check-in for the user
                            updateUserStreak(userId: userId) { streak in
                                checkInMessage = "Great job! Your workout streak is now \(streak) days! 🔥"
                                showingCheckInAlert = true
                            }
                        } else {
                            increaseCompletedSessions(userId: userId) {
                                checkInMessage = "Workout marked as complete!"
                                showingCheckInAlert = true
                            }
                        }
                    }
                }
            }
    }
    
    // Check if user has already checked in today
    private func checkIfUserCheckedInToday(completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error getting document: \(error)")
                completion(false)
                return
            }
            
            if let data = snapshot?.data(),
               let lastCheckIn = data["lastCheckIn"] as? Timestamp {
                // Check if last check-in was today
                let calendar = Calendar.current
                let hasCheckedIn = calendar.isDateInToday(lastCheckIn.dateValue())
                completion(hasCheckedIn)
            } else {
                completion(false)
            }
        }
    }
    
    // Update user's streak and check-in status
    private func updateUserStreak(userId: String, completion: @escaping (Int) -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            // Get current streak and last check-in date
            let currentStreak = document.data()?["streak"] as? Int ?? 0
            let lastCheckIn = document.data()?["lastCheckIn"] as? Timestamp
            
            let now = Date()
            let calendar = Calendar.current
            var newStreak = currentStreak
            
            if let lastDate = lastCheckIn?.dateValue() {
                // If last check-in was yesterday, increment streak
                if calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now)!) {
                    newStreak += 1
                }
                // If last check-in was more than a day ago, reset streak to 1
                else if !calendar.isDateInToday(lastDate) {
                    newStreak = 1
                }
                // If last check-in was today, maintain streak (shouldn't happen due to previous check)
            } else {
                // First check-in ever
                newStreak = 1
            }
            
            // Update both streak and last check-in
            transaction.updateData([
                "streak": newStreak,
                "lastCheckIn": Timestamp(date: now),
                "completedSessions": FieldValue.increment(Int64(1))
            ], forDocument: userRef)
            
            return newStreak
        }) { (result, error) in
            if let error = error {
                print("Transaction failed: \(error)")
                completion(0)
            } else if let newStreak = result as? Int {
                completion(newStreak)
            }
        }
    }
    
    // Increment completed sessions counter
    private func increaseCompletedSessions(userId: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.updateData([
            "completedSessions": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error updating completed sessions: \(error)")
            }
            completion()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    // Get the day of week as a string from a date
    private func getDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // 3-letter abbreviation (e.g. "Mon")
        return formatter.string(from: date)
    }
    
    // Get the workouts that should appear on a specific date
    func getWorkoutsForDate(_ date: Date) -> [Workout] {
        // Don't show workouts for days before today
        if date < Calendar.current.startOfDay(for: Date()) {
            return []
        }
        
        let dayOfWeek = getDayOfWeek(date)
        
        return workouts.filter { workout in
            // Only include if workout is scheduled for this day of the week
            // AND the workout creation date is on or before this date
            if let days = workout.days, days.contains(dayOfWeek) {
                // Only show workouts on or after their creation date
                return date >= Calendar.current.startOfDay(for: workout.date)
            }
            return false
        }
    }
    
    private func updateSelectedDateWorkouts(_ date: Date) {
        // First, get workouts that were created on this exact date
        selectedDateWorkouts = workouts.filter { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: date)
        }
        
        // Then, get all workouts that should appear on this date (scheduled days)
        allWorkoutsOnSelectedDay = getWorkoutsForDate(date)
    }
    
    // Fetch workouts from Firestore
    private func fetchWorkouts() {
        // Safely unwrap userId from Firebase Authentication
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).collection("workouts")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching workouts: \(error.localizedDescription)")
                    return
                }
                
                // Safe unwrapping of snapshot and processing documents
                if let snapshot = snapshot {
                    var fetchedWorkouts: [Workout] = []
                    
                    for document in snapshot.documents {
                        if let workoutDate = (document["workoutDate"] as? Timestamp)?.dateValue() {
                            let lastCompletedDate = (document["lastCompletedDate"] as? Timestamp)?.dateValue()
                            
                            let workout = Workout(
                                id: document.documentID,
                                name: document["workoutName"] as? String ?? "",
                                muscleGroup: document["muscleGroup"] as? String ?? "",
                                days: document["workoutDays"] as? [String] ?? [],
                                duration: document["duration"] as? String ?? "",
                                date: workoutDate,
                                isCompleted: lastCompletedDate != nil,
                                lastCompletedDate: lastCompletedDate
                            )
                            fetchedWorkouts.append(workout)
                        } else {
                            print("Workout date is missing for document \(document.documentID)")
                        }
                    }
                    // Update the workouts list
                    workouts = fetchedWorkouts
                    
                    // Set initial selected date to today
                    selectedDate = Date()
                    if let date = selectedDate {
                        updateSelectedDateWorkouts(date)
                    }
                }
            }
    }
}

// FSCalendarView remains mostly the same
struct FSCalendarView: UIViewRepresentable {
    var workouts: [Workout]
    @Binding var selectedDate: Date?
    var getWorkoutsForDate: (Date) -> [Workout]

    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        
        // Calendar customization
        calendar.appearance.titleDefaultColor = .black
        calendar.appearance.headerTitleColor = .black
        calendar.appearance.weekdayTextColor = .darkGray
        calendar.appearance.selectionColor = UIColor(Color.accentColor)
        calendar.appearance.todayColor = UIColor(Color.accentColor.opacity(0.3))
        calendar.appearance.eventDefaultColor = UIColor(Color.accentColor)
        calendar.appearance.eventSelectionColor = UIColor(Color.accentColor)
        
        // Set today as selected by default
        calendar.select(Date())
        selectedDate = Date()
        
        return calendar
    }
    
    func updateUIView(_ uiView: FSCalendar, context: Context) {
        uiView.reloadData()  // Reload data when workouts change
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(workouts: workouts, selectedDate: $selectedDate, getWorkoutsForDate: getWorkoutsForDate)
    }
    
    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource {
        var workouts: [Workout]
        @Binding var selectedDate: Date?
        var getWorkoutsForDate: (Date) -> [Workout]
        
        init(workouts: [Workout], selectedDate: Binding<Date?>, getWorkoutsForDate: @escaping (Date) -> [Workout]) {
            self.workouts = workouts
            self._selectedDate = selectedDate
            self.getWorkoutsForDate = getWorkoutsForDate
        }
        
        // This method checks if a workout exists for a particular date
        func calendar(_ calendar: FSCalendar, hasEventForDate date: Date) -> Bool {
            // Get all workouts for this date based on scheduled days
            let workoutsForDate = getWorkoutsForDate(date)
            return !workoutsForDate.isEmpty
        }
        
        // Handle date selection
        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            selectedDate = date
        }
    }
}
