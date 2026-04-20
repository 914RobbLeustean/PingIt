import SwiftUI

struct PingClusterAnnotationView: View {
    let count: Int
    let containsHotPing: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(clusterGradient)
                .frame(width: 44, height: 44)
                .shadow(color: containsHotPing ? .red.opacity(0.4) : .orange.opacity(0.3), radius: 4)

            Text("\(count)")
                .font(.subheadline)
                .bold()
                .foregroundStyle(.white)
        }
        .accessibilityLabel("\(count) pings\(containsHotPing ? ", includes trending" : "")")
    }

    private var clusterGradient: AnyGradient {
        containsHotPing ? Color.red.gradient : Color.orange.gradient
    }
}
