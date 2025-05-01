import SwiftUI

struct OnboardingView: View {
    // Track login state to pass into LoginScreen
    @State private var isLoggedIn = false
    // Your image asset names
    private let images = ["image1", "image2", "image3", "image4"]
    @State private var currentIndex = 0
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Fullscreen black background
            Color.black
                .ignoresSafeArea()

            // Top curved section
            VStack(spacing: 0) {
                ZStack {
                    Color.black
                    Circle()
                        .fill(Color.white)
                        .frame(width: 1000, height: 500)
                        .offset(y: 450)
                }
                .frame(height: 550)
                Spacer()
            }

            // Main content
            VStack {
                // Logo & subtitle
                VStack(spacing: 8) {
                    Image("FiTTTTLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 30)
                    
                    Text("Accountability in Fitness")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .padding(.top, 40)

                Spacer().frame(height: 80)

                // Draggable carousel
                ZStack {
                    ForEach(images.indices.reversed(), id: \.self) { index in
                        let baseOffset = CGFloat(index - currentIndex) * 20
                        let xOffset = index == currentIndex ? baseOffset + dragOffset : baseOffset
                        OnboardingCard(imageName: images[index])
                            .offset(x: xOffset)
                            .scaleEffect(index == currentIndex ? 1 : 0.9)
                            .opacity(index < currentIndex ? 0 : 1)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentIndex)
                    }
                }
                .frame(height: 400)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in state = value.translation.width }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if value.translation.width < -threshold {
                                currentIndex = min(currentIndex + 1, images.count - 1)
                            } else if value.translation.width > threshold {
                                currentIndex = max(currentIndex - 1, 0)
                            }
                        }
                )

                // Page controls
                HStack(spacing: 16) {
                    Button(action: prev) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    ForEach(images.indices, id: \.self) { i in
                        Circle()
                            .fill(i == currentIndex ? Color.black : Color.gray.opacity(0.5))
                            .frame(width: 12, height: 12)
                    }
                    Button(action: next) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                }
                .padding(.top, 11)

                Spacer()

                // Register ⇒ SignUpView
                NavigationLink(destination: SignUpView()) {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.black)
                        .cornerRadius(25)
                }
                .padding(.top, 24)

                // Log In ⇒ LoginScreen with binding
                NavigationLink(destination: LoginScreen(isLoggedIn: $isLoggedIn)) {
                    Text("Log In")
                        .font(.body)
                        .underline()
                        .foregroundColor(.black)
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func next() {
        withAnimation { currentIndex = min(currentIndex + 1, images.count - 1) }
    }

    private func prev() {
        withAnimation { currentIndex = max(currentIndex - 1, 0) }
    }
}

struct OnboardingCard: View {
    let imageName: String
    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 320, height: 400)
            .cornerRadius(20)
            .shadow(radius: 5)
            .clipped()
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OnboardingView()
        }
        .previewDevice("iPhone 16")
    }
}
