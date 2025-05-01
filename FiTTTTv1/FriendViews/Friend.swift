
import Foundation

struct Friend: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let points: Int
    let imageName: String
}
