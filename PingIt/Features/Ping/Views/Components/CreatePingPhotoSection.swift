import SwiftUI

struct CreatePingPhotoSection: View {
    let selectedImageData: Data?
    let isProcessingImage: Bool
    var onRemove: () -> Void
    @Binding var showPhotoPicker: Bool
    @Binding var showCamera: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CreatePingSectionLabel(title: "Photo (optional)")

            if let imageData = selectedImageData,
               let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipShape(.rect(cornerRadius: 16))

                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.pingHot)
                            .clipShape(.circle)
                    }
                    .buttonStyle(.plain)
                    .offset(x: -10, y: 10)
                    .accessibilityLabel("Remove photo")
                }
                .padding(.horizontal, 20)
            } else if isProcessingImage {
                ProgressView()
                    .tint(Color.pingAccent)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .padding(.horizontal, 20)
            } else {
                photoAddButton
            }
        }
    }

    private var photoAddButton: some View {
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
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16))
                Text("Add a photo")
                    .font(.dmSans(.medium, size: 14, relativeTo: .body))
            }
            .foregroundStyle(Color.pingAccent.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.clear)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.pingAccent.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            )
        }
        .padding(.horizontal, 20)
    }
}
