import SwiftUI

struct ProfileInfoCard: View {
    let username: String
    let email: String
    let memberSince: String
    let isEditing: Bool
    @Binding var editedUsername: String
    let isSaving: Bool
    let errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            usernameRow
            SettingsRowDivider()
            infoRow(label: "Email", value: email)
            SettingsRowDivider()
            infoRow(label: "Member since", value: memberSince)
        }
        .background(Color.pingSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.pingBorder, lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: 20))
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var usernameRow: some View {
        HStack(spacing: 12) {
            Text("Username")
                .font(.dmSans(.regular, size: 14, relativeTo: .body))
                .foregroundStyle(Color.pingTextSecondary)

            Spacer(minLength: 0)

            if isEditing {
                TextField("Username", text: $editedUsername)
                    .font(.dmSans(.medium, size: 14, relativeTo: .body))
                    .foregroundStyle(Color.pingTextPrimary)
                    .multilineTextAlignment(.trailing)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disabled(isSaving)

                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color.pingAccent)
                }
            } else {
                Text("@\(username)")
                    .font(.dmSans(.medium, size: 14, relativeTo: .body))
                    .foregroundStyle(Color.pingTextPrimary)
            }
        }
        .padding(.horizontal, 18)
        .frame(minHeight: 52)

        if let errorMessage, isEditing {
            Text(errorMessage)
                .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                .foregroundStyle(Color.pingHot)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 18)
                .padding(.bottom, 8)
                .padding(.top, -4)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.dmSans(.regular, size: 14, relativeTo: .body))
                .foregroundStyle(Color.pingTextSecondary)

            Spacer(minLength: 0)

            Text(value)
                .font(.dmSans(.medium, size: 14, relativeTo: .body))
                .foregroundStyle(Color.pingTextPrimary)
        }
        .padding(.horizontal, 18)
        .frame(minHeight: 52)
    }
}
