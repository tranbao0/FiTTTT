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
    let calendar = FSCalendar()

    var body: some View {
        VStack {
            FSCalendarView(workouts: workouts)
                .onAppear {
                    fetchWorkouts()
                }
        }
        .padding()
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
                                name: document["workoutName"] as? String ?? "",
                                muscleGroup: document["muscleGroup"] as? String ?? "",
                                day: document["workoutDay"] as? String ?? "",
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
                }
            }
    }
}

struct FSCalendarView: UIViewRepresentable {
    var workouts: [Workout]

    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        return calendar
    }
    
    func updateUIView(_ uiView: FSCalendar, context: Context) {
        uiView.reloadData()  // Reload data when workouts change
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(workouts: workouts)
    }
    
    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource {
        var workouts: [Workout]
        
        init(workouts: [Workout]) {
            self.workouts = workouts
        }
        
        // This method checks if a workout exists for a particular date
        func calendar(_ calendar: FSCalendar, hasEventForDate date: Date) -> Bool {
            return workouts.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
        }
    }
}

// Workout Model
struct Workout: Identifiable {
    var id = UUID()
    var name: String
    var muscleGroup: String
    var day: String
    var duration: String
    var date: Date
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
