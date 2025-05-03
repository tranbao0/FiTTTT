import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct NotificationBadge: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell")
                .font(.system(size: 24))
            
            if notificationManager.hasUnreadNotifications {
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Text("\(notificationManager.unreadNotifications.count)")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                    )
                    .offset(x: 4, y: -4)
            }
        }
    }
}
