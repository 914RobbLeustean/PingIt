import SwiftUI

struct WelcomeView: View {
    @Binding var path: [AuthRoute]

    var body: some View {
        ZStack {
            Color.pingBackground
                .ignoresSafeArea()

            RadarBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 14) {
                    PingItWordmark()
                    Text("The city is live. Feel it.")
                        .font(.dmSans(.regular, size: 16, relativeTo: .body))
                        .foregroundStyle(Color.pingTextSecondary)
                        .lineSpacing(4)
                        .frame(maxWidth: 280, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)

                Spacer(minLength: 0)

                VStack(spacing: 12) {
                    Button("Create Account") {
                        path.append(.register)
                    }
                    .buttonStyle(PrimaryPillButtonStyle())

                    Button("Sign In") {
                        path.append(.login)
                    }
                    .buttonStyle(SecondaryPillButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
