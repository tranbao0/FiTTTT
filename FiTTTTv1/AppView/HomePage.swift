import SwiftUI
import WebKit

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

// MARK: - Main Content View
struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                        Image(systemName: "line.horizontal.3")
                            .font(.system(size: 24))
                            .foregroundColor(.black)

                        Spacer()

                        NavigationLink(destination: LogWorkoutView()) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                        }
                    }

                    // 2) Center logo + title
                    VStack(spacing: 4) {
                        Image("FiTTTTLogoBlacked")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 140, height: 40)
                        Text("Accountability in Fitness")
                            .font(.subheadline)
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
                            Text("Build Routine")
                                .font(.title2)
                                .bold()
                            Text("Make a goal and build your routine")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Button(action: {
                                // TODO: Build plan action
                            }) {
                                Text("Make Goal")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(25)
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .overlay(Rectangle().frame(height: 1).foregroundColor(.black), alignment: .bottom)

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
                                    Text("20min • Moderate")
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
                        NavigationLink(destination: CalendarView()) {
                            Image(systemName: "calendar")
                                .font(.system(size: 24))
                        }
                    Spacer()
                    }
                .padding(.vertical, 12)
                .background(Color.black)
                .foregroundColor(.white)
                
            }
            .edgesIgnoringSafeArea(.bottom)
            .background(Color.white)
        }
    }


// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
