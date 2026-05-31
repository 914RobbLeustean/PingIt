import SwiftUI
import PhotosUI

struct PingPhotoSectionView: View {
    let selectedImageData: Data?
    let isProcessingImage: Bool
    var onRemove: () -> Void
    @Binding var showPhotoPicker: Bool
    @Binding var showCamera: Bool

    var body: some View {
        Section("Photo (optional)") {
            if let imageData = selectedImageData,
               let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .clipped()
                        .clipShape(.rect(cornerRadius: 8))
                        .contentShape(.rect)

                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .red)
                            .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .accessibilityLabel("Remove photo")
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            }

            if isProcessingImage {
                ProgressView("Processing image…")
            }

            Menu {
                Button("Choose from Library", systemImage: "photo.on.rectangle") {
                    showPhotoPicker = true
                }
                if CameraPickerView.isCameraAvailable {
                    Button("Take Photo", systemImage: "camera") {
                        showCamera = true
                    }
                }
            } label: {
                Label(
                    selectedImageData != nil ? "Change Photo" : "Add Photo",
                    systemImage: "photo"
                )
            }
        }
    }
}
