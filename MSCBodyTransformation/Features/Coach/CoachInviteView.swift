import SwiftUI

@MainActor
struct CoachInviteView: View {
    let state: CoachInviteComposerState
    let router: ShellTabRouter

    @State private var actionError: String?
    @State private var inviteToRevoke: CoachInvite?

    var body: some View {
        @Bindable var state = state

        Group {
            switch state.state {
            case .idle, .loading:
                LoadingStateView()
            case .failed(let error):
                ScrollView {
                    ErrorStateView(error: error) {
                        Task {
                            await state.load()
                        }
                    }
                    .padding(AppSpacing.medium)
                }
            case .loaded(let snapshot):
                inviteForm(snapshot, bindableState: $state)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .task {
            if state.state == .idle {
                await state.load()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    openStore()
                } label: {
                    Label(
                        "coach.action.store_preview",
                        systemImage: "bag"
                    )
                }
                .accessibilityIdentifier("coach.invite.open-store")
            }
        }
        .confirmationDialog(
            "coach.invite.revoke.confirm.title",
            isPresented: Binding(
                get: { inviteToRevoke != nil },
                set: {
                    if !$0 {
                        inviteToRevoke = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("coach.invite.revoke", role: .destructive) {
                guard let invite = inviteToRevoke else {
                    return
                }
                Task {
                    await revoke(invite)
                }
            }
            Button("action.cancel", role: .cancel) {}
        } message: {
            Text("coach.invite.revoke.confirm.message")
        }
        .accessibilityIdentifier("coach.invite")
    }

    private func inviteForm(
        _ snapshot: CoachInviteSnapshot,
        bindableState: Bindable<CoachInviteComposerState>
    ) -> some View {
        Form {
            walletSection(snapshot.wallet)
            composerSection(snapshot, bindableState: bindableState)
            if let invite = state.latestGeneratedInvite {
                generatedInviteSection(invite)
            }
            storePreviewSection
            historySection(snapshot)
            behaviorExplanation
            if let actionError {
                Section {
                    Label(
                        actionError,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(Color.appDestructive)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .refreshable {
            await state.load()
        }
    }

    private func walletSection(_ wallet: CoachWallet) -> some View {
        Section {
            LabeledContent("metric.seat_credits") {
                Text(
                    wallet.availableSeatCredits,
                    format: .number.locale(CoachFormatting.locale)
                )
                .font(AppTypography.cardTitle.monospacedDigit())
            }
            LabeledContent("coach.invite.capacity.available") {
                Text(
                    wallet.availableSeatCredits,
                    format: .number.locale(CoachFormatting.locale)
                )
                .monospacedDigit()
            }
            if wallet.availableSeatCredits == 0 {
                Label(
                    "coach.invite.exhausted.message",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(Color.appWarning)
            }
        } header: {
            Text("coach.invite.capacity.title")
        } footer: {
            Text("coach.invite.capacity.footer")
        }
    }

    private func composerSection(
        _ snapshot: CoachInviteSnapshot,
        bindableState: Bindable<CoachInviteComposerState>
    ) -> some View {
        Section("coach.invite.composer.title") {
            Picker(
                "coach.invite.program",
                selection: bindableState.selectedProgramID
            ) {
                ForEach(snapshot.programs) { program in
                    Text(program.title)
                        .tag(Optional(program.id))
                }
            }
            Stepper(
                value: bindableState.validForDays,
                in: 1...30
            ) {
                LabeledContent("coach.invite.expiry") {
                    (
                        Text(
                            state.validForDays,
                            format: .number.locale(CoachFormatting.locale)
                        )
                        + Text(" ")
                        + Text("coach.invite.days")
                    )
                    .monospacedDigit()
                }
            }
            Button {
                Task {
                    await generateInvite()
                }
            } label: {
                Label(
                    "coach.invite.generate",
                    systemImage: "qrcode"
                )
            }
            .disabled(
                state.selectedProgramID == nil
                    || state.isPerformingAction
            )
            .accessibilityIdentifier("coach.invite.generate")
        }
    }

    private func generatedInviteSection(
        _ invite: CoachInvite
    ) -> some View {
        Section {
            VStack(spacing: AppSpacing.medium) {
                CoachQRCodeView(
                    payload: "mscbody://invite/\(invite.code)"
                )
                Text(invite.code)
                    .font(AppTypography.metric.monospacedDigit())
                    .foregroundStyle(Color.appPrimaryText)
                    .accessibilityLabel(Text("shell.invite.code"))
                Text(
                    CoachFormatting.dateTime(invite.expiresAt)
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
                ShareLink(
                    item: "mscbody://invite/\(invite.code)"
                ) {
                    Label(
                        "coach.invite.share",
                        systemImage: "square.and.arrow.up"
                    )
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandPrimary)
                .accessibilityIdentifier("coach.invite.share")
            }
            .frame(maxWidth: .infinity)
        } header: {
            Text("coach.invite.generated.title")
        } footer: {
            Text("coach.invite.generated.footer")
        }
    }

    private var storePreviewSection: some View {
        Section {
            Button {
                openStore()
            } label: {
                Label(
                    "coach.action.store_preview",
                    systemImage: "bag"
                )
            }
            .accessibilityIdentifier("coach.invite.quick-store")
        }
    }

    private func historySection(
        _ snapshot: CoachInviteSnapshot
    ) -> some View {
        Section("coach.invite.history.title") {
            if snapshot.invites.isEmpty {
                Text("coach.invite.history.empty")
                    .foregroundStyle(Color.appSecondaryText)
            } else {
                ForEach(snapshot.invites) { invite in
                    CoachInviteHistoryRow(
                        invite: invite,
                        program: snapshot.programs.first {
                            $0.id == invite.programID
                        },
                        revoke: {
                            inviteToRevoke = invite
                        }
                    )
                }
            }
        }
    }

    private var behaviorExplanation: some View {
        Section("coach.invite.behavior.title") {
            Label(
                "coach.invite.behavior.no_decrement",
                systemImage: "checkmark.circle"
            )
            Label(
                "coach.invite.behavior.enrollment_consumes",
                systemImage: "person.badge.plus"
            )
            Label(
                "coach.invite.behavior.duplicate",
                systemImage: "arrow.triangle.2.circlepath"
            )
            Label(
                "coach.invite.behavior.production",
                systemImage: "shippingbox"
            )
        }
    }

    private func generateInvite() async {
        do {
            try await state.generateInvite()
            actionError = nil
        } catch let error as DomainError {
            actionError = CoachFormatting.reason(error)
        } catch {
            actionError = String(localized: "coach.error.generic")
        }
    }

    private func revoke(_ invite: CoachInvite) async {
        do {
            try await state.revoke(invite)
            actionError = nil
            inviteToRevoke = nil
        } catch let error as DomainError {
            actionError = CoachFormatting.reason(error)
        } catch {
            actionError = String(localized: "coach.error.generic")
        }
    }

    private func openStore() {
        router.navigate(
            to: .coach(.storePreview),
            in: .coach(.invite)
        )
    }
}

private struct CoachInviteHistoryRow: View {
    let invite: CoachInvite
    let program: Program?
    let revoke: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            HStack(alignment: .firstTextBaseline) {
                Text(invite.code)
                    .font(AppTypography.cardTitle.monospacedDigit())
                Spacer()
                statusBadge
            }
            Text(program?.title ?? String(localized: "coach.program.none"))
                .font(AppTypography.body)
            Text(
                CoachFormatting.dateTime(invite.expiresAt)
            )
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appSecondaryText)
            if invite.status == .active {
                Button(
                    "coach.invite.revoke",
                    role: .destructive,
                    action: revoke
                )
                .frame(minHeight: 44)
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch invite.status {
        case .active:
            StatusBadge(title: "coach.invite.status.active", kind: .success)
        case .redeemed:
            StatusBadge(title: "coach.invite.status.redeemed", kind: .neutral)
        case .expired:
            StatusBadge(title: "coach.invite.status.expired", kind: .warning)
        case .revoked:
            StatusBadge(title: "coach.invite.status.revoked", kind: .error)
        }
    }
}

#Preview("Undangan aktif") {
    NavigationStack {
        CoachInvitePreview()
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

@MainActor
private struct CoachInvitePreview: View {
    @State private var state = CoachInviteComposerState(environment: .preview)
    @State private var router = ShellTabRouter()

    var body: some View {
        CoachInviteView(state: state, router: router)
            .navigationTitle(Text("tab.coach.invite"))
    }
}
