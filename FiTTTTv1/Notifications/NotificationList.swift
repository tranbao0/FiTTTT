// NotificationsList.swift
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct NotificationsList: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    
    var body: some View {
        NavigationStack {
            Group {
                if notificationManager.unreadNotifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No notifications")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(notificationManager.unreadNotifications) { notification in
                                NotificationRow(notification: notification)
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarItems(trailing: Button("Mark All Read") {
                notificationManager.markAllAsRead()
            })
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.type == .confront ? "exclamationmark.triangle.fill" : "bell.fill")
                .foregroundColor(notification.type == .confront ? .red : .yellow)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.fromUsername)
                    .font(.headline)
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(notification.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

// Preview
struct NotificationsList_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsList()
    }
}
