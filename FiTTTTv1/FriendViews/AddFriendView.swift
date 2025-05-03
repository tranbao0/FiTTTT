import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddFriendView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchQuery = ""
    @State private var searchResults: [Friend] = []
    @State private var allUsers: [Friend] = []  // Show all users initially
    @State private var isSearching = false
    @State private var isLoadingInitial = true  // For loading initial list
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var usersToDisplay: [Friend] {
        return searchResults.isEmpty && searchQuery.isEmpty ? allUsers : searchResults
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Add Friends and Requests buttons section
            HStack(spacing: 12) {
                // Add Friends button (current view)
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    Text("Add Friends")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black)
                .cornerRadius(25)
                
                // Requests button
                NavigationLink(destination: FriendRequestsView(requests: [])) {
                    HStack(spacing: 4) {
                        Text("Requests")
                            .font(.headline)
                            .foregroundColor(.black)
                        Circle()
                            .fill(Color.red)
                            .frame(width: 25, height: 25)
                            .overlay(Text("1").font(.caption).bold().foregroundColor(.white))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search by username", text: $searchQuery)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: searchQuery) { newValue in
                        if newValue.isEmpty {
                            // Clear search results and show all users
                            searchResults = []
                        } else {
                            // Perform search as user types
                            performSearch()
                        }
                    }
                
                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Results or Initial User List
            if isSearching || isLoadingInitial {
                ProgressView()
                    .padding()
            } else if usersToDisplay.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    if searchQuery.isEmpty {
                        Text("No users found")
                            .font(.headline)
                        Text("Check your database configuration")
                            .foregroundColor(.gray)
                    } else {
                        Text("No users found for '\(searchQuery)'")
                            .font(.headline)
                        Text("Try another username")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 50)
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(usersToDisplay) { user in
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
        .onAppear {
            loadAllUsers()
        }
    }
    
    // All your existing functions remain exactly the same
    private func loadAllUsers() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "You need to be logged in to see users"
            showingError = true
            isLoadingInitial = false
            return
        }
        
        isLoadingInitial = true
        let db = Firestore.firestore()
        
        db.collection("users")
            .limit(to: 20)  // Limit initial load
            .getDocuments { snapshot, error in
                isLoadingInitial = false
                
                if let error = error {
                    errorMessage = "Error loading users: \(error.localizedDescription)"
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
                    
                    if let friend = Friend.fromDocument(document) {
                        results.append(friend)
                    }
                }
                
                // Check friend status for all users
                if !results.isEmpty {
                    checkFriendStatus(for: results, currentUserId: currentUserId) { updatedResults in
                        allUsers = updatedResults
                    }
                } else {
                    allUsers = results
                }
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
        
        // Create a DispatchGroup to manage multiple queries
        let searchGroup = DispatchGroup()
        var allResults: [Friend] = []
        
        // Search with original case
        searchGroup.enter()
        searchByUsername(searchQuery, db: db, currentUserId: currentUserId) { results in
            allResults.append(contentsOf: results)
            searchGroup.leave()
        }
        
        // Search with lowercase (if different from original)
        if searchQuery != searchQuery.lowercased() {
            searchGroup.enter()
            searchByUsername(searchQuery.lowercased(), db: db, currentUserId: currentUserId) { results in
                allResults.append(contentsOf: results)
                searchGroup.leave()
            }
        }
        
        // Search with capitalized (if different from others)
        let capitalized = searchQuery.prefix(1).uppercased() + searchQuery.dropFirst().lowercased()
        if capitalized != searchQuery && capitalized != searchQuery.lowercased() {
            searchGroup.enter()
            searchByUsername(capitalized, db: db, currentUserId: currentUserId) { results in
                allResults.append(contentsOf: results)
                searchGroup.leave()
            }
        }
        
        // When all searches complete
        searchGroup.notify(queue: .main) {
            isSearching = false
            
            // Remove duplicates based on ID
            let uniqueResults = Array(Dictionary(grouping: allResults, by: { $0.id }).compactMapValues({ $0.first }))
                .map { $0.value }
            
            // Check friend status for all results
            if !uniqueResults.isEmpty {
                checkFriendStatus(for: uniqueResults, currentUserId: currentUserId) { updatedResults in
                    searchResults = updatedResults
                }
            } else {
                searchResults = []
            }
        }
    }

    // Helper function to search by username
    private func searchByUsername(_ query: String, db: Firestore, currentUserId: String, completion: @escaping ([Friend]) -> Void) {
        db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: query)
            .whereField("username", isLessThanOrEqualTo: query + "\u{f8ff}")
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Search error for '\(query)': \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                // Convert documents to Friend objects
                var results: [Friend] = []
                for document in documents {
                    // Skip current user
                    if document.documentID == currentUserId {
                        continue
                    }
                    
                    if let friend = Friend.fromDocument(document) {
                        results.append(friend)
                    }
                }
                
                completion(results)
            }
    }
    
    // Update checkFriendStatus to use completion handler
    private func checkFriendStatus(for results: [Friend], currentUserId: String, completion: @escaping ([Friend]) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").document(currentUserId).collection("friendRequests")
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Error loading friend data: \(error.localizedDescription)"
                    showingError = true
                    completion(results)
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
                
                // Update search results with friend status
                var updatedResults = results
                for i in 0..<updatedResults.count {
                    if let status = friendStatuses[updatedResults[i].id] {
                        updatedResults[i].status = status
                    }
                }
                
                completion(updatedResults)
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
        
        // Update the UI immediately (optimistic update)
        updateUserStatus(userId: user.id, newStatus: .pending)
        
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
                // Revert the status on error
                updateUserStatus(userId: user.id, newStatus: .none)
                errorMessage = "Error sending friend request: \(error.localizedDescription)"
                showingError = true
                return
            }
        }
    }
    
    private func acceptFriendRequest(from user: Friend) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "You need to be logged in to accept friend requests"
            showingError = true
            return
        }
        
        // Update the UI immediately (optimistic update)
        updateUserStatus(userId: user.id, newStatus: .friends)
        
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
                // Revert the status on error
                updateUserStatus(userId: user.id, newStatus: .requested)
                errorMessage = "Error accepting friend request: \(error.localizedDescription)"
                showingError = true
                return
            }
        }
    }
    
    // Helper function to update the status in both lists
    private func updateUserStatus(userId: String, newStatus: Friend.FriendStatus) {
        // Update in searchResults
        if let index = searchResults.firstIndex(where: { $0.id == userId }) {
            searchResults[index].status = newStatus
        }
        
        // Update in allUsers
        if let index = allUsers.firstIndex(where: { $0.id == userId }) {
            allUsers[index].status = newStatus
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
