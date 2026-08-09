import SwiftUI

@MainActor
struct CommerceAccountView: View {
    let accountID: UUID
    let coordinator: CommerceCoordinator
    let applications: any CoachApplicationRepository

    @Environment(\.dismiss) private var dismiss
    @State private var application: CoachApplication?
    @State private var offering: CommerceProductPresentation?
    @State private var isLoading = true
    @State private var isRestoring = false
    @State private var feedback: String?

    var body: some View {
        NavigationStack {
            Form {
                coachAccessSection
                purchaseHistorySection
                restoreSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle(
                String(
                    localized: "commerce.account.title",
                    defaultValue: "Pembelian dan akses"
                )
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        String(
                            localized: "action.close",
                            defaultValue: "Tutup"
                        )
                    ) {
                        dismiss()
                    }
                }
            }
            .task { await load() }
        }
    }

    @ViewBuilder
    private var coachAccessSection: some View {
        Section {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let application {
                LabeledContent(
                    String(
                        localized: "commerce.coach.application_status",
                        defaultValue: "Status pengajuan"
                    ),
                    value: statusTitle(application.status)
                )

                if let payment = application.payment,
                   let end = payment.accessEndsAt {
                    LabeledContent(
                        String(
                            localized: "commerce.coach.access_until",
                            defaultValue: "Akses aktif sampai"
                        ),
                        value: end.formatted(
                            .dateTime
                                .day()
                                .month(.wide)
                                .year()
                                .locale(Locale(identifier: "id-ID"))
                        )
                    )
                }

                if let offering {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text(offering.displayName)
                            .font(AppTypography.cardTitle)
                        Text(offering.description)
                            .font(AppTypography.secondary)
                            .foregroundStyle(Color.appSecondaryText)
                        LabeledContent(
                            String(
                                localized: "commerce.price",
                                defaultValue: "Harga Apple"
                            ),
                            value: offering.displayPrice
                        )
                        Button {
                            Task { await purchaseCoachAccess(offering) }
                        } label: {
                            purchaseButtonLabel
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                        .disabled(isBusy)
                        .accessibilityIdentifier(
                            "commerce.coach.purchase.confirm"
                        )
                    }
                } else if canPurchaseCoachAccess(application.status) {
                    Button {
                        Task { await prepareCoachAccess() }
                    } label: {
                        Label(
                            application.status == .active
                                ? String(
                                    localized: "commerce.coach.renew",
                                    defaultValue: "Perpanjang akses Coach"
                                )
                                : String(
                                    localized: "commerce.coach.activate",
                                    defaultValue: "Aktifkan akses Coach"
                                ),
                            systemImage: "apple.logo"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(isBusy)
                    .accessibilityIdentifier("commerce.coach.prepare")
                } else {
                    Text(
                        String(
                            localized: "commerce.coach.waiting_approval",
                            defaultValue: "Pembayaran tersedia setelah pengajuan diterima Admin."
                        )
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                }
            } else {
                Text(
                    String(
                        localized: "commerce.coach.no_application",
                        defaultValue: "Belum ada pengajuan Coach pada akun ini."
                    )
                )
                .foregroundStyle(Color.appSecondaryText)
            }

            if let feedback {
                Label(feedback, systemImage: "info.circle")
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
            }
        } header: {
            Text(
                String(
                    localized: "commerce.coach.title",
                    defaultValue: "Akses Coach tiga bulan"
                )
            )
        } footer: {
            Text(
                String(
                    localized: "commerce.coach.footer",
                    defaultValue: "Perpanjangan dilakukan manual. Jika akses berakhir, fitur dan QR Coach dinonaktifkan sampai pembayaran berikutnya terverifikasi."
                )
            )
        }
    }

    private var purchaseHistorySection: some View {
        Section {
            if coordinator.transactionHistory.isEmpty {
                Text(
                    String(
                        localized: "commerce.history.empty",
                        defaultValue: "Belum ada riwayat pembelian."
                    )
                )
                .foregroundStyle(Color.appSecondaryText)
            } else {
                ForEach(coordinator.transactionHistory) { transaction in
                    VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                        HStack {
                            Text(subjectTitle(transaction.subjectKind))
                                .font(AppTypography.label)
                            Spacer()
                            Text(transactionStatusTitle(transaction.status))
                                .font(AppTypography.secondary)
                                .foregroundStyle(statusColor(transaction.status))
                        }
                        Text(transaction.productID)
                            .font(.caption.monospaced())
                            .foregroundStyle(Color.appSecondaryText)
                            .textSelection(.enabled)
                        if let purchasedAt = transaction.purchasedAt {
                            Text(
                                purchasedAt.formatted(
                                    .dateTime
                                        .day()
                                        .month(.abbreviated)
                                        .year()
                                        .hour()
                                        .minute()
                                        .locale(Locale(identifier: "id-ID"))
                                )
                            )
                            .font(AppTypography.secondary)
                            .foregroundStyle(Color.appSecondaryText)
                        }
                    }
                    .padding(.vertical, AppSpacing.xxSmall)
                }
            }
        } header: {
            Text(
                String(
                    localized: "commerce.history.title",
                    defaultValue: "Riwayat pembelian"
                )
            )
        }
    }

    private var restoreSection: some View {
        Section {
            Button {
                Task { await restore() }
            } label: {
                if isRestoring {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label(
                        String(
                            localized: "commerce.restore.action",
                            defaultValue: "Pulihkan pembelian"
                        ),
                        systemImage: "arrow.clockwise"
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .disabled(isRestoring || isBusy)
            .accessibilityIdentifier("commerce.restore")
        } footer: {
            Text(
                String(
                    localized: "commerce.restore.footer",
                    defaultValue: "Gunakan jika pembelian lama belum muncul. Apple mungkin meminta autentikasi App Store."
                )
            )
        }
    }

    @ViewBuilder
    private var purchaseButtonLabel: some View {
        if isBusy {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else {
            Text(
                String(
                    localized: "commerce.purchase.action",
                    defaultValue: "Beli dengan Apple"
                )
            )
            .frame(maxWidth: .infinity)
        }
    }

    private var isBusy: Bool {
        switch coordinator.state {
        case .loadingProduct, .purchasing, .verifying:
            true
        default:
            false
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let loadedApplication = applications.coachApplication(
                userID: accountID
            )
            async let loadedHistory: Void = coordinator.loadHistory()
            application = try await loadedApplication
            _ = try await loadedHistory
            feedback = nil
        } catch let error as DomainError {
            feedback = errorMessage(error)
        } catch {
            feedback = String(
                localized: "commerce.error.generic",
                defaultValue: "Data pembelian belum dapat dimuat."
            )
        }
    }

    private func prepareCoachAccess() async {
        do {
            offering = try await coordinator.prepareCoachAccessPurchase()
            feedback = nil
        } catch let error as DomainError {
            feedback = errorMessage(error)
        } catch {
            feedback = String(
                localized: "commerce.error.generic",
                defaultValue: "Pembayaran belum dapat dimulai."
            )
        }
    }

    private func purchaseCoachAccess(
        _ offering: CommerceProductPresentation
    ) async {
        do {
            switch try await coordinator.purchase(offering) {
            case .fulfilled:
                self.offering = nil
                feedback = coordinator.roleRefreshError == nil
                    ? String(
                        localized: "commerce.coach.activated",
                        defaultValue: "Akses Coach berhasil diaktifkan."
                    )
                    : String(
                        localized: "commerce.coach.activated_refresh_needed",
                        defaultValue: "Akses Coach sudah aktif. Tutup lalu buka kembali aplikasi untuk memuat peran terbaru."
                    )
                application = try await applications.coachApplication(
                    userID: accountID
                )
            case .pending:
                feedback = String(
                    localized: "commerce.pending",
                    defaultValue: "Pembelian menunggu persetujuan Apple."
                )
            case .cancelled:
                feedback = nil
            }
        } catch let error as DomainError {
            feedback = errorMessage(error)
        } catch {
            feedback = String(
                localized: "commerce.error.generic",
                defaultValue: "Pembayaran belum berhasil. Coba lagi."
            )
        }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            let results = try await coordinator.restorePurchases()
            feedback = results.isEmpty
                ? String(
                    localized: "commerce.restore.empty",
                    defaultValue: "Tidak ada pembelian aktif yang perlu dipulihkan."
                )
                : String(
                    localized: "commerce.restore.success",
                    defaultValue: "Pembelian berhasil direkonsiliasi."
                )
            application = try await applications.coachApplication(
                userID: accountID
            )
        } catch let error as DomainError {
            feedback = errorMessage(error)
        } catch {
            feedback = String(
                localized: "commerce.error.generic",
                defaultValue: "Pembelian belum dapat dipulihkan."
            )
        }
    }

    private func canPurchaseCoachAccess(
        _ status: CoachApplicationStatus
    ) -> Bool {
        status == .acceptedPendingPayment
            || status == .active
            || status == .expired
    }

    private func statusTitle(_ status: CoachApplicationStatus) -> String {
        switch status {
        case .acceptedPendingPayment:
            String(
                localized: "coach.application.status.accepted_payment",
                defaultValue: "Diterima, menunggu pembayaran"
            )
        case .active, .approved:
            String(
                localized: "coach.application.status.active",
                defaultValue: "Aktif"
            )
        case .expired:
            String(
                localized: "coach.application.status.expired",
                defaultValue: "Berakhir"
            )
        case .rejected:
            String(
                localized: "coach.application.status.rejected",
                defaultValue: "Ditolak"
            )
        case .submitted, .pendingAdminApproval:
            String(
                localized: "coach.application.status.pending_admin_approval",
                defaultValue: "Menunggu keputusan Admin"
            )
        case .draft, .ineligible, .readyForPayment, .paymentProcessing,
             .paymentVerified:
            String(
                localized: "coach.application.status.processing",
                defaultValue: "Dalam proses"
            )
        }
    }

    private func subjectTitle(_ subject: CommerceSubjectKind) -> String {
        switch subject {
        case .program:
            String(
                localized: "commerce.subject.program",
                defaultValue: "Program"
            )
        case .coachAccess:
            String(
                localized: "commerce.subject.coach",
                defaultValue: "Akses Coach"
            )
        }
    }

    private func transactionStatusTitle(
        _ status: CommerceTransactionStatus
    ) -> String {
        switch status {
        case .pending:
            String(localized: "status.pending", defaultValue: "Menunggu")
        case .verified:
            String(localized: "status.verified", defaultValue: "Terverifikasi")
        case .refunded:
            String(localized: "status.refunded", defaultValue: "Dikembalikan")
        case .revoked:
            String(localized: "status.revoked", defaultValue: "Dicabut")
        case .expired:
            String(localized: "status.expired", defaultValue: "Berakhir")
        }
    }

    private func statusColor(_ status: CommerceTransactionStatus) -> Color {
        switch status {
        case .verified: .appSuccess
        case .pending: .appWarning
        case .refunded, .revoked, .expired: .appDestructive
        }
    }

    private func errorMessage(_ error: DomainError) -> String {
        switch error {
        case .offline:
            String(
                localized: "commerce.error.offline",
                defaultValue: "Tidak ada koneksi. Periksa internet lalu coba lagi."
            )
        case .sessionExpired:
            String(
                localized: "commerce.error.session",
                defaultValue: "Sesi berakhir. Masuk kembali untuk melanjutkan."
            )
        case .permissionDenied:
            String(
                localized: "commerce.error.approval",
                defaultValue: "Akses pembayaran belum diizinkan untuk akun ini."
            )
        case .notFound:
            String(
                localized: "commerce.product_unavailable",
                defaultValue: "Produk App Store belum tersedia."
            )
        case .conflict(let reason), .validation(_, let reason):
            reason
        case .timeout:
            String(
                localized: "commerce.error.timeout",
                defaultValue: "Permintaan terlalu lama. Coba lagi."
            )
        case .invalidFixture, .unknown:
            String(
                localized: "commerce.error.generic",
                defaultValue: "Terjadi kendala. Coba lagi."
            )
        }
    }
}
