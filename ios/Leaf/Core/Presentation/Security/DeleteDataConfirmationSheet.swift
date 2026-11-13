import SwiftUI

/// Destructive two-step confirmation sheet for completely wiping user financial records.
public struct DeleteDataConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppContainer.self) private var container

    @State private var confirmationText: String = ""
    @State private var isDeleting: Bool = false
    @State private var errorMessage: String? = nil

    public let onDataDeleted: (() -> Void)?

    public init(onDataDeleted: (() -> Void)? = nil) {
        self.onDataDeleted = onDataDeleted
    }

    private var isConfirmed: Bool {
        confirmationText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "DELETE"
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Warning Icon
                        Image(systemName: "exclamationmark.octagon.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(LeafTheme.expenseCoral)
                            .padding(.top, 10)

                        VStack(spacing: 6) {
                            Text("Erase All Financial Data?")
                                .font(LeafTypography.titleMedium)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                            Text("This action permanently wipes all financial records on this device. This operation is completely irreversible unless you have an exported backup.")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        // Checklist of what will be erased
                        SquircleCard(cornerRadius: 14) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("WHAT WILL BE PERMANENTLY ERASED:")
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(LeafTheme.expenseCoral)

                                checklistItem("All expenses, income, and transfer transactions")
                                checklistItem("Custom categories and category spending history")
                                checklistItem("Active budgets and budget tracking history")
                                checklistItem("Savings goals, deposits, and withdrawal records")
                                checklistItem("Split groups, participants, and debt settlements")
                                checklistItem("Recurring schedules, bills, and reminder notifications")
                                checklistItem("Saved statements and temporary export files")
                            }
                            .padding(14)
                        }
                        .padding(.horizontal)

                        // Confirmation Input
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Type DELETE to confirm")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            TextField("DELETE", text: $confirmationText)
                                .font(LeafTypography.bodyBold)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)
                                .padding(12)
                                .background(LeafTheme.card(for: colorScheme))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isConfirmed ? LeafTheme.expenseCoral : LeafTheme.border(for: colorScheme), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)

                        if let error = errorMessage {
                            Text(error)
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.expenseCoral)
                                .padding(.horizontal)
                        }

                        // Destructive Wipe Button
                        Button {
                            executeDataWipe()
                        } label: {
                            HStack(spacing: 8) {
                                if isDeleting {
                                    ProgressView()
                                        .tint(Color.white)
                                } else {
                                    Image(systemName: "trash.fill")
                                    Text("Permanently Erase All Data")
                                }
                            }
                            .font(LeafTypography.bodyBold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isConfirmed && !isDeleting ? LeafTheme.expenseCoral : Color.gray.opacity(0.4))
                            .foregroundStyle(Color.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isConfirmed || isDeleting)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Delete All Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func checklistItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(LeafTheme.expenseCoral)
                .padding(.top, 2)

            Text(text)
                .font(LeafTypography.caption)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
        }
    }

    private func executeDataWipe() {
        guard isConfirmed else { return }
        isDeleting = true
        errorMessage = nil

        Task {
            do {
                try await container.deleteAllFinancialDataUseCase.execute()
                await MainActor.run {
                    self.isDeleting = false
                    dismiss()
                    onDataDeleted?()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isDeleting = false
                }
            }
        }
    }
}

