import SwiftUI
import WebKit
import FirebaseAuth
import FirebaseFirestore

struct ConfettiView: View {
    @State private var isActive = false
    let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple]
    
    var body: some View {
        ZStack {
            ForEach(0..<100, id: \.self) { i in
                Circle()
                    .fill(colors[i % colors.count])
                    .frame(width: CGFloat.random(in: 5...10))
                    .position(
                        x: isActive ? CGFloat.random(in: 0...UIScreen.main.bounds.width) : UIScreen.main.bounds.width/2,
                        y: isActive ? CGFloat.random(in: UIScreen.main.bounds.height/2...UIScreen.main.bounds.height) : UIScreen.main.bounds.height/2
                    )
                    .opacity(isActive ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: 1.5)
                            .delay(Double.random(in: 0...0.5)),
                        value: isActive
                    )
            }
        }
        .onAppear {
            isActive = true
        }
    }
}

// MARK: - YouTube Embed View
struct YouTubeView: UIViewRepresentable {
    let videoID: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.configuration.allowsInlineMediaPlayback = true
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let embedURL = "https://www.youtube.com/embed/\(videoID)?playsinline=1"
        if let url = URL(string: embedURL) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}

// MARK: - Placeholder Course Detail View
struct CourseDetailView: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.largeTitle)
            .padding()
    }
}

struct AppHeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "line.horizontal.3")
            Spacer()
            VStack(spacing: 4) {
                Image("FiTTTTLogoBlacked")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 40)
                Text("Accountability in Fitness")
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
            Spacer()
            NavigationLink(destination: ProfileView()) {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.black)
            }
        }
        .padding()
        .background(Color.white)
        .overlay(Rectangle().frame(height: 1).foregroundColor(.black), alignment: .bottom)
    }
}

struct ContentView: View {
    @State private var hasCheckedInToday: Bool = false
    @State private var streak: Int = 0
    @State private var showConfetti = false
    @State private var showStreak = false
    
