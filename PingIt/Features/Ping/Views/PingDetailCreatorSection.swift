import SwiftUI

struct PingDetailCreatorSection: View {
    let username: String?
    let profileImageUrl: String?
    let countdownText: String

    var body: some View {
        HStack {
            if let urlString = profileImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                }
                .frame(width: 40, height: 40)
                .clipShape(.circle)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.secondary)
            }

            Text(username ?? "Loading...")
                .font(.headline)

            Spacer()

            Label(countdownText, systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.orange)
        }
        .accessibilityElement(children: .combine)
    }
}
