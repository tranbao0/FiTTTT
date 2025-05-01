import SwiftUI

struct FriendsView: View {
    let topFriends: [Friend] = [
        Friend(rank: 1, name: "John", points: 6210, imageName: "John"),
        Friend(rank: 2, name: "Sophia", points: 3685, imageName: "sophia"),
        Friend(rank: 3, name: "Robert", points: 3559, imageName: "robert")
    ]
    
    let otherFriends: [Friend] = [
        Friend(rank: 4, name: "Dave", points: 3512, imageName: "dave"),
        Friend(rank: 5, name: "Dushan", points: 3012, imageName: "dushan"),
        Friend(rank: 6, name: "Sophia", points: 2655, imageName: "anaa"),
        Friend(rank: 7, name: "You", points: 1932, imageName: "you"),
        Friend(rank: 8, name: "Lisa", points: 1801, imageName: "lisa"),
        Friend(rank: 9, name: "Justin", points: 871, imageName: "justin")
    ]
    
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
                    Image(systemName: "person.crop.circle")
                }
                .padding(.horizontal)
                .padding(.top)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Search friend")
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                // Top 3 Circle Avatars
                HStack(spacing: 30) {
                    ForEach(topFriends.sorted { $0.rank < $1.rank }) { friend in
                        NavigationLink(destination: FriendDetailView(friend: friend)) {
                            VStack {
                                ZStack {
                                    Circle()
                                        .stroke(Color.black, lineWidth: friend.rank == 1 ? 3 : 1)
                                        .frame(width: 80, height: 80)
                                    Image(friend.imageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 70, height: 70)
                                        .clipShape(Circle())
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

                // Friend List
                List(otherFriends) { friend in
                    NavigationLink(destination: FriendDetailView(friend: friend)) {
                        HStack {
                            Text("\(friend.rank)")
                                .font(.headline)
                                .frame(width: 30)
                            Image(friend.imageName)
                                .resizable()
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                            Text(friend.name)
                                .font(friend.name == "You" ? .headline.italic() : .headline)
                            Spacer()
                            Text("\(friend.points) pts")
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)

                // Bottom Tab Bar
                HStack {
                    Spacer()
                    Image(systemName: "house")
                    Spacer()
                    Image(systemName: "dumbbell")
                    Spacer()
                    Image(systemName: "person.2")
                    Spacer()
                    Image(systemName: "figure.bench.press")
                    Spacer()
                }
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}
