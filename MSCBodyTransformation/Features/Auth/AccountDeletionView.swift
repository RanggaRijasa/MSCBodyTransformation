import SwiftUI

@MainActor
struct AccountDeletionView: View {
    let user: AppUser

    @Environment(\.appEnvironment) private var environment
    @Environment(\.dismiss) private var dismiss

    @State private var password = ""
    @State private var isConfirmationPresented = false
    @State private var isVerifying = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    private var connectedProviders: [AuthenticationProvider] {
        user.authenticationProviders ?? []
    }

    private var isBusy: Bool {
        isVerifying || isDeleting
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    Text(
                        String(
                            localized: "account_deletion.title",
                            defaultValue: "Hapus akun"
                        )
                    )
                    .font(AppTypography.screenTitle)
                    .foregroundStyle(Color.appPrimaryText)
                    .accessibilityAddTraits(.isHeader)

                    permanentWarning
                    deletedDataSection
                    winnerSnapshotNote

                    if user.role == .coach {
                        coachTransferNote
                    }

                    identityConfirmationSection

                    if let errorMessage {
                        errorCard(message: errorMessage)
                    }

                    if isBusy {
                        progressStatus
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.top, AppSpacing.small)
                .padding(.bottom, AppSpacing.xxLarge)
            }
            .background(Color.appBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        String(
                            localized: "action.cancel",
                            defaultValue: "Batal"
                        )
                    ) {
                        dismiss()
                    }
                    .disabled(isBusy)
                }
            }
            .interactiveDismissDisabled(isBusy)
            .confirmationDialog(
                String(
                    localized: "account_deletion.confirmation.title",
                    defaultValue: "Hapus akun secara permanen?"
                ),
                isPresented: $isConfirmationPresented
            ) {
                Button(
                    String(
                        localized: "account_deletion.confirmation.action",
                        defaultValue: "Hapus akun sekarang"
                    ),
                    role: .destructive
                ) {
                    Task {
                        await deleteAccount()
                    }
                }
                Button(
                    String(
                        localized: "action.cancel",
                        defaultValue: "Batal"
                    ),
                    role: .cancel
                ) {}
            } message: {
                Text(
                    String(
                        localized: "account_deletion.confirmation.message",
                        defaultValue:
                            "Akun dan data pribadi akan dihapus sekarang. Tindakan ini tidak dapat dibatalkan."
                    )
                )
            }
        }
        .accessibilityIdentifier("account-deletion")
    }

    private var permanentWarning: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(Color.appDestructive)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(
                    String(
                        localized: "account_deletion.permanent.title",
                        defaultValue: "Penghapusan permanen"
                    )
                )
                .font(AppTypography.cardTitle)
                .foregroundStyle(Color.appPrimaryText)

                Text(
                    String(
                        localized: "account_deletion.permanent.message",
                        defaultValue:
                            "Akun dan data pribadi akan dihapus. Tindakan ini tidak dapat dibatalkan."
                    )
                )
                .font(AppTypography.body)
                .foregroundStyle(Color.appSecondaryText)
            }
        }
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.appDestructive.opacity(0.10),
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
            .stroke(Color.appDestructive.opacity(0.28), lineWidth: 1)
        }
    }

    private var deletedDataSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            sectionTitle(
                String(
                    localized: "account_deletion.data.title",
                    defaultValue: "Data yang akan dihapus"
                )
            )

            VStack(spacing: 0) {
                deletionRow(
                    title: String(
                        localized: "account_deletion.data.profile_media",
                        defaultValue: "Profil dan media pribadi"
                    ),
                    systemImage: "person.crop.circle.badge.xmark"
                )
                divider
                deletionRow(
                    title: String(
                        localized: "account_deletion.data.participation",
                        defaultValue: "Keikutsertaan, kiriman, dan skor"
                    ),
                    systemImage: "list.bullet.clipboard"
                )
                divider
                deletionRow(
                    title: String(
                        localized: "account_deletion.data.access",
                        defaultValue: "Akses akun dan sesi aktif"
                    ),
                    systemImage: "rectangle.portrait.and.arrow.right"
                )
            }
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

    private var winnerSnapshotNote: some View {
        informationNote(
            message: String(
                localized: "account_deletion.winner_snapshot",
                defaultValue:
                    "Catatan pemenang yang sudah dikunci tetap tersimpan tanpa identitas akun."
            ),
            systemImage: "trophy"
        )
    }

    private var coachTransferNote: some View {
        informationNote(
            message: String(
                localized: "account_deletion.coach_transfer",
                defaultValue:
                    "Akun Coach dengan peserta aktif harus dialihkan oleh Admin terlebih dahulu."
            ),
            systemImage: "person.2"
        )
    }

    private var identityConfirmationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            sectionTitle(
                String(
                    localized: "account_deletion.identity.title",
                    defaultValue: "Konfirmasi identitas"
                )
            )

            if connectedProviders.isEmpty {
                unavailableIdentityCard
            } else {
                ForEach(connectedProviders, id: \.rawValue) { provider in
                    providerCard(provider)
                    verificationControl(provider)
                }

                Text(
                    String(
                        localized: "account_deletion.verify.help",
                        defaultValue:
                            "Setelah verifikasi berhasil, kamu akan diminta konfirmasi terakhir sebelum akun dihapus."
                    )
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.sectionTitle)
            .foregroundStyle(Color.appPrimaryText)
            .accessibilityAddTraits(.isHeader)
    }

    private func deletionRow(
        title: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.appDestructive)
                .frame(width: 28)
                .accessibilityHidden(true)

            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(Color.appPrimaryText)

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.medium)
        .frame(minHeight: AppControlMetrics.minimumTouchTarget)
    }

    private var divider: some View {
        Divider()
            .padding(.leading, 60)
    }

    private func informationNote(
        message: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.appSecondaryText)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(message)
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.appSecondaryBackground,
            in: RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
        )
    }

    private func providerCard(
        _ provider: AuthenticationProvider
    ) -> some View {
        HStack(spacing: AppSpacing.medium) {
            providerIcon(provider)

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(user.email)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appPrimaryText)
                    .lineLimit(2)
                    .textSelection(.enabled)

                Text(providerConnectionTitle(provider))
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
            }

            Spacer(minLength: 0)

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.appSuccess)
                .accessibilityHidden(true)
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
    }

    @ViewBuilder
    private func providerIcon(
        _ provider: AuthenticationProvider
    ) -> some View {
        switch provider {
        case .apple:
            Image(systemName: "apple.logo")
                .font(.title2)
                .foregroundStyle(Color.appPrimaryText)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
        case .google:
            Image("GoogleGLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)
        case .email:
            Image(systemName: "envelope.fill")
                .font(.title3)
                .foregroundStyle(Color.appPrimaryText)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func verificationControl(
        _ provider: AuthenticationProvider
    ) -> some View {
        switch provider {
        case .apple:
            AuthenticationAppleButton(maximumWidth: .infinity) {
                verify(using: .provider(.apple))
            }
            .disabled(isBusy)
            .accessibilityIdentifier("account-deletion.apple")
        case .google:
            OfficialGoogleSignInButton(
                title: String(
                    localized: "account_deletion.verify.google",
                    defaultValue: "Verifikasi dengan Google"
                ),
                maximumWidth: .infinity
            ) {
                verify(using: .provider(.google))
            }
            .disabled(isBusy)
            .accessibilityIdentifier("account-deletion.google")
        case .email:
            VStack(spacing: AppSpacing.small) {
                SecureField(
                    String(
                        localized: "auth.field.password",
                        defaultValue: "Password"
                    ),
                    text: $password
                )
                .textContentType(.password)
                .padding(.horizontal, AppSpacing.medium)
                .frame(minHeight: 50)
                .background(
                    Color.appSurface,
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.medium,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: AppRadius.medium,
                        style: .continuous
                    )
                    .stroke(Color.appBorder, lineWidth: 1)
                }
                .accessibilityIdentifier("account-deletion.password")

                Button(
                    String(
                        localized: "account_deletion.verify.email",
                        defaultValue: "Verifikasi dengan password"
                    )
                ) {
                    verify(
                        using: .email(
                            email: user.email,
                            password: password
                        )
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandPrimary)
                .frame(
                    maxWidth: .infinity,
                    minHeight: AppControlMetrics.minimumTouchTarget
                )
                .disabled(password.count < 8 || isBusy)
                .accessibilityIdentifier("account-deletion.email")
            }
        }
    }

    private var unavailableIdentityCard: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .foregroundStyle(Color.appSecondaryText)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(
                    String(
                        localized:
                            "account_deletion.identity.unavailable.title",
                        defaultValue: "Metode masuk belum tersedia"
                    )
                )
                .font(AppTypography.cardTitle)
                .foregroundStyle(Color.appPrimaryText)

                Text(
                    String(
                        localized:
                            "account_deletion.identity.unavailable.message",
                        defaultValue:
                            "Tutup layar ini, masuk ulang, lalu coba hapus akun kembali."
                    )
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
            }
        }
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.appSecondaryBackground,
            in: RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
        )
    }

    private func errorCard(message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(AppTypography.body)
            .foregroundStyle(Color.appDestructive)
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.appDestructive.opacity(0.10),
                in: RoundedRectangle(
                    cornerRadius: AppRadius.large,
                    style: .continuous
                )
            )
            .accessibilityIdentifier("account-deletion.error")
    }

    private var progressStatus: some View {
        HStack(spacing: AppSpacing.small) {
            ProgressView()

            Text(
                isDeleting
                    ? String(
                        localized: "account_deletion.progress",
                        defaultValue: "Menghapus akun…"
                    )
                    : String(
                        localized: "account_deletion.verify.progress",
                        defaultValue: "Memverifikasi akun…"
                    )
            )
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityIdentifier("account-deletion.progress")
    }

    private func providerConnectionTitle(
        _ provider: AuthenticationProvider
    ) -> String {
        switch provider {
        case .apple:
            String(
                localized: "account_deletion.identity.apple",
                defaultValue: "Terhubung dengan Apple"
            )
        case .google:
            String(
                localized: "account_deletion.identity.google",
                defaultValue: "Terhubung dengan Google"
            )
        case .email:
            String(
                localized: "account_deletion.identity.email",
                defaultValue: "Terhubung dengan email"
            )
        }
    }

    private func verify(
        using reauthentication: AccountReauthentication
    ) {
        Task {
            await verifyAccount(using: reauthentication)
        }
    }

    private func verifyAccount(
        using reauthentication: AccountReauthentication
    ) async {
        guard let repository = environment.repositories?.authentication else {
            errorMessage = String(
                localized: "account_deletion.error.configuration",
                defaultValue:
                    "Layanan akun belum tersedia. Coba lagi nanti."
            )
            return
        }

        isVerifying = true
        errorMessage = nil
        defer {
            isVerifying = false
        }

        do {
            try await repository.reauthenticateForAccountDeletion(
                reauthentication
            )
            password = ""
            isConfirmationPresented = true
        } catch {
            errorMessage = mappedMessage(for: error)
        }
    }

    private func deleteAccount() async {
        guard let repository = environment.repositories?.authentication else {
            errorMessage = String(
                localized: "account_deletion.error.configuration",
                defaultValue:
                    "Layanan akun belum tersedia. Coba lagi nanti."
            )
            return
        }

        isDeleting = true
        errorMessage = nil
        defer {
            isDeleting = false
        }

        do {
            try await repository.deleteAccountAfterReauthentication()
            dismiss()
        } catch {
            errorMessage = mappedMessage(for: error)
        }
    }

    private func mappedMessage(for error: Error) -> String {
        guard let authenticationError = error as? AuthenticationError else {
            return String(
                localized: "account_deletion.error.generic",
                defaultValue:
                    "Akun belum dapat dihapus. Coba lagi."
            )
        }
        switch authenticationError {
        case .invalidCredential:
            return String(
                localized: "account_deletion.error.credential",
                defaultValue:
                    "Autentikasi ulang gagal. Periksa metode masukmu."
            )
        case .recentReauthenticationRequired:
            return String(
                localized: "account_deletion.error.reauthentication",
                defaultValue:
                    "Autentikasi ulang sudah kedaluwarsa. Coba lagi."
            )
        case .accountDeletionNotAllowed:
            return String(
                localized: "account_deletion.error.not_allowed",
                defaultValue:
                    "Akun ini tidak dapat dihapus dari aplikasi."
            )
        case .accountRelationshipsRequireTransfer:
            return String(
                localized: "account_deletion.error.transfer",
                defaultValue:
                    "Hubungan program harus dialihkan oleh Admin sebelum akun dapat dihapus."
            )
        case .offline:
            return String(
                localized: "auth.error.offline",
                defaultValue:
                    "Tidak ada koneksi. Periksa jaringan lalu coba lagi."
            )
        case .timeout:
            return String(
                localized: "auth.error.timeout",
                defaultValue: "Koneksi terlalu lama. Coba lagi."
            )
        case .cancelled:
            return String(
                localized: "auth.provider.cancelled",
                defaultValue: "Proses masuk dibatalkan."
            )
        case .providerUnavailable:
            return String(
                localized: "auth.provider.error",
                defaultValue:
                    "Penyedia akun belum dapat digunakan. Coba lagi."
            )
        default:
            return String(
                localized: "account_deletion.error.generic",
                defaultValue:
                    "Akun belum dapat dihapus. Coba lagi."
            )
        }
    }
}

#Preview("Hapus akun Google") {
    AccountDeletionView(
        user: AppUser(
            id: UUID(),
            email: "peserta@example.com",
            displayName: "Peserta",
            role: .participant,
            hasCompletedOnboarding: true,
            isCoachApprovalPending: false,
            authenticationProviders: [.google],
            createdAt: .now
        )
    )
    .environment(\.appEnvironment, .preview)
    .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Hapus akun Apple · Teks besar") {
    AccountDeletionView(
        user: AppUser(
            id: UUID(),
            email: "contoh@privaterelay.appleid.com",
            displayName: "Peserta",
            role: .participant,
            hasCompletedOnboarding: true,
            isCoachApprovalPending: false,
            authenticationProviders: [.apple],
            createdAt: .now
        )
    )
    .environment(\.appEnvironment, .preview)
    .environment(\.locale, Locale(identifier: "id-ID"))
    .environment(\.dynamicTypeSize, .accessibility2)
    .preferredColorScheme(.dark)
}
