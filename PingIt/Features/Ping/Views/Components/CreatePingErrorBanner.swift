import SwiftUI

struct CreatePingErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.pingHot)

            Text(message)
                .font(.dmSans(.medium, size: 13, relativeTo: .footnote))
                .foregroundStyle(Color.pingHot)
        }
        .padding(.horizontal, 20)
    }
}
