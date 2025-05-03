import SwiftUI

struct FriendDetailView: View {
    let friend: Friend  

    var moveProgress: Double { friend.name == "You" ? 0.85 : 0.45 }
    var exerciseProgress: Double { friend.name == "You" ? 0.6 : 0.3 }
    var standProgress: Double { friend.name == "You" ? 0.9 : 0.4 }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(friend.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(radius: 5)
                
                Text(friend.name)
                    .font(.largeTitle)
                    .bold()
                
                Text("Streak: \(friend.streak) days")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                HStack(spacing: 20) {
                    Label("Move", systemImage: "flame")
                        .foregroundColor(.red)
                    Label("Exercise", systemImage: "heart")
                        .foregroundColor(.green)
                    Label("Stand", systemImage: "figure.stand")
                        .foregroundColor(.blue)
                }
                .font(.caption)

                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent Activities")
                        .font(.headline)
                    if friend.name == "You" {
                        Text("• Ran 7km")
                        Text("• 4 workouts completed")
                        Text("• Gained 400 points")
                    } else {
                        Text("• Walked 2km")
                        Text("• 2 workouts completed")
                        Text("• Gained 150 points")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(friend.name)
    }
}


