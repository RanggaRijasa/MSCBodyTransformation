import SwiftUI

@MainActor
struct AdminCopyDayContentSheet: View {
    @Environment(\.dismiss) private var dismiss

    let sourceDay: AdminDayDraft
    let targetDays: [AdminDayDraft]
    let onCopy: (Set<UUID>) -> Void

    @State private var selectedDayIDs: Set<UUID> = []
    @State private var showsReplacementConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Sumber") {
                    LabeledContent(
                        "Hari",
                        value: "Hari ke-\(sourceDay.dayNumber)"
                    )
                    LabeledContent {
                        Text(
                            sourceDay.steps.count,
                            format: .number.locale(
                                Locale(identifier: "id-ID")
                            )
                        )
                    } label: {
                        Text("Jumlah langkah")
                    }
                }

                Section {
                    ForEach(targetDays) { day in
                        targetRow(day)
                    }
                } header: {
                    Text("Pilih hari tujuan")
                } footer: {
                    Text(
                        "Deskripsi dan seluruh langkah pada hari tujuan akan diganti. Nama dan tanggal hari tetap."
                    )
                }
            }
            .navigationTitle("Salin isi hari")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salin") {
                        requestCopy()
                    }
                    .disabled(selectedDayIDs.isEmpty)
                    .accessibilityIdentifier(
                        "admin.program.copy-content.confirm"
                    )
                }
            }
            .confirmationDialog(
                "Ganti isi hari yang dipilih?",
                isPresented: $showsReplacementConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    "Ganti isi hari",
                    role: .destructive
                ) {
                    copyAndDismiss()
                }
                Button("Batal", role: .cancel) {}
            } message: {
                Text(
                    "Hari tujuan yang sudah berisi konten akan diganti dengan isi hari sumber."
                )
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityIdentifier("admin.program.copy-content.sheet")
    }

    private func targetRow(_ day: AdminDayDraft) -> some View {
        Button {
            if selectedDayIDs.contains(day.id) {
                selectedDayIDs.remove(day.id)
            } else {
                selectedDayIDs.insert(day.id)
            }
        } label: {
            HStack(spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text("Hari ke-\(day.dayNumber) · \(day.title)")
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(Color.appPrimaryText)

                    HStack(spacing: AppSpacing.xSmall) {
                        Text(
                            "\(day.steps.count.formatted(.number.locale(Locale(identifier: "id-ID")))) langkah"
                        )
                        if hasContent(day) {
                            Text("Isi saat ini akan diganti")
                                .foregroundStyle(Color.appWarning)
                        }
                    }
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                }

                Spacer(minLength: AppSpacing.small)

                Image(
                    systemName: selectedDayIDs.contains(day.id)
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.title3)
                .foregroundStyle(
                    selectedDayIDs.contains(day.id)
                        ? Color.brandPrimary
                        : Color.appSecondaryText
                )
                .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(
            selectedDayIDs.contains(day.id)
                ? "Dipilih"
                : "Belum dipilih"
        )
        .accessibilityIdentifier(
            "admin.program.copy-content.target.\(day.id)"
        )
    }

    private var selectedDaysContainContent: Bool {
        targetDays.contains {
            selectedDayIDs.contains($0.id) && hasContent($0)
        }
    }

    private func hasContent(_ day: AdminDayDraft) -> Bool {
        !day.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !day.steps.isEmpty
    }

    private func requestCopy() {
        if selectedDaysContainContent {
            showsReplacementConfirmation = true
        } else {
            copyAndDismiss()
        }
    }

    private func copyAndDismiss() {
        onCopy(selectedDayIDs)
        dismiss()
    }
}
