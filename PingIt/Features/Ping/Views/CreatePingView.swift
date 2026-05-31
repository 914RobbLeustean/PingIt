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

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                textSection

                PingPhotoSectionView(
                    selectedImageData: viewModel.selectedImageData,
                    isProcessingImage: viewModel.isProcessingImage,
                    onRemove: { viewModel.removeSelectedImage() },
                    showPhotoPicker: $showPhotoPicker,
                    showCamera: $showCamera
                )

                locationSection

                expirationSection(viewModel: viewModel)

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Create Ping")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: handleCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: handleCreate)
                        .disabled(viewModel.canCreate == false)
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $pickerItem, matching: .images)
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView { image in
                    viewModel.handleCameraImage(image)
                }
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
    }

    // MARK: - Sections

    private var textSection: some View {
        @Bindable var viewModel = viewModel
        return Section("What's happening?") {
            TextField("Describe your activity...", text: $viewModel.text, axis: .vertical)
                .lineLimit(3...6)

            HStack {
                Spacer()
                Text("\(viewModel.characterCount) / \(Constants.Ping.maxTextLength)")
                    .font(.caption)
                    .foregroundStyle(viewModel.isOverLimit ? .red : .secondary)
                    .accessibilityLabel("Character count")
                    .accessibilityValue("\(viewModel.characterCount) of \(Constants.Ping.maxTextLength)")
            }
        }
    }

    private var locationSection: some View {
        @Bindable var viewModel = viewModel
        return Section("Location") {
            NavigationLink {
                LocationPickerView(
                    selectedLocation: $viewModel.selectedLocation,
                    selectedLocationName: $viewModel.selectedLocationName
                )
            } label: {
                HStack {
                    Label(
                        viewModel.locationDisplayText,
                        systemImage: viewModel.selectedLocation != nil ? "mappin.circle.fill" : "mappin.circle"
                    )
                    Spacer()
                }
                .foregroundStyle(viewModel.selectedLocation != nil ? .primary : .secondary)
            }
            .accessibilityHint("Opens a map to choose the ping location")
        }
    }

    private func expirationSection(viewModel: CreatePingViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return Section("Expires in") {
            Picker("Expiration", selection: $viewModel.selectedExpirationIndex) {
                ForEach(0..<4, id: \.self) { index in
                    Text(self.viewModel.expirationLabel(for: index)).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.selectedExpirationIndex) { _, newValue in
                self.viewModel.isCustomDuration = newValue == 3
            }

            if viewModel.isCustomDuration {
                DatePicker(
                    "Expires at",
                    selection: $viewModel.customExpiryDate,
                    in: self.viewModel.customExpiryRange,
                    displayedComponents: .hourAndMinute
                )
                .accessibilityLabel("Custom ping expiry time")
            }
        }
    }

    // MARK: - Actions

    private func handleCancel() {
        dismiss()
    }

    private func handleCreate() {
        Task {
            await viewModel.createPing()
        }
    }
}
