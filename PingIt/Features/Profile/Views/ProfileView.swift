import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserService.self) private var userService
    @State private var viewModel = ProfileViewModel()
    @FocusState private var isUsernameFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile image — outside Form to avoid tap area issues
                    ProfileImageSection(
                        profileImageUrl: viewModel.user?.profileImageUrl,
                        isUploading: viewModel.isUploadingImage,
                        selectedPhotoItem: $viewModel.selectedPhotoItem,
                        onCameraImage: handleCameraImage,
                        onRemove: handleRemovePhoto
                    )
                    .padding(.vertical)

                    // Form for editable fields
                    Form {
                        Section("Username") {
                            TextField("Username", text: $viewModel.editedUsername)
                                .textContentType(.username)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .focused($isUsernameFocused)

                            if viewModel.hasUnsavedUsernameChanges, !viewModel.isUsernameValid {
                                Text("3-20 characters, letters, numbers, and underscores only")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }

                        Section("Account") {
                            LabeledContent("Email", value: viewModel.user?.email ?? "")

                            if let createdAt = viewModel.user?.createdAt {
                                LabeledContent("Member since", value: createdAt.formatted(date: .abbreviated, time: .omitted))
                            }
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Section {
                                Label(errorMessage, systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(.red)
                            }
                        }

                        if let successMessage = viewModel.successMessage {
                            Section {
                                Label(successMessage, systemImage: "checkmark.circle")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .scrollDisabled(true)
                    .frame(minHeight: 400)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: handleSaveUsername)
                        .disabled(viewModel.canSaveUsername == false)
                }
            }
            .task {
                viewModel.configure(authService: authService, userService: userService)
                await viewModel.loadProfile()
            }
            .onChange(of: viewModel.selectedPhotoItem) { _, newItem in
                if newItem != nil {
                    handlePhotoSelection()
                }
            }
        }
    }

    // MARK: - Actions

    private func handleSaveUsername() {
        isUsernameFocused = false
        Task {
            await viewModel.saveUsername()
        }
    }

    private func handlePhotoSelection() {
        Task {
            await viewModel.handleSelectedPhoto()
        }
    }

    private func handleCameraImage(_ image: UIImage) {
        Task {
            await viewModel.handleCameraImage(image)
        }
    }

    private func handleRemovePhoto() {
        Task {
            await viewModel.removeProfilePicture()
        }
    }
}
