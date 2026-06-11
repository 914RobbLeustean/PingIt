import SwiftUI
import PhotosUI

struct RecapStorySheet: View {
    @Environment(PingRecapService.self) private var recapService
    @Environment(AuthService.self) private var authService
    @State private var viewModel: RecapStoryViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?

    init(recap: PingRecap) {
        self._viewModel = State(initialValue: RecapStoryViewModel(recap: recap))
    }

    var body: some View {
        VStack(spacing: 0) {
            RecapHeader(recap: viewModel.recap, photoCount: viewModel.visiblePhotos.count)
                .padding(.bottom, 14)

            if viewModel.isLoadingPhotos {
                Spacer()
                ProgressView()
                    .tint(Color.pingAccent)
                Spacer()
            } else if viewModel.visiblePhotos.isEmpty {
                RecapEmptyState(canSubmit: viewModel.canSubmitPhoto)
            } else {
                RecapPhotoCarousel(photos: viewModel.visiblePhotos)
            }

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color.pingHot)
                    .padding(.top, 10)
            }

            if viewModel.canSubmitPhoto {
                RecapAddPhotoButton(
                    isUploading: viewModel.isUploading,
                    selectedItem: $selectedPhotoItem
                )
                .padding(.top, 14)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .task {
            viewModel.configure(recapService: recapService, authService: authService)
            viewModel.startObservingPhotos()
        }
        .onDisappear {
            viewModel.stopObservingPhotos()
        }
        .onChange(of: selectedPhotoItem) {
            guard let item = selectedPhotoItem else { return }
            selectedPhotoItem = nil
            Task { await viewModel.handleSelectedPhoto(item: item) }
        }
    }
}

// MARK: - Header

private struct RecapHeader: View {
    let recap: PingRecap
    let photoCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("📸")
                    .font(.system(size: 13))
                Text("RECAP")
                    .font(.syne(.extraBold, size: 12))
                    .tracking(1.5)
                    .foregroundStyle(Color.pingAccent)
            }

            Text(titleText)
                .font(.syne(.extraBold, size: 20, relativeTo: .title3))
                .foregroundStyle(Color.pingTextPrimary)
                .lineSpacing(2)
                .lineLimit(2)

            Text(subtitleText)
                .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                .foregroundStyle(Color.pingTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var titleText: String {
        if let category = recap.category.flatMap(PingCategory.init(rawValue:)) {
            return "\(category.emoji)  \(recap.title)"
        }
        return recap.title
    }

    private var subtitleText: String {
        switch photoCount {
        case 0: "No photos yet from this ping."
        case 1: "1 photo from this ping"
        default: "\(photoCount) photos from this ping"
        }
    }
}

// MARK: - Carousel

private struct RecapPhotoCarousel: View {
    let photos: [PingRecapPhoto]

    var body: some View {
        TabView {
            ForEach(photos) { photo in
                if let url = URL(string: photo.imageUrl) {
                    RetryableAsyncImage(url: url, maxHeight: 360, cornerRadius: 16)
                        .padding(.horizontal, 2)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .automatic : .never))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(maxHeight: 400)
        .accessibilityLabel("Recap photos")
    }
}

// MARK: - Empty State

private struct RecapEmptyState: View {
    let canSubmit: Bool

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Text("📷")
                .font(.system(size: 40))
            Text("Nothing here yet.")
                .font(.syne(.bold, size: 18, relativeTo: .headline))
                .foregroundStyle(Color.pingTextPrimary)
            Text(canSubmit
                 ? "You were going — add the first photo."
                 : "People who RSVP'd can share photos for a little while after a ping ends.")
                .font(.dmSans(.regular, size: 14, relativeTo: .body))
                .foregroundStyle(Color.pingTextSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Add Photo Button

private struct RecapAddPhotoButton: View {
    let isUploading: Bool
    @Binding var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            HStack(spacing: 8) {
                if isUploading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 16))
                }
                Text(isUploading ? "UPLOADING..." : "ADD YOUR PHOTO")
                    .font(.syne(.extraBold, size: 15))
                    .tracking(-0.3)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.pingAccent)
            .clipShape(.capsule)
            .shadow(color: Color.pingAccent.opacity(0.35), radius: 12, y: 3)
        }
        .disabled(isUploading)
        .opacity(isUploading ? 0.7 : 1)
        .accessibilityLabel(isUploading ? "Uploading photo" : "Add your photo to this recap")
    }
}
