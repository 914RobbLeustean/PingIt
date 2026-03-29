import SwiftUI

struct ChatPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Chat",
            systemImage: "bubble.left.and.bubble.right",
            description: Text("Join a ping to start chatting.")
        )
    }
}
