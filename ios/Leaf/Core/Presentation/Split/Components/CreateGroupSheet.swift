import SwiftUI

/// Sheet for creating a new SplitGroup or editing an existing one.
/// Provides name entry, icon picker from curated SF Symbols, and a color palette picker.
public struct CreateGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public var existingGroup: SplitGroup?
    public let onSave: (String, String, String) async throws -> Void

    @State private var name: String = ""
    @State private var selectedIcon: String = "person.3.fill"
    @State private var selectedColorHex: String = "#10B981"
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    private let availableIcons = [
        "person.3.fill",
        "airplane",
        "fork.knife",
        "house.fill",
        "cart.fill",
        "car.fill",
        "film.fill",
        "gift.fill",
        "beach.umbrella.fill",
        "cup.and.saucer.fill",
        "music.note",
        "sparkles"
    ]

    private let availableColors = [
        "#10B981", // Emerald
        "#3B82F6", // Blue
        "#6366F1", // Indigo
        "#8B5CF6", // Purple
        "#EC4899", // Pink
        "#F43F5E", // Rose
        "#F97316", // Orange
        "#F59E0B", // Amber
        "#14B8A6", // Teal
        "#06B6D4"  // Cyan
    ]

    public init(
        existingGroup: SplitGroup? = nil,
        onSave: @escaping (String, String, String) async throws -> Void
    ) {
        self.existingGroup = existingGroup
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Error banner if any
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(LeafTheme.expenseCoral)
                                Text(error)
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.expenseCoral)
                            }
                            .padding(.horizontal)
                        }

                        // Preview Avatar Card
                        previewCard

                        // Name input
                        nameSection

                        // Icon picker
                        iconPickerSection

                        // Color picker
                        colorPickerSection

                        // Save action button
                        Button(action: {
                            Task { await handleSave() }
                        }) {
                            HStack(spacing: 8) {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: existingGroup != nil ? "checkmark" : "plus")
                                    Text(existingGroup != nil ? "Update Group" : "Create Group")
                                        .font(LeafTypography.headline)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? LeafTheme.brandEmerald.opacity(0.4)
                                : LeafTheme.brandEmerald
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(existingGroup != nil ? "Edit Group" : "New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
            .onAppear {
                if let g = existingGroup {
                    self.name = g.name
                    self.selectedIcon = g.iconName
                    self.selectedColorHex = g.colorHex
                }
            }
        }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: selectedColorHex).opacity(0.2))
                    .frame(width: 72, height: 72)

                Image(systemName: selectedIcon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color(hex: selectedColorHex))
            }

            Text(name.isEmpty ? "Group Preview" : name)
                .font(LeafTypography.headline)
                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
        )
        .padding(.horizontal)
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GROUP NAME")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .tracking(0.5)

            TextField("e.g. Goa Trip, Flatmates, Weekend Trek", text: $name)
                .font(LeafTypography.bodyMedium)
                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                )
        }
        .padding(.horizontal)
    }

    // MARK: - Icon Picker Section

    private var iconPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CHOOSE ICON")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .tracking(0.5)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                ForEach(availableIcons, id: \.self) { icon in
                    let isSelected = selectedIcon == icon
                    Button(action: {
                        selectedIcon = icon
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    isSelected
                                    ? Color(hex: selectedColorHex).opacity(0.2)
                                    : (colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                                )
                                .frame(height: 48)

                            Image(systemName: icon)
                                .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(
                                    isSelected
                                    ? Color(hex: selectedColorHex)
                                    : LeafTheme.textPrimary(for: colorScheme)
                                )
                        }
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color(hex: selectedColorHex) : LeafTheme.cardBorder(for: colorScheme),
                                    lineWidth: isSelected ? 2 : 0.75
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Color Picker Section

    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CHOOSE THEME COLOR")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableColors, id: \.self) { hex in
                        let isSelected = selectedColorHex.uppercased() == hex.uppercased()
                        Button(action: {
                            selectedColorHex = hex
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 40, height: 40)

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay(
                                Circle()
                                    .stroke(
                                        isSelected ? LeafTheme.textPrimary(for: colorScheme) : Color.clear,
                                        lineWidth: 2.5
                                    )
                                    .padding(-2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Save Handler

    private func handleSave() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Group name cannot be empty."
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            try await onSave(trimmed, selectedIcon, selectedColorHex)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}

