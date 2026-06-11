import SwiftUI

/// Ghost marker for an expired ping with a recap. Visually quieter than
/// active pins: semi-transparent, no pulse rings, no badges.
struct RecapAnnotationView: View {
    let recap: PingRecap
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("📸")
                .font(.system(size: 15))
                .frame(width: 34, height: 34)
                .background(Color.pingSurface.opacity(0.85))
                .clipShape(.circle)
                .overlay(
                    Circle().strokeBorder(Color.pingBorder, lineWidth: 1)
                )
                .opacity(0.65)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Recap of \(recap.title)")
        .accessibilityHint("Shows photos from this ended ping")
    }
}
