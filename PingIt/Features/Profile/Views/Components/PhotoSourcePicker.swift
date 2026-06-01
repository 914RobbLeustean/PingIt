import SwiftUI

struct PhotoSourcePicker: View {
    let hasExistingPhoto: Bool
    let onChooseLibrary: () -> Void
    let onTakePhoto: () -> Void
    let onRemovePhoto: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            handle

            Text("Profile Photo")
                .font(.syne(.extraBold, size: 22, relativeTo: .title3))
                .foregroundStyle(Color.pingTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                sourceRow(label: "Choose from Library", icon: "photo.on.rectangle", action: onChooseLibrary)
                SettingsRowDivider()
                if CameraPickerView.isCameraAvailable {
                    sourceRow(label: "Take Photo", icon: "camera", action: onTakePhoto)
                    if hasExistingPhoto {
                        SettingsRowDivider()
                    }
                }
                if hasExistingPhoto {
                    sourceRow(label: "Remove Photo", icon: "trash", color: .pingHot, action: onRemovePhoto)
                }
            }
            .background(Color.pingSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.pingBorder, lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: 20))
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            Button("Cancel", action: onCancel)
                .font(.dmSans(.semiBold, size: 15, relativeTo: .body))
                .foregroundStyle(Color.pingTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.pingSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.pingBorder, lineWidth: 1)
                )
                .clipShape(.rect(cornerRadius: 20))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(Color.pingBackground)
    }

    private var handle: some View {
        Capsule()
            .fill(Color.pingBorder)
            .frame(width: 36, height: 4)
            .padding(.top, 14)
            .padding(.bottom, 16)
    }

    private func sourceRow(label: String, icon: String, color: Color = .pingTextPrimary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(label)
                    .font(.dmSans(.medium, size: 15, relativeTo: .body))
                    .foregroundStyle(color)

                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(minHeight: 52)
            .contentShape(.rect)
        }
        .buttonStyle(SettingsRowButtonStyle())
    }
}

