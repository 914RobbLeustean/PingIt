import SwiftUI

/// Custom input field styled to match the PingIt prototype.
/// - 52pt height, 14pt corner radius, surface-elevated fill, hairline border.
/// - Leading SF Symbol icon, optional trailing accessory (e.g. password eye toggle).
struct AuthInputField<Trailing: View>: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .never
    var submitLabel: SubmitLabel = .next
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.pingTextSecondary)
                .frame(width: 18, height: 18)

            Group {
                if isSecure {
                    SecureField(
                        "",
                        text: $text,
                        prompt: Text(placeholder).foregroundStyle(Color.pingTextSecondary)
                    )
                } else {
                    TextField(
                        "",
                        text: $text,
                        prompt: Text(placeholder).foregroundStyle(Color.pingTextSecondary)
                    )
                }
            }
            .font(.dmSans(.regular, size: 15, relativeTo: .body))
            .foregroundStyle(Color.pingTextPrimary)
            .tint(Color.pingAccent)
            .keyboardType(keyboardType)
            .textContentType(contentType)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled()
            .submitLabel(submitLabel)

            trailing()
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.pingSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.pingBorder, lineWidth: 1)
        )
    }
}

extension AuthInputField where Trailing == EmptyView {
    init(
        placeholder: String,
        text: Binding<String>,
        icon: String,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        contentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .never,
        submitLabel: SubmitLabel = .next
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.contentType = contentType
        self.autocapitalization = autocapitalization
        self.submitLabel = submitLabel
        self.trailing = { EmptyView() }
    }
}
