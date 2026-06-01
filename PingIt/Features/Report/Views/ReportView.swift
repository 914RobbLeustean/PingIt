import SwiftUI

struct ReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ReportViewModel
    private let reportService: any ReportServicing
    private let blockService: BlockService

    var onDidBlock: (() -> Void)?

    init(
        targetType: Report.ReportTargetType,
        targetId: String,
        targetOwnerId: String,
        targetContent: String? = nil,
        targetImageURL: String? = nil,
        reportService: any ReportServicing,
        blockService: BlockService,
        onDidBlock: (() -> Void)? = nil
    ) {
        self._viewModel = State(initialValue: ReportViewModel(
            targetType: targetType,
            targetId: targetId,
            targetOwnerId: targetOwnerId,
            targetContent: targetContent,
            targetImageURL: targetImageURL
        ))
        self.reportService = reportService
        self.blockService = blockService
        self.onDidBlock = onDidBlock
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            ReportSheetHeader(
                title: viewModel.didSubmitReport ? "Thanks" : "Report",
                onClose: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.didSubmitReport {
                        ReportSubmittedCard()
                        if viewModel.showBlockOffer {
                            ReportBlockOfferCard(
                                onBlock: handleBlockTap,
                                onSkip: { dismiss() }
                            )
                        }
                    } else {
                        ReportReasonSection(selectedReason: $viewModel.selectedReason)
                        ReportDetailsSection(details: $viewModel.additionalDetails)
                        if let error = viewModel.errorMessage {
                            ReportErrorChip(message: error)
                        }
                        ReportSubmitButton(
                            isEnabled: viewModel.selectedReason != nil && !viewModel.isSubmitting,
                            isSubmitting: viewModel.isSubmitting,
                            action: handleSubmit
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.pingBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .task {
            viewModel.configure(reportService: reportService)
        }
    }

    @MainActor
    private func handleSubmit() {
        Task { await viewModel.submitReport() }
    }

    private func handleBlockTap() {
        Task {
            try? await blockService.blockUser(viewModel.targetOwnerId)
            dismiss()
            onDidBlock?()
        }
    }
}

// MARK: - Header

private struct ReportSheetHeader: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.pingBorder)
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 14)

            HStack {
                Spacer().frame(width: 38, height: 38)

                Spacer()

                Text(title)
                    .font(.syne(.extraBold, size: 18, relativeTo: .title3))
                    .foregroundStyle(Color.pingTextPrimary)
                    .tracking(-0.3)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.pingTextSecondary)
                        .frame(width: 38, height: 38)
                        .background(Color.pingSurface, in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Reason Section

private struct ReportReasonSection: View {
    @Binding var selectedReason: Report.ReportReason?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's the issue?")
                .font(.dmSans(.semiBold, size: 13, relativeTo: .footnote))
                .foregroundStyle(Color.pingTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 10) {
                ForEach(Report.ReportReason.allCases, id: \.self) { reason in
                    ReportReasonCard(
                        reason: reason,
                        isSelected: selectedReason == reason,
                        onTap: { selectedReason = reason }
                    )
                }
            }
        }
    }
}

private struct ReportReasonCard: View {
    let reason: Report.ReportReason
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: reason.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.pingAccent : Color.pingTextSecondary)
                    .frame(width: 22)

                Text(reason.rawValue)
                    .font(.dmSans(.semiBold, size: 15, relativeTo: .body))
                    .foregroundStyle(Color.pingTextPrimary)

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.pingAccent : Color.pingBorder,
                            lineWidth: isSelected ? 6 : 1.5
                        )
                        .frame(width: 20, height: 20)
                }
                .animation(.easeOut(duration: 0.15), value: isSelected)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.pingSurface, in: .rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color.pingAccent : Color.pingBorder,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(reason.rawValue)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Details Section

private struct ReportDetailsSection: View {
    @Binding var details: String

    private let limit = 500
    private var characterCount: Int { details.count }
    private var isOverLimit: Bool { characterCount > limit }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional details (optional)")
                .font(.dmSans(.semiBold, size: 13, relativeTo: .footnote))
                .foregroundStyle(Color.pingTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(alignment: .trailing, spacing: 6) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $details)
                        .font(.dmSans(.regular, size: 15, relativeTo: .body))
                        .foregroundStyle(Color.pingTextPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(14)
                        .frame(minHeight: 96)

                    if details.isEmpty {
                        Text("Tell us more about what happened...")
                            .font(.dmSans(.regular, size: 15, relativeTo: .body))
                            .foregroundStyle(Color.pingTextSecondary)
                            .padding(18)
                            .allowsHitTesting(false)
                    }
                }
                .background(Color.pingSurfaceElevated)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.pingBorder, lineWidth: 1)
                )

                Text("\(characterCount)/\(limit)")
                    .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                    .foregroundStyle(isOverLimit ? Color.pingHot : .pingTextSecondary)
                    .padding(.trailing, 4)
            }
        }
        .onChange(of: details) { _, newValue in
            if newValue.count > limit {
                details = String(newValue.prefix(limit))
            }
        }
    }
}

// MARK: - Submit Button

private struct ReportSubmitButton: View {
    let isEnabled: Bool
    let isSubmitting: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.black)
                } else {
                    Text("Submit Report")
                        .font(.syne(.extraBold, size: 14))
                        .tracking(-0.3)
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isEnabled ? Color.pingAccent : Color.pingAccent.opacity(0.35),
                in: .capsule
            )
            .shadow(
                color: Color.pingAccent.opacity(isEnabled ? 0.3 : 0),
                radius: 10
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel("Submit report")
    }
}

// MARK: - Error Chip

private struct ReportErrorChip: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.pingHot)

            Text(message)
                .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                .foregroundStyle(Color.pingTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.pingHot.opacity(0.12), in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.pingHot.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Submitted Card

private struct ReportSubmittedCard: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.pingLive)
                .padding(.top, 12)

            Text("Thanks for reporting")
                .font(.syne(.extraBold, size: 20, relativeTo: .title3))
                .foregroundStyle(Color.pingTextPrimary)

            Text("We'll review this within 72 hours.")
                .font(.dmSans(.regular, size: 14, relativeTo: .body))
                .foregroundStyle(Color.pingTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .background(Color.pingSurface, in: .rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.pingBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Block Offer Card

private struct ReportBlockOfferCard: View {
    let onBlock: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Also block this user?")
                    .font(.syne(.extraBold, size: 16, relativeTo: .headline))
                    .foregroundStyle(Color.pingTextPrimary)

                Text("You won't see their pings or messages.")
                    .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color.pingTextSecondary)
            }

            HStack(spacing: 10) {
                Button(action: onSkip) {
                    Text("No thanks")
                        .font(.dmSans(.semiBold, size: 14, relativeTo: .body))
                        .foregroundStyle(Color.pingTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.pingSurfaceElevated, in: .capsule)
                        .overlay(
                            Capsule().strokeBorder(Color.pingBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button(action: onBlock) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Block")
                            .font(.syne(.extraBold, size: 14))
                            .tracking(-0.3)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.pingHot, in: .capsule)
                    .shadow(color: Color.pingHot.opacity(0.35), radius: 10)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Block user")
            }
        }
        .padding(18)
        .background(Color.pingSurface, in: .rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.pingBorder, lineWidth: 1)
        )
    }
}

// MARK: - ReportReason icons

private extension Report.ReportReason {
    var icon: String {
        switch self {
        case .spam:                 "megaphone"
        case .harassment:           "exclamationmark.bubble"
        case .inappropriateContent: "eye.slash"
        case .other:                "ellipsis.circle"
        }
    }
}
