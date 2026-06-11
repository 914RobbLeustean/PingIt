import SwiftUI

struct AuthScreenHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            AuthBackButton(action: onBack)
            Text(title)
                .font(.syne(.extraBold, size: 22, relativeTo: .title2))
                .foregroundStyle(Color.pingTextPrimary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}
