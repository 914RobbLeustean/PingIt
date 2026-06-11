import SwiftUI

/// Creator-only sheet for editing a ping's text, details, and category.
/// Location, expiry, and photo are fixed at creation — the ping keeps its
/// identity on the map and in everyone's feed.
struct EditPingView: View {
    @Environment(PingService.self) private var pingService
    @Environment(ContentModerationService.self) private var contentModerationService
    @Environment(AnalyticsService.self) private var analyticsService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditPingViewModel

    init(ping: Ping) {
        self._viewModel = State(initialValue: EditPingViewModel(ping: ping))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            EditPingHeader(
                canSave: viewModel.canSave,
                isSaving: viewModel.isSaving,
                onCancel: { dismiss() },
                onSave: { Task { await viewModel.save() } }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    CreatePingTextSection(
                        text: $viewModel.text,
                        characterCount: viewModel.characterCount,
                        isOverLimit: viewModel.isOverLimit
                    )

                    CreatePingDescriptionSection(
                        text: $viewModel.descriptionText,
                        characterCount: viewModel.descriptionCharacterCount,
                        isOverLimit: viewModel.isDescriptionOverLimit
                    )

                    CreatePingCategorySection(
                        selectedCategory: $viewModel.selectedCategory
                    )

                    if let errorMessage = viewModel.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                            .foregroundStyle(Color.pingHot)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.pingBackground)
        .onChange(of: viewModel.didSave) { _, didSave in
            if didSave { dismiss() }
        }
        .task {
            viewModel.configure(
                pingService: pingService,
                contentModerationService: contentModerationService,
                analyticsService: analyticsService
            )
        }
    }
}

// MARK: - Header

private struct EditPingHeader: View {
    let canSave: Bool
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.pingTextPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.pingSurfaceElevated)
                    .clipShape(.circle)
                    .overlay(
                        Circle().strokeBorder(Color.pingBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel editing")

            Spacer()

            Text("Edit Ping")
                .font(.syne(.extraBold, size: 20, relativeTo: .title3))
                .foregroundStyle(Color.pingTextPrimary)

            Spacer()

            Button(action: onSave) {
                Group {
                    if isSaving {
                        ProgressView()
                            .tint(.black)
                            .scaleEffect(0.8)
                    } else {
                        Text("Save")
                            .font(.dmSans(.semiBold, size: 14))
                            .foregroundStyle(.black)
                    }
                }
                .frame(width: 64, height: 36)
                .background(canSave ? Color.pingAccent : Color.pingAccent.opacity(0.35))
                .clipShape(.capsule)
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .accessibilityLabel("Save changes")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }
}
