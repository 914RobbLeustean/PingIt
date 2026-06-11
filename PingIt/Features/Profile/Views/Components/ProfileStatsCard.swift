import SwiftUI

struct ProfileStatsCard: View {
    struct Stat: Equatable {
        let value: String
        let label: String
    }

    let stats: [Stat]

    init(stats: [Stat]) {
        self.stats = stats
    }

    init(pingCount: Int, boostCount: Int, followerCount: Int) {
        self.stats = [
            Stat(value: "\(pingCount)", label: "PINGS"),
            Stat(value: "\(boostCount)", label: "BOOSTS"),
            Stat(value: "\(followerCount)", label: "FOLLOWERS"),
        ]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                if index > 0 {
                    statDivider
                }
                StatColumn(value: stat.value, label: stat.label)
            }
        }
        .background(Color.pingSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.pingBorder, lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: 20))
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stats.map { "\($0.value) \($0.label.lowercased())" }.joined(separator: ", "))
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.pingBorder)
            .frame(width: 1)
            .padding(.vertical, 8)
    }
}

private struct StatColumn: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.syne(.extraBold, size: 22, relativeTo: .title2))
                .tracking(-0.5)
                .foregroundStyle(Color.pingAccent)

            Text(label)
                .font(.dmSans(.regular, size: 11, relativeTo: .caption2))
                .tracking(0.5)
                .foregroundStyle(Color.pingTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}
