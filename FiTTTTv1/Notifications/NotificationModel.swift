import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AppNotification: Identifiable {
    let id: String
    let message: String
    let timestamp: Date
    let read: Bool
    let fromUserId: String
    let fromUsername: String
    let type: NotificationType
    
    enum NotificationType: String {
        case remind = "remind"
        case confront = "confront"
        case general = "general"
    }
    
    static func fromDocument(_ document: DocumentSnapshot) -> AppNotification? {
        guard let data = document.data() else { return nil }
        
        return AppNotification(
            id: document.documentID,
            message: data["message"] as? String ?? "",
            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
            read: data["read"] as? Bool ?? false,
            fromUserId: data["fromUserId"] as? String ?? "",
            fromUsername: data["fromUsername"] as? String ?? "Unknown",
            type: NotificationType(rawValue: data["type"] as? String ?? "general") ?? .general
        )
    }
}
