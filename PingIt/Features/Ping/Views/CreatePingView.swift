import SwiftUI
import CoreLocation
import PhotosUI

struct CreatePingView: View {
    @Environment(AuthService.self) private var authService
    @Environment(PingService.self) private var pingService
    @Environment(ChatService.self) private var chatService
    @Environment(LocationService.self) private var locationService
    @Environment(ContentModerationService.self) private var contentModerationService
    @Environment(RateLimitService.self) private var rateLimitService
    @Environment(AnalyticsService.self) private var analyticsService
    @Environment(\.dismiss) private var dismiss
    @Binding var createdPingLocation: CLLocationCoordinate2D?
    @State private var viewModel = CreatePingViewModel()
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showLocationPicker = false

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            CreatePingHeader(onDismiss: handleDismiss)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    CreatePingCategorySection(
                        selectedCategory: $viewModel.selectedCategory
                    )

                    CreatePingTextSection(
                        text: $viewModel.text,
                        characterCount: viewModel.characterCount,
                        isOverLimit: viewModel.isOverLimit
                    )

                    CreatePingPhotoSection(
                        selectedImageData: viewModel.selectedImageData,
                        isProcessingImage: viewModel.isProcessingImage,
                        onRemove: { viewModel.removeSelectedImage() },
                        showPhotoPicker: $showPhotoPicker,
                        showCamera: $showCamera
                    )

                    CreatePingExpirySection(
                        selectedIndex: $viewModel.selectedExpirationIndex,
                        isCustomDuration: $viewModel.isCustomDuration,
                        customDurationHours: $viewModel.customDurationHours,
                        durationDisplayLabel: viewModel.customExpiryDisplayLabel,
                        absoluteTimeLabel: viewModel.customExpiryAbsoluteLabel
                    )

                    CreatePingLocationSection(
                        locationDisplayText: viewModel.locationDisplayText,
                        hasLocation: viewModel.selectedLocation != nil,
                        onTap: { showLocationPicker = true }
                    )

                    if let errorMessage = viewModel.errorMessage {
                        CreatePingErrorBanner(message: errorMessage)
                    }
                }
                .padding(.bottom, 100)
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollIndicators(.hidden)

            CreatePingButton(
                canCreate: viewModel.canCreate,
                isCreating: viewModel.isCreating,
                action: handleCreate
            )
        }
        .background(Color.pingSurface)
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickerItem, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { image in
                viewModel.handleCameraImage(image)
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(
                selectedLocation: $viewModel.selectedLocation,
                selectedLocationName: $viewModel.selectedLocationName
            )
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await viewModel.handleSelectedPhoto(item: newItem)
                pickerItem = nil
            }
        }
        .task {
            viewModel.configure(
                authService: authService,
                pingService: pingService,
                chatService: chatService,
                locationService: locationService,
                contentModerationService: contentModerationService,
                rateLimitService: rateLimitService,
                analyticsService: analyticsService
            )
        }
        .onChange(of: viewModel.didCreatePing) { _, didCreate in
            if didCreate {
                createdPingLocation = viewModel.selectedLocation
                dismiss()
            }
        }
    }

    // MARK: - Actions

    private func handleDismiss() {
        dismiss()
    }

    private func handleCreate() {
        Task {
            await viewModel.createPing()
        }
    }
}
