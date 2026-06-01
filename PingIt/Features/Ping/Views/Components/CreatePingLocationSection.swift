import SwiftUI

struct CreatePingLocationSection: View {
    let locationDisplayText: String
    let hasLocation: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CreatePingSectionLabel(title: "Location")

            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: hasLocation ? "mappin.circle.fill" : "mappin.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.pingAccent)

                    Text(locationDisplayText)
                        .font(.dmSans(.medium, size: 14, relativeTo: .body))
                        .foregroundStyle(hasLocation ? Color.pingTextPrimary : .pingTextSecondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.pingTextSecondary)
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color.pingSurfaceElevated)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.pingBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .accessibilityHint("Opens location picker")
        }
    }
}
