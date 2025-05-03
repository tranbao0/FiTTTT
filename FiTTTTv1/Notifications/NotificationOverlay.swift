import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct NotificationOverlay: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    
    var body: some View {
        if notificationManager.showNotification, let notification = notificationManager.currentNotification {
            VStack {
                HStack {
                    if notification.type == .confront {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    } else if notification.type == .remind {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.yellow)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(notification.fromUsername)
                            .font(.headline)
                        Text(notification.message)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        notificationManager.showNotification = false
                        notificationManager.markAsRead(notificationId: notification.id)
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.horizontal)
                
                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(), value: notificationManager.showNotification)
        }
    }
}
