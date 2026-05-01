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
        NavigationStack {
            Form {
                if viewModel.didSubmitReport {
                    submittedSection
                } else {
                    reasonSection
                    detailsSection
                    submitSection
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { dismiss() })
                }
            }
            .task {
                viewModel.configure(reportService: reportService)
            }
        }
    }

    private var reasonSection: some View {
        Section("What's the issue?") {
            ForEach(Report.ReportReason.allCases, id: \.self) { reason in
                Button {
                    viewModel.selectedReason = reason
                } label: {
                    HStack {
                        Text(reason.rawValue)
                            .foregroundStyle(.primary)
                        Spacer()
                        if viewModel.selectedReason == reason {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
    }

    private var detailsSection: some View {
        Section("Additional details (optional)") {
            TextField("Tell us more...", text: $viewModel.additionalDetails, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var submitSection: some View {
        Section {
            Button("Submit Report", action: handleSubmit)
                .disabled(viewModel.selectedReason == nil || viewModel.isSubmitting)

            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    @ViewBuilder private var submittedSection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)

                Text("Thanks for reporting")
                    .font(.headline)

                Text("We'll review this within 72 hours.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }

        if viewModel.showBlockOffer {
            Section {
                Button("Block this user", systemImage: "hand.raised", role: .destructive) {
                    Task {
                        try? await blockService.blockUser(viewModel.targetOwnerId)
                        dismiss()
                        onDidBlock?()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button("No thanks") {
                    dismiss()
                }
            }
        }
    }

    @MainActor
    private func handleSubmit() {
        Task { await viewModel.submitReport() }
    }
}
