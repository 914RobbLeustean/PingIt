import SwiftUI

struct WelcomeView: View {
    @Binding var path: [AuthRoute]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("PingIt")
                    .font(.largeTitle)
                    .bold()
                Text("Discover what's happening around you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                Button("Create Account") {
                    path.append(.register)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                Button("Sign In") {
                    path.append(.login)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}
