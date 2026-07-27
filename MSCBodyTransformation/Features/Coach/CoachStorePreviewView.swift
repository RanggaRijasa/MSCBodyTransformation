import SwiftUI

@MainActor
struct CoachStorePreviewView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let state: CoachStorePreviewState

    @State private var actionError: String?
    @State private var showsDemoConfirmation = false

    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: AppSpacing.small)]
        }
        return [
            GridItem(.adaptive(minimum: 180), spacing: AppSpacing.small)
        ]
    }

    var body: some View {
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
                store(snapshot)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationTitle(Text("coach.store.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if state.state == .idle {
                await state.load()
            }
        }
        .alert(
            "coach.store.confirm.title",
            isPresented: $showsDemoConfirmation
        ) {
            Button("action.cancel", role: .cancel) {
                state.simulateCancellation()
            }
            Button("coach.store.confirm.demo_action") {
                Task {
                    await completeDemoPurchase()
                }
            }
        } message: {
            Text("coach.store.confirm.message")
        }
        .accessibilityIdentifier("coach.store")
    }

    private func store(_ snapshot: CoachStoreSnapshot) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.large) {
                demoNotice
                balance(snapshot.wallet)
                purchaseStatus
                packs
                purchaseHistory(snapshot.ledger)
#if DEBUG
                debugStates
#endif
                if let actionError {
                    Label(
                        actionError,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appDestructive)
                }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity)
        }
        .refreshable {
            await state.load()
        }
    }

    private var demoNotice: some View {
        Label {
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text("coach.store.demo.title")
                    .font(AppTypography.cardTitle)
                Text("coach.store.demo.message")
                    .font(AppTypography.secondary)
            }
        } icon: {
            Image(systemName: "shippingbox.fill")
                .foregroundStyle(Color.brandAccent)
        }
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.appSurface,
            in: RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
            .stroke(Color.appBorder, lineWidth: 1)
        }
        .accessibilityIdentifier("coach.store.no-real-purchase")
    }

    private func balance(_ wallet: CoachWallet) -> some View {
        MetricCard(
            title: "metric.seat_credits",
            value: CoachFormatting.number(wallet.availableSeatCredits),
            systemImage: "person.badge.plus",
            accentColor: .brandAccent
        )
    }

    @ViewBuilder
    private var purchaseStatus: some View {
        switch state.purchaseState {
        case .loading:
            ProgressView("coach.store.state.loading")
        case .available:
            StatusBadge(
                title: "coach.store.state.available",
                kind: .success
            )
        case .purchasing(let pack):
            statusCard(
                title: "coach.store.state.purchasing",
                detail: pack.seatCredits
            )
        case .pending(let pack):
            statusCard(
                title: "coach.store.state.pending",
                detail: pack.seatCredits
            )
        case .success(let pack):
            statusCard(
                title: "coach.store.state.success",
                detail: pack.seatCredits,
                kind: .success
            )
        case .cancelled:
            StatusBadge(
                title: "coach.store.state.cancelled",
                kind: .neutral
            )
        case .failed:
            StatusBadge(
                title: "coach.store.state.error",
                kind: .error
            )
        }
    }

    private func statusCard(
        title: LocalizedStringKey,
        detail: Int,
        kind: AppStatusKind = .pending
    ) -> some View {
        let seatCount = Text(
            detail,
            format: .number.locale(CoachFormatting.locale)
        )

        return HStack {
            StatusBadge(title: title, kind: kind)
            Spacer()
            Text("\(seatCount) \(Text("coach.store.seat_suffix"))")
            .font(AppTypography.cardTitle.monospacedDigit())
        }
        .padding(AppSpacing.medium)
        .background(
            Color.appSurface,
            in: RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
        )
    }

    private var packs: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(
                title: "coach.store.packs.title",
                subtitle: "coach.store.packs.subtitle"
            )
            LazyVGrid(columns: columns, spacing: AppSpacing.small) {
                ForEach(CoachSeatPack.samples) { pack in
                    let seatCount = Text(
                        pack.seatCredits,
                        format: .number.locale(CoachFormatting.locale)
                    )
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("\(seatCount) \(Text("coach.store.seat_suffix"))")
                        .font(AppTypography.metric.monospacedDigit())
                        Text(CoachFormatting.currency(pack.samplePrice))
                            .font(AppTypography.cardTitle.monospacedDigit())
                        Text("coach.store.sample_price")
                            .font(AppTypography.secondary)
                            .foregroundStyle(Color.appSecondaryText)
#if DEBUG
                        Button {
                            state.prepareDemoPurchase(pack)
                            showsDemoConfirmation = true
                        } label: {
                            Text("coach.store.demo_cta")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.brandPrimary)
                        .accessibilityIdentifier(
                            "coach.store.pack.\(pack.seatCredits)"
                        )
#else
                        Button("coach.store.demo_cta") {}
                            .buttonStyle(.bordered)
                            .disabled(true)
#endif
                    }
                    .padding(AppSpacing.medium)
                    .background(
                        Color.appSurface,
                        in: RoundedRectangle(
                            cornerRadius: AppRadius.large,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: AppRadius.large,
                            style: .continuous
                        )
                        .stroke(Color.appBorder, lineWidth: 1)
                    }
                }
            }
        }
    }

    private func purchaseHistory(
        _ ledger: [CreditLedgerEntry]
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "coach.store.history.title")
            if ledger.isEmpty {
                Text("coach.store.history.empty")
                    .foregroundStyle(Color.appSecondaryText)
            } else {
                ForEach(ledger) { entry in
                    HStack(alignment: .top, spacing: AppSpacing.medium) {
                        Image(
                            systemName: entry.seatCreditDelta >= 0
                                ? "plus.circle.fill"
                                : "minus.circle.fill"
                        )
                        .foregroundStyle(
                            entry.seatCreditDelta >= 0
                                ? Color.appSuccess
                                : Color.appWarning
                        )
                        VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                            Text(entry.note)
                                .font(AppTypography.body)
                            Text(CoachFormatting.date(entry.createdAt))
                                .font(AppTypography.secondary)
                                .foregroundStyle(Color.appSecondaryText)
                        }
                        Spacer()
                        Text(
                            entry.seatCreditDelta,
                            format: .number
                                .sign(strategy: .always())
                                .locale(CoachFormatting.locale)
                        )
                        .font(AppTypography.cardTitle.monospacedDigit())
                    }
                    .padding(AppSpacing.medium)
                    .background(
                        Color.appSurface,
                        in: RoundedRectangle(
                            cornerRadius: AppRadius.large,
                            style: .continuous
                        )
                    )
                }
            }
        }
    }

