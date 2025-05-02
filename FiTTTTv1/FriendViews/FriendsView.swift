import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FriendsView: View {
    @State private var friends: [Friend] = []
    @State private var pendingRequests: [Friend] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showingAddFriends = false
    
    var sortedFriends: [Friend] {
        return friends.sorted { $0.points > $1.points }
    }
    
    var topFriends: [Friend] {
        let ranked = sortedFriends.enumerated().map { index, friend in
            var rankedFriend = friend
            rankedFriend.rank = index + 1
            return rankedFriend
        }
        
        return Array(ranked.prefix(3))
    }
    
    var otherFriends: [Friend] {
        let ranked = sortedFriends.enumerated().map { index, friend in
            var rankedFriend = friend
            rankedFriend.rank = index + 1
            return rankedFriend
        }
        
        return Array(ranked.dropFirst(3))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "line.horizontal.3")
                    Spacer()
                    Text("Friends")
                        .font(.title)
                        .bold()
                    Spacer()
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle")
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Add Friends button and Search Bar
                HStack {
                    // Add Friend Button
                    Button(action: {
                        showingAddFriends = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Add Friends")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Pending Requests indicator
                    if !pendingRequests.isEmpty {
                        NavigationLink(destination: FriendRequestsView(requests: pendingRequests)) {
                            HStack {
                                Text("\(pendingRequests.count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                
                                Text("Requests")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if friends.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Friends Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Add friends to compare workouts and keep each other motivated!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            showingAddFriends = true
                        }) {
                            Text("Find Friends")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 200)
                                .padding()
                                .background(Color.black)
                                .cornerRadius(12)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.vertical, 60)
                } else {
                    // Top 3 Circle Avatars
                    if !topFriends.isEmpty {
                        HStack(spacing: 30) {
                            ForEach(topFriends) { friend in
                                NavigationLink(destination: FriendDetailView(friend: friend)) {
                                    VStack {
                                        ZStack {
                                            Circle()
                                                .stroke(Color.black, lineWidth: friend.rank == 1 ? 3 : 1)
                                                .frame(width: 80, height: 80)
                                            
                                            // Use actual profile image if available
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 70, height: 70)
                                                .clipShape(Circle())
                                                .foregroundColor(.gray)
                                        }
                                        Text(friend.name)
                                            .font(.subheadline)
                                            .bold()
                                        Text("\(friend.points) pts")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Circle()
                                            .foregroundColor(.green)
                                            .overlay(Text("\(friend.rank)").foregroundColor(.black).bold())
                                            .frame(width: 24, height: 24)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }

                    // Friend List
                    List {
                        ForEach(otherFriends) { friend in
                            NavigationLink(destination: FriendDetailView(friend: friend)) {
                                HStack {
                                    Text("\(friend.rank)")
                                        .font(.headline)
                                        .frame(width: 30)
                                    
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                        .foregroundColor(.gray)
                                    
                                    Text(friend.name)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text("\(friend.points) pts")
                                        .fontWeight(.semibold)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .listStyle(.plain)
                }

                // Bottom Tab Bar
                HStack {
                    Spacer()
                    NavigationLink(destination: ContentView()) {
                        Image(systemName: "house")
                            .font(.system(size: 24))
                    }
                    Spacer()
                    NavigationLink(destination: LogWorkoutView()) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 24))
                    }
                    Spacer()
                    Image(systemName: "person.2")
                        .font(.system(size: 32))
                    Spacer()
                    NavigationLink(destination: CalendarView()) {
                        Image(systemName: "calendar")
                            .font(.system(size: 24))
                    }
                    Spacer()
                }
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                loadFriends()
            }
            .sheet(isPresented: $showingAddFriends) {
                AddFriendView()
            }
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func loadFriends() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "You need to be logged in to view friends"
            showingError = true
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        
        // Get all friend requests
        db.collection("users").document(currentUserId).collection("friendRequests")
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Error loading friends: \(error.localizedDescription)"
                    showingError = true
                    isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    isLoading = false
                    return
                }
                
                // Filter for accepted friends and pending requests
                var acceptedFriendIds: [String] = []
                var pendingRequestIds: [String] = []
                
                for document in documents {
                    if let status = document.data()["status"] as? String {
                        if status == Friend.FriendStatus.friends.rawValue {
                            acceptedFriendIds.append(document.documentID)
                        } else if status == Friend.FriendStatus.requested.rawValue {
                            pendingRequestIds.append(document.documentID)
                        }
                    }
                }
                
                // Load friend details
                var loadedFriends: [Friend] = []
                var loadedRequests: [Friend] = []
                let group = DispatchGroup()
                
                // Load accepted friends
                for friendId in acceptedFriendIds {
                    group.enter()
                    db.collection("users").document(friendId).getDocument { docSnapshot, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("Error loading friend data: \(error.localizedDescription)")
                            return
                        }
                        
                        if let docSnapshot = docSnapshot, docSnapshot.exists,
                           var friend = Friend.fromDocument(docSnapshot) {
                            friend.status = .friends
                            loadedFriends.append(friend)
                        }
                    }
                }
                
                // Load pending requests
                for requestId in pendingRequestIds {
                    group.enter()
                    db.collection("users").document(requestId).getDocument { docSnapshot, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("Error loading request data: \(error.localizedDescription)")
                            return
                        }
                        
                        if let docSnapshot = docSnapshot, docSnapshot.exists,
                           var friend = Friend.fromDocument(docSnapshot) {
                            friend.status = .requested
                            loadedRequests.append(friend)
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    self.friends = loadedFriends
                    self.pendingRequests = loadedRequests
                    self.isLoading = false
                }
            }
    }
}
