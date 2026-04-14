import SwiftUI

struct AuthSecureField: View {
    let title: String
    @Binding var text: String
    @Binding var isVisible: Bool
    var textContentType: UITextContentType?

    var body: some View {
        HStack {
            Image(systemName: "lock")
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Group {
                if isVisible {
                    TextField(title, text: $text)
                        .textContentType(textContentType)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } else {
                    SecureField(title, text: $text)
                        .textContentType(textContentType)
                }
            }

            Button(isVisible ? "Hide password" : "Show password", systemImage: isVisible ? "eye.slash" : "eye") {
                isVisible.toggle()
            }
            .labelStyle(.iconOnly)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
    }
}