    // Check if user has already checked in today
    private func checkIfUserCheckedInToday() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error getting document: \(error)")
                return
            }
            
            if let data = snapshot?.data() {
                if let lastCheckIn = data["lastCheckIn"] as? Timestamp {
                    // Check if last check-in was today
                    let calendar = Calendar.current
                    hasCheckedInToday = calendar.isDateInToday(lastCheckIn.dateValue())
                }
                
                // Get current streak
                streak = data["streak"] as? Int ?? 0
            }
        }
    }
    
    // Update user's streak in Firestore
    private func updateStreak() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        // Using a transaction to safely update the streak
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
                // If last check-in was today, maintain streak (shouldn't happen due to UI check)
                else if calendar.isDateInToday(lastDate) {
                    // Do nothing
                }
                // If last check-in was more than a day ago, reset streak to 1
                else {
                    newStreak = 1
                }
            } else {
                // First check-in ever
                newStreak = 1
            }
            
            transaction.updateData([
                "streak": newStreak,
                "lastCheckIn": Timestamp(date: now)
            ], forDocument: userRef)
            
            streak = newStreak
            return nil
        }) { _, error in
            if let error = error {
                print("Transaction failed: \(error)")
            } else {
                // Show success feedback
                hasCheckedInToday = true
                showConfetti = true
                showStreak = true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "line.horizontal.3")
                    Spacer()
                    VStack(spacing: 4) {
                        Image("FiTTTTLogoBlacked")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 140, height: 40)
                        Text("Accountability in Fitness")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    Spacer()
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.black)
                    }
                }
                .padding()
                .background(Color.white)
                .overlay(Rectangle().frame(height: 1).foregroundColor(.black), alignment: .bottom)

                // Middle ScrollView
                ScrollView {
                    VStack(spacing: 20) {
                        // Build Routine Section
                        VStack(spacing: 8) {
                            Text("Personalize Your Plans")
                                .font(.title2)
                                .bold()
                            Text("Make a goal and build your routine")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            NavigationLink(destination: LogWorkoutView()) {
                                Text("Build Routine")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .padding(.horizontal)
                            }
                            
                            // Check-in Button with morphing animation
                            Button(action: {
                                if !hasCheckedInToday {
                                    updateStreak()
                                }
                            }) {
                                Text(hasCheckedInToday ? "Checked In" : "Check In Today")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(hasCheckedInToday ? Color.gray : Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .padding(.horizontal)
                                    .opacity(hasCheckedInToday ? 0.7 : 1.0)
                            }
                            .disabled(hasCheckedInToday)
                            .padding(.top, 8)
                            .animation(.easeInOut(duration: 0.3), value: hasCheckedInToday)
                            
                            // Streak Message
                            if showStreak {
                                Text("🔥 Day \(streak) of your streak! Keep it up!")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                    .padding(.top, 16)
                                    .transition(.opacity.combined(with: .slide))
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .overlay(Rectangle().frame(height: 1).foregroundColor(.black), alignment: .bottom)
                        
                        // Rest of your existing content
                        // Top Picks Header
                        Text("Top Picks to Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        // Swipeable Video Scroll
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // First video
                                VStack(alignment: .leading) {
                                    YouTubeView(videoID: "j91YBwNnY0w")
                                        .frame(width: 300, height: 180)
                                        .cornerRadius(10)
                                    Text("Mindful Cooldown")
                                        .font(.subheadline)
                                        .bold()
                                    Text("5min • Chill Vibes")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 300)

                                // Second video
                                VStack(alignment: .leading) {
                                    YouTubeView(videoID: "M0uO8X3_tEA")
                                        .frame(width: 300, height: 180)
                                        .cornerRadius(10)
                                    Text("Hitt Workout")
                                        .font(.subheadline)
                                        .bold()
                                    Text("20min • Intense")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 300)

                                // Third video
                                VStack(alignment: .leading) {
                                    YouTubeView(videoID: "eMjyvIQbn9M")
                                        .frame(width: 300, height: 180)
                                        .cornerRadius(10)
                                    Text("Science Lift")
                                        .font(.subheadline)
                                        .bold()
                                    Text("17min • Chill Vibes")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 300)

                                // Fourth video
                                VStack(alignment: .leading) {
                                    YouTubeView(videoID: "jWhjDcp5fTY")
                                        .frame(width: 300, height: 180)
                                        .cornerRadius(10)
                                    Text("CBum Workout")
                                        .font(.subheadline)
                                        .bold()
                                    Text("17min • Intense")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 300)
                            }
                            .padding(.horizontal)
                        }

                        // Trending Courses Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trending Courses")
                                .font(.headline)
                                .padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    // Personal Trainer Course
                                    NavigationLink(destination: CourseDetailView(title: "Power Lifting")) {
                                        VStack(alignment: .leading) {
                                            Image("PowerLifting")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 180, height: 100)
                                                .clipped()
                                                .cornerRadius(10)
                                            Text("Fitness")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("Power Lifting")
                                                .font(.subheadline)
                                                .bold()
                                        }
                                        .frame(width: 180)
                                    }

                                    // Sport Nutrition Course
                                    NavigationLink(destination: CourseDetailView(title: "Pilates")) {
                                        VStack(alignment: .leading) {
                                            Image("Pilates")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 180, height: 100)
                                                .clipped()
                                                .cornerRadius(10)
                                            Text("Fitness")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("Pilates")
                                                .font(.subheadline)
                                                .bold()
                                        }
                                        .frame(width: 180)
                                    }
                                    
                                    NavigationLink(destination: CourseDetailView(title: "Calisthenics")) {
                                        VStack(alignment: .leading) {
                                            Image("Calisthenics")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 180, height: 100)
                                                .clipped()
                                                .cornerRadius(10)
                                            Text("Fitness")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("Calisthenics")
                                                .font(.subheadline)
                                                .bold()
                                        }
                                        .frame(width: 180)
                                    }
                                    NavigationLink(destination: CourseDetailView(title: "Running")) {
                                        VStack(alignment: .leading) {
                                            Image("Running")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 180, height: 100)
                                                .clipped()
                                                .cornerRadius(10)
                                            Text("Fitness")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("Running")
                                                .font(.subheadline)
                                                .bold()
                                        }
                                        .frame(width: 180)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                .overlay {
                    if showConfetti {
                        ConfettiView()
                            .onAppear {
                                // Remove confetti after animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showConfetti = false
                                }
                            }
                    }
                }

                // Bottom Tab Bar
                HStack {
                    Spacer()
                    Image(systemName: "house")
                        .font(.system(size: 32))
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
            .edgesIgnoringSafeArea(.bottom)
            .background(Color.white)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                checkIfUserCheckedInToday()
            }
        }
    }
}
