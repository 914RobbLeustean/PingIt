import SwiftUI

struct AuthPasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    var contentType: UITextContentType? = .password
    var submitLabel: SubmitLabel = .next

    var body: some View {
        AuthInputField(
            placeholder: placeholder,
            text: $text,
            icon: "lock",
            isSecure: !isVisible,
            contentType: contentType,
            submitLabel: submitLabel
        ) {
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.pingTextSecondary)
                    .frame(width: 24, height: 24)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isVisible ? "Hide password" : "Show password")
        }
    }
}
