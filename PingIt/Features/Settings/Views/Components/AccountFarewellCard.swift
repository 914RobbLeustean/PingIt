import SwiftUI

struct AccountFarewellCard: View {
    @State private var appeared = false
    @State private var tearDrop = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.pingAccent.opacity(0.25), .clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 64
                        )
                    )
                    .frame(width: 128, height: 128)

                SadFaceMark()
                    .frame(width: 88, height: 88)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .animation(.spring(response: 0.55, dampingFraction: 0.62), value: appeared)
            }

            VStack(spacing: 8) {
                Text("We're sad to see you go.")
                    .font(.syne(.extraBold, size: 22, relativeTo: .title2))
                    .foregroundStyle(Color.pingTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Your account is gone, your pings have faded.\nThanks for being part of PingIt.")
                    .font(.dmSans(.regular, size: 14, relativeTo: .footnote))
                    .foregroundStyle(Color.pingTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            appeared = true
        }
    }
}

private struct SadFaceMark: View {
    @State private var blink = false
    @State private var tearOffset: CGFloat = -6

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // Face
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.pingAccent, Color.pingAccent.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.pingAccent.opacity(0.4), radius: 18, y: 6)

                // Eyes
                HStack(spacing: s * 0.22) {
                    eye(size: s)
                    eye(size: s)
                }
                .offset(y: -s * 0.07)

                // Mouth (sad curve)
                SadMouthShape()
                    .stroke(Color.black.opacity(0.7), style: StrokeStyle(lineWidth: s * 0.05, lineCap: .round))
                    .frame(width: s * 0.42, height: s * 0.18)
                    .offset(y: s * 0.18)

                // Tear
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), Color.pingLive.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: s * 0.07, height: s * 0.14)
                    .offset(x: -s * 0.18, y: s * 0.04 + tearOffset)
                    .opacity(tearOffset > -3 ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.2).delay(0.3).repeatForever(autoreverses: false)) {
                            tearOffset = s * 0.35
                        }
                    }
            }
        }
    }

    private func eye(size: CGFloat) -> some View {
        Capsule()
            .fill(Color.black.opacity(0.78))
            .frame(width: size * 0.07, height: blink ? size * 0.02 : size * 0.13)
            .onAppear {
                Task { @MainActor in
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(2.8))
                        withAnimation(.easeInOut(duration: 0.1)) { blink = true }
                        try? await Task.sleep(for: .milliseconds(120))
                        withAnimation(.easeInOut(duration: 0.1)) { blink = false }
                    }
                }
            }
    }
}

private struct SadMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.4)
        )
        return p
    }
}
