import SwiftUI

nonisolated enum ParticipantWeighInPresentation: Sendable {
    case entry
    case pushed
}

@MainActor
struct ParticipantWeighInView: View {
    let store: ParticipantJourneyStore
    let type: WeighInType
    let presentation: ParticipantWeighInPresentation

    @Environment(\.dismiss) private var dismiss
    @State private var weightInput = ""
    @State private var fieldError: String?
    @State private var confirmation: WeighInConfirmation?
    @State private var hasLocalEvidence = false
    @FocusState private var isWeightFocused: Bool

    var body: some View {
        Form {
            if type == .final && !isFinalWindowOpen {
                Section {
                    LockedContentView(
                        title: "participant.weigh.final.locked.title",
                        message: "participant.weigh.final.locked.message"
                    )
                }
            }

            Section {
                TextField(
                    "participant.weigh.field",
                    text: $weightInput
                )
                .keyboardType(.decimalPad)
                .focused($isWeightFocused)
                .accessibilityIdentifier("participant.weigh.input")

                LabeledContent(
                    "participant.weigh.unit",
                    value: "kg"
                )

                if let fieldError {
                    Text(fieldError)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appDestructive)
                        .accessibilityIdentifier(
                            "participant.weigh.validation"
                        )
                }
            } header: {
                Text(
                    type == .initial
                        ? "participant.weigh.initial.title"
                        : "participant.weigh.final.title"
                )
            } footer: {
                Text("participant.weigh.decimal_hint")
            }

            Section {
                Button {
                    hasLocalEvidence.toggle()
                } label: {
                    Label(
                        hasLocalEvidence
                            ? "participant.weigh.evidence.attached"
                            : "participant.weigh.evidence.action",
                        systemImage: hasLocalEvidence
                            ? "checkmark.circle.fill"
                            : "photo"
                    )
                }
            } header: {
                Text("participant.weigh.evidence.title")
            } footer: {
                Text("participant.weigh.evidence.message")
            }

            Section {
                Label(
                    "participant.weigh.privacy",
                    systemImage: "lock.shield"
                )
                .foregroundStyle(Color.appSecondaryText)
            }

            Section {
                Button(
                    type == .initial
                        ? "participant.weigh.initial.submit"
                        : "participant.weigh.final.submit"
                ) {
                    prepareConfirmation()
                }
                .disabled(
                    weightInput.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty || !isFinalWindowOpen
                )
                .accessibilityIdentifier("participant.weigh.submit")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle(
            Text(
                type == .initial
                    ? "participant.weigh.initial.navigation_title"
                    : "participant.weigh.final.navigation_title"
            )
        )
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("action.done") {
                    isWeightFocused = false
                }
            }
        }
        .onAppear { isWeightFocused = true }
        .sheet(item: $confirmation) { confirmation in
            ConfirmationSheet(
                title: "participant.weigh.confirm.title",
                message: confirmation.messageKey,
                confirmTitle: "action.confirm",
                isDestructive: false
            ) {
                Task {
                    await submit()
                }
            }
        }
    }

    private var isFinalWindowOpen: Bool {
        guard type == .final,
              let program = store.currentProgram else {
            return true
        }
        do {
            try WeighInWindowValidator().validate(
                type: .final,
                now: store.effectiveDate,
                program: program
            )
            return true
        } catch {
            return false
        }
    }

    private func prepareConfirmation() {
        do {
            let weight = try IndonesianWeightInputParser().parse(weightInput)
            try WeighInValidator().validate(weightKilograms: weight)
            fieldError = nil
            confirmation = WeighInConfirmation(
                messageKey: type == .initial
                    ? "participant.weigh.confirm.initial_message"
                    : "participant.weigh.confirm.final_message"
            )
        } catch let error as DomainError {
            fieldError = ParticipantFormatting.fieldReason(error)
        } catch {
            fieldError = String(localized: "participant.error.generic")
        }
    }

    private func submit() async {
        do {
            try await store.submitWeighIn(
                type: type,
                input: weightInput
            )
            fieldError = nil
            if presentation == .pushed {
                dismiss()
            }
        } catch let error as DomainError {
            fieldError = ParticipantFormatting.fieldReason(error)
        } catch {
            fieldError = String(localized: "participant.error.generic")
        }
    }
}

private struct WeighInConfirmation: Identifiable {
    let id = UUID()
    let messageKey: LocalizedStringKey
}

#Preview("Timbang awal") {
    NavigationStack {
        ParticipantWeighInPreview(type: .initial)
    }
}

#Preview("Timbang akhir terkunci") {
    NavigationStack {
        ParticipantWeighInPreview(type: .final)
    }
}

@MainActor
private struct ParticipantWeighInPreview: View {
    let type: WeighInType
    @State private var store = ParticipantJourneyStore(
        environment: .preview
    )

    var body: some View {
        ParticipantWeighInView(
            store: store,
            type: type,
            presentation: .pushed
        )
        .task { await store.load() }
    }
}
