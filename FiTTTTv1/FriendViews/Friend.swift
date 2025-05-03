import Foundation
import FirebaseFirestore

struct Friend: Identifiable {
    let id: String
    let name: String
    let username: String
    let streak: Int  // Replace points with streak
    let imageName: String
    var status: FriendStatus = .none
    
    // For local display purposes
    var rank: Int = 0
    
    enum FriendStatus: String, Codable {
        case none
        case pending  // Request sent, waiting for approval
        case requested  // Request received, needs your approval
        case friends   // Approved friend
    }
    
    // For Firestore mapping
    static func fromDocument(_ document: DocumentSnapshot) -> Friend? {
        guard let data = document.data() else { return nil }
        
        return Friend(
            id: document.documentID,
            name: data["username"] as? String ?? "Unknown",
            username: data["username"] as? String ?? "Unknown",
            streak: data["streak"] as? Int ?? 0,  // Get streak instead of points
            imageName: "person", // Default image
            status: FriendStatus(rawValue: data["friendStatus"] as? String ?? "none") ?? .none
        )
    }
}
