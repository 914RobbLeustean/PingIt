import SwiftUI

struct ProfileStatsCard: View {
    let pingCount: Int
    let boostCount: Int
    let memberAge: String

    var body: some View {
        HStack(spacing: 0) {
            StatColumn(value: "\(pingCount)", label: "PINGS")
            statDivider
            StatColumn(value: "\(boostCount)", label: "BOOSTS")
            statDivider
            StatColumn(value: memberAge, label: "MEMBER")
        }
        .background(Color.pingSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.pingBorder, lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: 20))
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pingCount) pings, \(boostCount) boosts, member for \(memberAge)")
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