#if DEBUG
    private var debugStates: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "coach.store.debug.title")
            Text("coach.store.debug.message")
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
            ViewThatFits(in: .horizontal) {
                HStack {
                    debugButton("Pending") {
                        state.setPreviewState(
                            .pending(CoachSeatPack.samples[0])
                        )
                    }
                    debugButton("Berhasil") {
                        state.setPreviewState(
                            .success(CoachSeatPack.samples[0])
                        )
                    }
                    debugButton("Dibatalkan") {
                        state.setPreviewState(.cancelled)
                    }
                    debugButton("Gagal") {
                        state.setPreviewState(.failed)
                    }
                }
                VStack {
                    debugButton("Pending") {
                        state.setPreviewState(
                            .pending(CoachSeatPack.samples[0])
                        )
                    }
                    debugButton("Berhasil") {
                        state.setPreviewState(
                            .success(CoachSeatPack.samples[0])
                        )
                    }
                    debugButton("Dibatalkan") {
                        state.setPreviewState(.cancelled)
                    }
                    debugButton("Gagal") {
                        state.setPreviewState(.failed)
                    }
                }
            }
        }
        .padding(AppSpacing.medium)
        .adaptiveGlassSurface()
    }

    private func debugButton(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .frame(minHeight: 44)
    }
#endif

    private func completeDemoPurchase() async {
        do {
            try await state.simulateSuccessfulPurchase()
            actionError = nil
        } catch let error as DomainError {
            actionError = CoachFormatting.reason(error)
            state.simulateFailure()
        } catch {
            actionError = String(localized: "coach.error.generic")
            state.simulateFailure()
        }
    }
}

#Preview("Store Coach — berhasil") {
    NavigationStack {
        CoachStorePreview()
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

@MainActor
private struct CoachStorePreview: View {
    @State private var state = CoachStorePreviewState(environment: .preview)

    var body: some View {
        CoachStorePreviewView(state: state)
    }
}
