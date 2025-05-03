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
    @State private var currentUser: Friend?

    var sortedFriends: [Friend] {
        var allFriends = friends
        if let currentUser = currentUser {
            allFriends.append(currentUser)
        }
        return allFriends.sorted { $0.streak > $1.streak }
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
        VStack(spacing: 0) {
            AppHeaderView()

            HStack {
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

                NavigationLink(destination: FriendRequestsView(requests: pendingRequests)) {
                    HStack {
                        if !pendingRequests.isEmpty {
                            Text("\(pendingRequests.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.red)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.2.wave.2")
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                        }
                        Text("Requests")
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            ScrollView {
                if isLoading {
                    ProgressView()
                        .padding(.top, 60)
                } else if friends.isEmpty {
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
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 0) {
                        if !topFriends.isEmpty {
                            HStack(spacing: 30) {
                                let reorderedTopFriends = reorderTopThree(topFriends)

                                ForEach(reorderedTopFriends, id: \.id) { friend in
                                    NavigationLink(destination: friend.id == Auth.auth().currentUser?.uid ? AnyView(ProfileView()) : AnyView(FriendDetailView(friend: friend))) {
                                        VStack {
                                            ZStack {
                                                Circle()
                                                    .stroke(Color.black, lineWidth: friend.rank == 1 ? 3 : 1)
                                                    .frame(width: 80, height: 80)
                                                Image(systemName: "person.circle.fill")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 70, height: 70)
                                                    .clipShape(Circle())
                                                    .foregroundColor(.gray)
                                            }
                                            Text(friend.id == Auth.auth().currentUser?.uid ? "You" : friend.name)
                                                .font(.subheadline)
                                                .bold()
                                                .italic(friend.id == Auth.auth().currentUser?.uid)
                                                .foregroundColor(.black)
                                            Text("Streak: \(friend.streak)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Circle()
                                                .foregroundColor(.green)
                                                .overlay(Text("\(friend.rank)").foregroundColor(.black).bold())
                                                .frame(width: 24, height: 24)
                                        }
                                        .padding(8)
                                        .background(
                                            Circle()
                                                .fill(friend.streak == 0 ? Color.red.opacity(0.1) : Color.clear)
                                                .frame(width: 100, height: 100)
                                        )
                                    }
                                }
                            }
                            .padding(.vertical)
                        }

                        VStack(spacing: 0) {
                            ForEach(otherFriends) { friend in
                                NavigationLink(destination: friend.id == Auth.auth().currentUser?.uid ? AnyView(ProfileView()) : AnyView(FriendDetailView(friend: friend))) {
                                    HStack {
                                        Text("\(friend.rank)")
                                            .font(.headline)
                                            .frame(width: 30)
                                            .foregroundColor(.black)

                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .clipShape(Circle())
                                            .foregroundColor(.gray)

                                        Text(friend.id == Auth.auth().currentUser?.uid ? "You" : friend.name)
                                            .font(.headline)
                                            .italic(friend.id == Auth.auth().currentUser?.uid)
                                            .foregroundColor(.black)

                                        Spacer()

                                        Text("Streak: \(friend.streak)")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(friend.streak == 0 ? Color.red.opacity(0.1) : Color.white)  // Add red tinge here
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 80) // prevent bottom bar clipping
                    }
                }
            }

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
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadFriends()
        }
        .sheet(isPresented: $showingAddFriends) {
            AddFriendView()
        }
        .alert(isPresented: $showingError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    func reorderTopThree(_ friends: [Friend]) -> [Friend] {
        guard friends.count >= 3 else { return friends }
        return [friends[1], friends[0], friends[2]]
    }
    
        func loadFriends() {
            guard let currentUserId = Auth.auth().currentUser?.uid else {
                errorMessage = "You need to be logged in to view friends"
                showingError = true
                isLoading = false
                return
            }
                
                let db = Firestore.firestore()
                
                // Create a dispatch group to handle all async operations
                let loadingGroup = DispatchGroup()
                
                // Load current user data
                loadingGroup.enter()
                db.collection("users").document(currentUserId).getDocument { docSnapshot, error in
                    defer { loadingGroup.leave() }
                    
                    if let error = error {
                        print("Error loading current user: \(error.localizedDescription)")
                    }
                    
                    if let docSnapshot = docSnapshot, docSnapshot.exists,
                       var user = Friend.fromDocument(docSnapshot) {
                        user.status = .friends
                        self.currentUser = user
                    }
                }
                
                // Get all friend requests
                loadingGroup.enter()
                db.collection("users").document(currentUserId).collection("friendRequests")
                    .getDocuments { snapshot, error in
                        if let error = error {
                            errorMessage = "Error loading friends: \(error.localizedDescription)"
                            showingError = true
                            loadingGroup.leave()
                            return
                        }
                        
                        guard let documents = snapshot?.documents else {
                            loadingGroup.leave()
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
                            loadingGroup.leave()
                        }
                    }
                
                // When all loading is complete
                loadingGroup.notify(queue: .main) {
                    self.isLoading = false
                }
            }
}
