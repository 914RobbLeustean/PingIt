import SwiftUI

/// Animated splash shown once per cold launch, layered above RootView.
///
/// Its first frame reproduces LaunchScreen.storyboard exactly — the amber
/// logo dot centered on pingBackground — so the static launch image hands
/// off without a visible seam. Radar rings then ripple outward, the
/// wordmark and tagline reveal beneath the dot (which never moves), and
/// the parent fades the whole overlay away when `onFinished` fires.
struct SplashView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showWordmark = false
    @State private var showTagline = false

    var body: some View {
        ZStack {
            Color.pingBackground

            if !reduceMotion {
                SplashRadarRings()
            }

            PingItLogoMark()

            VStack(spacing: 10) {
                Text("PINGIT")
                    .font(.syne(.extraBold, size: 34))
                    .tracking(-1)
                    .foregroundStyle(Color.pingTextPrimary)
                    .opacity(showWordmark ? 1 : 0)
                    .offset(y: showWordmark || reduceMotion ? 0 : 10)

                Text("The city is live. Feel it.")
                    .font(.dmSans(.regular, size: 14))
                    .foregroundStyle(Color.pingTextSecondary)
                    .opacity(showTagline ? 1 : 0)
            }
            .offset(y: 76)
        }
        // The storyboard centers the dot in the full screen; ignore safe
        // areas so this center lands on the same pixel and nothing jumps.
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("PingIt")
        .task { await run() }
    }

    private func run() async {
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.4)) {
                showWordmark = true
                showTagline = true
            }
            try? await Task.sleep(for: .seconds(1.1))
        } else {
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                showWordmark = true
            }
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeOut(duration: 0.5)) {
                showTagline = true
            }
            try? await Task.sleep(for: .milliseconds(1100))
        }
        onFinished()
    }
}

// MARK: - Radar Rings

/// Three staggered rings expanding from the logo dot, echoing the radar
/// motif used on the welcome screen and map annotations.
private struct SplashRadarRings: View {
    var body: some View {
        ZStack {
            SplashRing(delay: 0)
            SplashRing(delay: 0.6)
            SplashRing(delay: 1.2)
        }
    }
}

private struct SplashRing: View {
    let delay: Double
    @State private var expanded = false

    var body: some View {
        Circle()
            .strokeBorder(Color.pingAccent.opacity(0.55), lineWidth: 1.5)
            .frame(width: 18, height: 18)
            .scaleEffect(expanded ? 16 : 1)
            .opacity(expanded ? 0 : 0.8)
            .onAppear {
                // Single-shot: the splash only lives for ~one ring cycle, and
                // a repeatForever restart would pop a fresh bright ring in a
                // single frame mid-fade-out.
                withAnimation(.easeOut(duration: 2.4).delay(delay)) {
                    expanded = true
                }
            }
    }
}

#Preview {
    SplashView(onFinished: {})
}
