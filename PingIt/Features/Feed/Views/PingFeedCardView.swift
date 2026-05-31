import SwiftUI

struct PingFeedCardView: View {
    let ping: Ping
    let creator: User?
    let distanceText: String?
    let isHot: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let creator, !creator.isPrivateProfile {
                    Text(creator.username)
                        .font(.subheadline)
                        .bold()
                } else {
                    Text("Anonymous")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isHot {
                    Label("Hot", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Text(ping.text)
                .font(.body)
                .lineLimit(3)

            if let imageUrl = ping.imageUrl, let url = URL(string: imageUrl) {
                RetryableAsyncImage(url: url, maxHeight: 150, cornerRadius: 8)
            }

            HStack(spacing: 12) {
                Label(ping.expiresAt.countdownDescription, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let distanceText {
                    Label(distanceText, systemImage: "location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label("\(ping.boostCount)", systemImage: "flame")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("\(ping.participantCount)", systemImage: "person.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .accessibilityElement(children: .combine)
    }
}
