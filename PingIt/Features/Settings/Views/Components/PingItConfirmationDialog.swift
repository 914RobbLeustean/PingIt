import SwiftUI

struct PingItConfirmationDialog<Content: View>: View {
    let isPresented: Bool
    let onDismiss: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture(perform: onDismiss)

                VStack(spacing: 0) {
                    content()
                }
                .background(Color.pingSurfaceElevated)
                .clipShape(.rect(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.pingBorder, lineWidth: 1)
                )
                .padding(.horizontal, 32)
                .shadow(color: .black.opacity(0.4), radius: 24, y: 8)
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isPresented)
    }
}

struct DialogTitleBlock: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.syne(.extraBold, size: 20, relativeTo: .title3))
                .foregroundStyle(Color.pingTextPrimary)

            Text(message)
                .font(.dmSans(.regular, size: 14, relativeTo: .footnote))
                .foregroundStyle(Color.pingTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }
}

struct DialogButtonRow<Leading: View, Trailing: View>: View {
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 10) {
            leading()
            trailing()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

struct DialogSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.syne(.bold, size: 15))
            .tracking(-0.2)
            .foregroundStyle(Color.pingTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.pingSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color.pingBorder, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct DialogDestructiveButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.syne(.bold, size: 15))
            .tracking(-0.2)
            .foregroundStyle(isEnabled ? Color.white : Color.pingTextSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isEnabled ? Color.pingHot : Color.pingSurfaceElevated)
            )
            .shadow(
                color: isEnabled ? Color.pingHot.opacity(0.35) : .clear,
                radius: 12, y: 0
            )
            .opacity(isLoading ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed && isEnabled ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}
