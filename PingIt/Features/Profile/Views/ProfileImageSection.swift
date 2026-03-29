import SwiftUI
import PhotosUI

struct ProfileImageSection: View {
    let profileImageUrl: String?
    let isUploading: Bool
    @Binding var selectedPhotoItem: PhotosPickerItem?
    var onCameraImage: (UIImage) -> Void
    var onRemove: () -> Void

    @State private var showOptions = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var showRemoveAlert = false

    var body: some View {
        VStack(spacing: 12) {
            profileImage
            editButton
        }
        .photosPicker(isPresented: $showLibrary, selection: $selectedPhotoItem, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView(onImageCaptured: handleCameraCapture)
        }
        .alert("Remove profile picture?", isPresented: $showRemoveAlert) {
            Button("Remove", role: .destructive, action: handleConfirmRemove)
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Subviews

    private var profileImage: some View {
        ZStack {
            if let urlString = profileImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 120, height: 120)
                .clipShape(.circle)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(.secondary)
            }

            if isUploading {
                ProgressView()
                    .frame(width: 120, height: 120)
                    .background(.ultraThinMaterial)
                    .clipShape(.circle)
            }
        }
    }

    private var editButton: some View {
        Menu("Edit Photo", systemImage: "pencil.circle") {
            Button("Choose from Library", systemImage: "photo.on.rectangle", action: handleLibraryTap)
            Button("Take Photo", systemImage: "camera", action: handleCameraTap)
            if profileImageUrl != nil {
                Divider()
                Button("Remove Photo", systemImage: "trash", role: .destructive, action: handleRemoveTap)
            }
        }
        .font(.subheadline)
    }

    // MARK: - Actions

    private func handleLibraryTap() {
        showLibrary = true
    }

    private func handleCameraTap() {
        showCamera = true
    }

    private func handleRemoveTap() {
        showRemoveAlert = true
    }

    private func handleConfirmRemove() {
        onRemove()
    }

    private func handleCameraCapture(_ image: UIImage) {
        onCameraImage(image)
    }
}
