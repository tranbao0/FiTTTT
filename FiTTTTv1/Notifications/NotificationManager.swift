import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var unreadNotifications: [AppNotification] = []
    @Published var hasUnreadNotifications: Bool = false
    @Published var showNotification: Bool = false
    @Published var currentNotification: AppNotification?
    
    private var listener: ListenerRegistration?
    
    private init() {}
    
    func startListening() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        listener = db.collection("users")
            .document(currentUserId)
            .collection("notifications")
            .whereField("read", isEqualTo: false)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening for notifications: \(error.localizedDescription)")
                    return
                }
                
                if let changes = snapshot?.documentChanges {
                    for change in changes {
                        if change.type == .added {
                            if let notification = AppNotification.fromDocument(change.document) {
                                // Show new notification
                                if !self.unreadNotifications.contains(where: { $0.id == notification.id }) {
                                    self.showNotification(notification)
                                }
                            }
                        }
                    }
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.unreadNotifications = documents.compactMap { doc in
                    AppNotification.fromDocument(doc)
                }
                
                self.hasUnreadNotifications = !self.unreadNotifications.isEmpty
            }
    }
    
    func stopListening() {
        listener?.remove()
    }
    
    func markAsRead(notificationId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users")
            .document(currentUserId)
            .collection("notifications")
            .document(notificationId)
            .updateData(["read": true])
    }
    
    func markAllAsRead() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        unreadNotifications.forEach { notification in
            let ref = db.collection("users")
                .document(currentUserId)
                .collection("notifications")
                .document(notification.id)
            
            batch.updateData(["read": true], forDocument: ref)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error marking all as read: \(error.localizedDescription)")
            }
        }
    }
    
    private func showNotification(_ notification: AppNotification) {
        self.currentNotification = notification
        self.showNotification = true
        
        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.currentNotification?.id == notification.id {
                self.showNotification = false
            }
        }
    }
}
