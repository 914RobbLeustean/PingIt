import SwiftUI
import CoreLocation

struct CreatePingView: View {
    @Environment(AuthService.self) private var authService
    @Environment(PingService.self) private var pingService
    @Environment(ChatService.self) private var chatService
    @Environment(LocationService.self) private var locationService
    @Environment(\.dismiss) private var dismiss
    @Binding var createdPingLocation: CLLocationCoordinate2D?
    @State private var viewModel: CreatePingViewModel?

    var body: some View {
        NavigationStack {
            Form {
                Section("What's happening?") {
                    TextField(
                        "Describe your activity...",
                        text: Binding(
                            get: { viewModel?.text ?? "" },
                            set: { viewModel?.text = $0 }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(3...6)

                    HStack {
                        Spacer()
                        Text("\(viewModel?.characterCount ?? 0) / \(Constants.Ping.maxTextLength)")
                            .font(.caption)
                            .foregroundStyle(viewModel?.isOverLimit == true ? .red : .secondary)
                    }
                }

                Section("Location") {
                    NavigationLink {
                        LocationPickerView(
                            selectedLocation: Binding(
                                get: { viewModel?.selectedLocation },
                                set: { viewModel?.selectedLocation = $0 }
                            ),
                            selectedLocationName: Binding(
                                get: { viewModel?.selectedLocationName },
                                set: { viewModel?.selectedLocationName = $0 }
                            )
                        )
                    } label: {
                        HStack {
                            Label(
                                viewModel?.locationDisplayText ?? "Choose location",
                                systemImage: viewModel?.selectedLocation != nil ? "mappin.circle.fill" : "mappin.circle"
                            )
                            Spacer()
                        }
                        .foregroundStyle(viewModel?.selectedLocation != nil ? .primary : .secondary)
                    }
                }

                Section("Expires in") {
                    Picker("Expiration", selection: Binding(
                        get: { viewModel?.selectedExpirationIndex ?? 1 },
                        set: { viewModel?.selectedExpirationIndex = $0 }
                    )) {
                        ForEach(0..<3, id: \.self) { index in
                            Text(viewModel?.expirationLabel(for: index) ?? "").tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let errorMessage = viewModel?.errorMessage {
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
                        .disabled(viewModel?.canCreate != true)
                }
            }
            .onAppear(perform: handleAppear)
            .onChange(of: viewModel?.didCreatePing) { _, didCreate in
                if didCreate == true {
                    createdPingLocation = viewModel?.selectedLocation
                    dismiss()
                }
            }
        }
    }

    // MARK: - Actions

    private func handleAppear() {
        if viewModel == nil {
            viewModel = CreatePingViewModel(
                authService: authService,
                pingService: pingService,
                chatService: chatService,
                locationService: locationService
            )
        }
    }

    private func handleCancel() {
        dismiss()
    }

    private func handleCreate() {
        Task {
            await viewModel?.createPing()
        }
    }
}
