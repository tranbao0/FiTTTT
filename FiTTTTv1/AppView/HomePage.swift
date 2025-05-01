import SwiftUI
import WebKit

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

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Header
                HStack {
                    Image(systemName: "line.horizontal.3")
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Image("FiTTTTLogoBlacked")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 140, height: 40)
                        
                        Text("Accountability in Fitness")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    Image(systemName: "person.crop.circle")
                }
                .padding(.horizontal)
                .padding(.top)

                .padding()
                .background(Color.white)
                .overlay(Rectangle().frame(height: 3).foregroundColor(.black), alignment: .bottom)
                // 🌟 Middle content
                ScrollView {
                    VStack(spacing: 20) {
                        // Build Routine
                        VStack(spacing: 8) {
                            Text("Build Routine")
                                .font(.title2)
                                .bold()
                            Text("Pick your activities and set your schedule")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                // action here
                            }) {
                                Text("Log Workout")
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
                        .overlay(Rectangle().frame(height: 3).foregroundColor(.black), alignment: .bottom)

                        // Top Picks Header
                        Text("Top Picks to Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        // Example horizontal scroll
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading) {
                                    YouTubeView(videoID: "j91YBwNnY0w")
                                        .frame(width: 180, height: 120)
                                        .cornerRadius(10)

                                    Text("Mindful Cooldown")
                                        .font(.subheadline)
                                        .bold()
                                    Text("5min • Chill Vibes")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 180)
                            }
                            .padding(.horizontal)
                        }
                    }
                 .padding(.top, 10)
                }

                // Bottom Tab Bar
                HStack {
                    Spacer()
                    Image(systemName: "house")
                    Spacer()
                    Image(systemName: "dumbbell")
                    Spacer()
                    Image(systemName: "person.2")
                    Spacer()
                    Image(systemName: "figure.bench.press")
                    Spacer()
                }
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
            }
            .edgesIgnoringSafeArea(.bottom)
            .background(Color.white)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
