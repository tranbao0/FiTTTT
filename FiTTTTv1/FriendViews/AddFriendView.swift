import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddFriendView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchQuery = ""
    @State private var searchResults: [Friend] = []
    @State private var isSearching = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.title3)
                }
                
                Spacer()
                
                Text("Add Friends")
                    .font(.title2)
                    .bold()
                
                Spacer()
            }
            .padding()
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search by username", text: $searchQuery)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    performSearch()
                }) {
                    Text("Search")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Results
            if isSearching {
                ProgressView()
                    .padding()
            } else if searchResults.isEmpty && !searchQuery.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No users found")
                        .font(.headline)
                    Text("Try another username")
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(searchResults) { user in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.headline)
                                Text(user.username)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                sendFriendRequest(to: user)
                            }) {
                                switch user.status {
                                case .none:
                                    Text("Add")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.black)
                                        .cornerRadius(8)
                                case .pending:
                                    Text("Pending")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gray)
                                        .cornerRadius(8)
                                case .requested:
                                    Text("Accept")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                case .friends:
                                    Text("Friends")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                            }
                            .disabled(user.status == .pending || user.status == .friends)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
            
            Spacer()
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "You need to be logged in to search for friends"
            showingError = true
            return
        }
        
        isSearching = true
        searchResults = []
        
        let db = Firestore.firestore()
        
        // First, get current user's friend requests for reference
        db.collection("users").document(currentUserId).collection("friendRequests")
            .getDocuments { snapshot, error in
                if let error = error {
                    isSearching = false
                    errorMessage = "Error loading friend data: \(error.localizedDescription)"
                    showingError = true
                    return
                }
                
                // Create a dictionary to track friend request statuses
                var friendStatuses: [String: Friend.FriendStatus] = [:]
                
                if let documents = snapshot?.documents {
                    for document in documents {
                        if let status = document.data()["status"] as? String,
                           let friendStatus = Friend.FriendStatus(rawValue: status) {
                            friendStatuses[document.documentID] = friendStatus
                        }
                    }
                }
                
                // Now search for users by username
                db.collection("users")
                    .whereField("username", isGreaterThanOrEqualTo: searchQuery)
                    .whereField("username", isLessThanOrEqualTo: searchQuery + "\u{f8ff}")
                    .limit(to: 10)
                    .getDocuments { snapshot, error in
                        isSearching = false
                        
                        if let error = error {
                            errorMessage = "Error searching: \(error.localizedDescription)"
                            showingError = true
                            return
                        }
                        
                        guard let documents = snapshot?.documents else {
                            return
                        }
                        
                        // Convert documents to Friend objects
                        var results: [Friend] = []
                        for document in documents {
                            // Skip current user
                            if document.documentID == currentUserId {
                                continue
                            }
                            
                            if var friend = Friend.fromDocument(document) {
                                // Apply friend status if we have one
                                if let status = friendStatuses[document.documentID] {
                                    friend.status = status
                                }
                                results.append(friend)
                            }
                        }
                        
                        searchResults = results
                    }
            }
    }
    
    private func sendFriendRequest(to user: Friend) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "You need to be logged in to add friends"
            showingError = true
            return
        }
        
        let db = Firestore.firestore()
        
        // If this is an incoming request, accept it
        if user.status == .requested {
            acceptFriendRequest(from: user)
            return
        }
        
        // Otherwise, send a new request
        let batch = db.batch()
        
        // Create reference to outgoing request
        let outgoingRef = db.collection("users").document(currentUserId)
            .collection("friendRequests").document(user.id)
        
        // Create reference to incoming request
        let incomingRef = db.collection("users").document(user.id)
            .collection("friendRequests").document(currentUserId)
        
        // Set data for both references
        let outgoingData: [String: Any] = [
            "status": Friend.FriendStatus.pending.rawValue,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        let incomingData: [String: Any] = [
            "status": Friend.FriendStatus.requested.rawValue,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        batch.setData(outgoingData, forDocument: outgoingRef)
        batch.setData(incomingData, forDocument: incomingRef)
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                errorMessage = "Error sending friend request: \(error.localizedDescription)"
                showingError = true
                return
            }
            
            // Update UI to show pending status
            if let index = searchResults.firstIndex(where: { $0.id == user.id }) {
                searchResults[index].status = .pending
            }
        }
    }
    
    private func acceptFriendRequest(from user: Friend) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "You need to be logged in to accept friend requests"
            showingError = true
            return
        }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Update both users' friend request status
        let incomingRef = db.collection("users").document(currentUserId)
            .collection("friendRequests").document(user.id)
        
        let outgoingRef = db.collection("users").document(user.id)
            .collection("friendRequests").document(currentUserId)
        
        let friendStatus = Friend.FriendStatus.friends.rawValue
        
        batch.updateData(["status": friendStatus], forDocument: incomingRef)
        batch.updateData(["status": friendStatus], forDocument: outgoingRef)
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                errorMessage = "Error accepting friend request: \(error.localizedDescription)"
                showingError = true
                return
            }
            
            // Update UI to show friends status
            if let index = searchResults.firstIndex(where: { $0.id == user.id }) {
                searchResults[index].status = .friends
            }
        }
    }
}

