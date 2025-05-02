//
//  CalendarView.swift
//  FiTTTTv1
//
//
import SwiftUI
import FSCalendar
import FirebaseFirestore
import FirebaseAuth

struct CalendarView: View {
    @State private var workouts: [Workout] = []  // Stores workouts
    @State private var selectedDate: Date?
    @State private var selectedDateWorkouts: [Workout] = []
    let calendar = FSCalendar()

    var body: some View {
        VStack(spacing: 0) {
            // Calendar content
            FSCalendarView(workouts: workouts, selectedDate: $selectedDate)
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
                    
                    if selectedDateWorkouts.isEmpty {
                        Text("No workouts for this date")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(selectedDateWorkouts) { workout in
                                    workoutCard(workout)
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
    }
    
    private func workoutCard(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(workout.name)
                .font(.headline)
            
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
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func updateSelectedDateWorkouts(_ date: Date) {
        selectedDateWorkouts = workouts.filter { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: date)
        }
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
                            let workout = Workout(
                                id: document.documentID,
                                name: document["workoutName"] as? String ?? "",
                                muscleGroup: document["muscleGroup"] as? String ?? "",
                                days: document["workoutDays"] as? [String] ?? [],
                                duration: document["duration"] as? String ?? "",
                                date: workoutDate
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

struct FSCalendarView: UIViewRepresentable {
    var workouts: [Workout]
    @Binding var selectedDate: Date?

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
        return Coordinator(workouts: workouts, selectedDate: $selectedDate)
    }
    
    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource {
        var workouts: [Workout]
        @Binding var selectedDate: Date?
        
        init(workouts: [Workout], selectedDate: Binding<Date?>) {
            self.workouts = workouts
            self._selectedDate = selectedDate
        }
        
        // This method checks if a workout exists for a particular date
        func calendar(_ calendar: FSCalendar, hasEventForDate date: Date) -> Bool {
            return workouts.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
        }
        
        // Handle date selection
        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            selectedDate = date
        }
    }
}

// Updated Workout Model
struct Workout: Identifiable {
    var id: String
    var name: String
    var muscleGroup: String
    var days: [String]?  // Multiple days for the workout
    var duration: String
    var date: Date
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
