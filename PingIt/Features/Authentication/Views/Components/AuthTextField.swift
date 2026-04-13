import SwiftUI

enum ValidationState {
    case valid
    case invalid
    case checking
}

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var validationState: ValidationState?
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .never

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()

            if let state = validationState {
                validationIndicator(for: state)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
    }

    @ViewBuilder
    private func validationIndicator(for state: ValidationState) -> some View {
        switch state {
        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .invalid:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .checking:
            ProgressView()
                .controlSize(.small)
        }
    }
}
