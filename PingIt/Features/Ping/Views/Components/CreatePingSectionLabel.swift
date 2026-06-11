import SwiftUI

struct CreatePingSectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.dmSans(.semiBold, size: 11, relativeTo: .caption2))
            .tracking(0.8)
            .foregroundStyle(Color.pingTextSecondary)
            .padding(.horizontal, 20)
    }
}