struct FriendRequestsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var requests: [Friend]
    @State private var processingIds: Set<String> = []
    @State private var errorMessage = ""
    @State private var showingError = false
    
    init(requests: [Friend]) {
        _requests = State(initialValue: requests)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.title3)
                }
                
                Spacer()
                
                Text("Friend Requests")
                    .font(.title2)
                    .bold()
                
                Spacer()
            }
            .padding()
            
            if requests.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No pending friend requests")
                        .font(.headline)
                }
                .padding(.top, 100)
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(requests) { request in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading) {
                                Text(request.name)
                                    .font(.headline)
                                Text(request.username)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                // Reject button
                                Button(action: {
                                    rejectRequest(from: request)
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                }
                                
                                // Accept button
                                Button(action: {
                                    acceptRequest(from: request)
                                }) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.green)
                                        .clipShape(Circle())
                                }
                            }
                            .opacity(processingIds.contains(request.id) ? 0.5 : 1.0)
                            .disabled(processingIds.contains(request.id))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
            
            Spacer()
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func acceptRequest(from friend: Friend) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "You need to be logged in to accept friend requests"
            showingError = true
            return
        }
        
        processingIds.insert(friend.id)
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Update both users' friend request status
        let incomingRef = db.collection("users").document(currentUserId)
            .collection("friendRequests").document(friend.id)
        
        let outgoingRef = db.collection("users").document(friend.id)
            .collection("friendRequests").document(currentUserId)
        
        let friendStatus = Friend.FriendStatus.friends.rawValue
        
        batch.updateData(["status": friendStatus], forDocument: incomingRef)
        batch.updateData(["status": friendStatus], forDocument: outgoingRef)
        
        // Commit the batch
        batch.commit { error in
            processingIds.remove(friend.id)
            
            if let error = error {
                errorMessage = "Error accepting friend request: \(error.localizedDescription)"
                showingError = true
                return
            }
            
            // Remove from requests list
            if let index = requests.firstIndex(where: { $0.id == friend.id }) {
                requests.remove(at: index)
            }
        }
    }
    
    private func rejectRequest(from friend: Friend) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "You need to be logged in to reject friend requests"
            showingError = true
            return
        }
        
        processingIds.insert(friend.id)
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Delete both friend request records
        let incomingRef = db.collection("users").document(currentUserId)
            .collection("friendRequests").document(friend.id)
        
        let outgoingRef = db.collection("users").document(friend.id)
            .collection("friendRequests").document(currentUserId)
        
        batch.deleteDocument(incomingRef)
        batch.deleteDocument(outgoingRef)
        
        // Commit the batch
        batch.commit { error in
            processingIds.remove(friend.id)
            
            if let error = error {
                errorMessage = "Error rejecting friend request: \(error.localizedDescription)"
                showingError = true
                return
            }
            
            // Remove from requests list
            if let index = requests.firstIndex(where: { $0.id == friend.id }) {
                requests.remove(at: index)
            }
        }
    }
}
