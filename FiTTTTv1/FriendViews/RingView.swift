import SwiftUI

struct RingView: View {
    var progress: Double
    var ringColor: Color
    var size: CGFloat
    var lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
        }
        .frame(width: size, height: size)
    }
}
