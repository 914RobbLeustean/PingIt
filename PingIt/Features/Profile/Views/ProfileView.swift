import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserService.self) private var userService
    @Environment(ImageStorageService.self) private var imageStorageService
    @Environment(PingService.self) private var pingService
    @State private var viewModel = ProfileViewModel()
    @FocusState private var isUsernameFocused: Bool

    @State private var showPhotoSourcePicker = false
    @State private var showLibrary = false
    @State private var showCamera = false
    @State private var showRemovePhotoDialog = false

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            Color.pingBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 24) {
                        ProfileAvatarBlock(
                            initial: viewModel.avatarInitial,
                            username: viewModel.user?.username ?? "",
                            email: viewModel.user?.email ?? "",
                            profileImageUrl: viewModel.user?.profileImageUrl,
                            isUploading: viewModel.isUploadingImage,
                            onEditTapped: { showPhotoSourcePicker = true }
                        )

                        ProfileStatsCard(
                            pingCount: viewModel.pingCount,
                            boostCount: viewModel.totalBoosts,
                            memberAge: viewModel.memberAge
                        )

                        ProfileInfoCard(
                            username: viewModel.user?.username ?? "",
                            email: viewModel.user?.email ?? "",
                            memberSince: viewModel.memberSinceFormatted,
                            isEditing: viewModel.isEditingUsername,
                            editedUsername: $viewModel.editedUsername,
                            isSaving: viewModel.isSaving,
                            errorMessage: viewModel.isEditingUsername ? viewModel.errorMessage : nil
                        )

                        if let successMessage = viewModel.successMessage {
                            Text(successMessage)
                                .font(.dmSans(.medium, size: 13, relativeTo: .footnote))
                                .foregroundStyle(Color.pingLive)
                                .transition(.opacity.combined(with: .blurReplace))
                        }
                    }
                    .animation(.easeInOut(duration: 0.35), value: viewModel.successMessage)
                    .padding(.top, 4)
                    .padding(.bottom, 90)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
            }

            photoSourceSheet

            PingItConfirmationDialog(isPresented: showRemovePhotoDialog, onDismiss: { showRemovePhotoDialog = false }) {
                DialogTitleBlock(
                    title: "Remove profile photo?",
                    message: "Your profile will show your initial instead."
                )
                DialogButtonRow {
                    Button("Cancel", action: { showRemovePhotoDialog = false })
                        .buttonStyle(DialogSecondaryButtonStyle())
                } trailing: {
                    Button("Remove", action: confirmRemovePhoto)
                        .buttonStyle(DialogDestructiveButtonStyle())
                }
            }
        }
        .photosPicker(isPresented: $showLibrary, selection: Bindable(viewModel).selectedPhotoItem, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView(onImageCaptured: handleCameraImage)
        }
        .task {
            viewModel.configure(
                authService: authService,
                userService: userService,
                imageStorageService: imageStorageService,
                pingService: pingService
            )
            await viewModel.loadProfile()
        }
        .onChange(of: viewModel.selectedPhotoItem) { _, newItem in
            if newItem != nil {
                Task { await viewModel.handleSelectedPhoto() }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Profile")
                .font(.syne(.extraBold, size: 30, relativeTo: .largeTitle))
                .tracking(-0.5)
                .foregroundStyle(Color.pingTextPrimary)

            Spacer()

            if viewModel.isEditingUsername {
                HStack(spacing: 12) {
                    Button("Cancel", action: cancelEditUsername)
                        .font(.dmSans(.medium, size: 15, relativeTo: .body))
                        .foregroundStyle(Color.pingTextSecondary)

                    Button("Save", action: handleSaveUsername)
                        .font(.dmSans(.semiBold, size: 15, relativeTo: .body))
                        .foregroundStyle(viewModel.canSaveUsername ? Color.pingAccent : Color.pingAccent.opacity(0.4))
                        .disabled(!viewModel.canSaveUsername)
                }
            } else {
                Button("Edit", systemImage: "pencil", action: { viewModel.beginEditingUsername() })
                    .labelStyle(.iconOnly)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.pingTextSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private var photoSourceSheet: some View {
        if showPhotoSourcePicker {
            ZStack(alignment: .bottom) {
                Button(action: { showPhotoSourcePicker = false }) {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                }
                .buttonStyle(.plain)

                PhotoSourcePicker(
                    hasExistingPhoto: viewModel.user?.profileImageUrl != nil,
                    onChooseLibrary: {
                        showPhotoSourcePicker = false
                        showLibrary = true
                    },
                    onTakePhoto: {
                        showPhotoSourcePicker = false
                        showCamera = true
                    },
                    onRemovePhoto: {
                        showPhotoSourcePicker = false
                        showRemovePhotoDialog = true
                    },
                    onCancel: { showPhotoSourcePicker = false }
                )
                .transition(.move(edge: .bottom))
            }
            .transition(.opacity)
            .animation(.easeOut(duration: 0.25), value: showPhotoSourcePicker)
        }
    }

    // MARK: - Actions

    private func handleSaveUsername() {
        isUsernameFocused = false
        Task { await viewModel.saveUsername() }
    }

    private func cancelEditUsername() {
        isUsernameFocused = false
        viewModel.cancelEditingUsername()
    }

    private func handleCameraImage(_ image: UIImage) {
        Task { await viewModel.handleCameraImage(image) }
    }

    private func confirmRemovePhoto() {
        showRemovePhotoDialog = false
        Task { await viewModel.removeProfilePicture() }
    }
}
