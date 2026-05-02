import SwiftUI
import CoreLocation

struct CreatePingView: View {
    @Environment(AuthService.self) private var authService
    @Environment(PingService.self) private var pingService
    @Environment(ChatService.self) private var chatService
    @Environment(LocationService.self) private var locationService
    @Environment(ContentModerationService.self) private var contentModerationService
    @Environment(RateLimitService.self) private var rateLimitService
    @Environment(\.dismiss) private var dismiss
    @Binding var createdPingLocation: CLLocationCoordinate2D?
    @State private var viewModel = CreatePingViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section("What's happening?") {
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

                Section("Location") {
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

                Section("Expires in") {
                    Picker("Expiration", selection: $viewModel.selectedExpirationIndex) {
                        ForEach(0..<3, id: \.self) { index in
                            Text(viewModel.expirationLabel(for: index)).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }

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
            .task {
                viewModel.configure(
                    authService: authService,
                    pingService: pingService,
                    chatService: chatService,
                    locationService: locationService,
                    contentModerationService: contentModerationService,
                    rateLimitService: rateLimitService
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
