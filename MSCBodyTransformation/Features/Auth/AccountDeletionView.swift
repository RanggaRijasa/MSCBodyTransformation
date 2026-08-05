import SwiftUI

@MainActor
struct AccountDeletionView: View {
    let email: String

    @Environment(\.appEnvironment) private var environment
    @Environment(\.dismiss) private var dismiss

    @State private var password = ""
    @State private var pendingMethod: PendingDeletionMethod?
    @State private var isConfirmationPresented = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                consequencesSection
                reauthenticationSection

                if let errorMessage {
                    Section {
                        Label(
                            errorMessage,
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(Color.appDestructive)
                        .accessibilityIdentifier(
                            "account-deletion.error"
                        )
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle(
                Text(
                    String(
                        localized: "account_deletion.title",
                        defaultValue: "Hapus akun"
                    )
                )
            )
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
                    .disabled(isDeleting)
                }
            }
            .interactiveDismissDisabled(isDeleting)
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
                    guard let pendingMethod else {
                        return
                    }
                    Task {
                        await deleteAccount(using: pendingMethod)
                    }
                }
                Button(
                    String(
                        localized: "action.cancel",
                        defaultValue: "Batal"
                    ),
                    role: .cancel
                ) {
                    pendingMethod = nil
                }
            } message: {
                Text(
                    String(
                        localized: "account_deletion.confirmation.message",
                        defaultValue:
                            "Tindakan ini tidak dapat dibatalkan. Autentikasi ulang akan dilakukan sebelum akun dihapus."
                    )
                )
            }
        }
        .accessibilityIdentifier("account-deletion")
    }

    private var consequencesSection: some View {
        Section {
            Label(
                String(
                    localized: "account_deletion.immediate",
                    defaultValue:
                        "Akses akun akan dicabut segera setelah autentikasi ulang berhasil."
                ),
                systemImage: "person.crop.circle.badge.xmark"
            )
            Label(
                String(
                    localized: "account_deletion.personal_data",
                    defaultValue:
                        "Profil, keikutsertaan program, kiriman, skor, dan media pribadi akan dihapus."
                ),
                systemImage: "trash"
            )
            Label(
                String(
                    localized: "account_deletion.winner_snapshot",
                    defaultValue:
                        "Catatan pemenang yang sudah dikunci tetap tersimpan tanpa identitas akun."
                ),
                systemImage: "trophy"
            )
            Label(
                String(
                    localized: "account_deletion.coach_transfer",
                    defaultValue:
                        "Akun Coach dengan peserta aktif harus dialihkan oleh Admin terlebih dahulu."
                ),
                systemImage: "person.2"
            )
        } header: {
            Text(
                String(
                    localized: "account_deletion.consequences",
                    defaultValue: "Dampak penghapusan"
                )
            )
        } footer: {
            Text(
                String(
                    localized: "account_deletion.irreversible",
                    defaultValue:
                        "Penghapusan permanen dan tidak dapat dibatalkan."
                )
            )
        }
    }

    private var reauthenticationSection: some View {
        Section {
            Text(email)
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
                .textSelection(.enabled)

            SecureField(
                String(
                    localized: "auth.field.password",
                    defaultValue: "Password"
                ),
                text: $password
            )
            .textContentType(.password)
            .accessibilityIdentifier("account-deletion.password")

            Button(
                String(
                    localized: "account_deletion.email.action",
                    defaultValue: "Autentikasi ulang dan hapus"
                ),
                role: .destructive
            ) {
                pendingMethod = .email
                isConfirmationPresented = true
            }
            .disabled(password.count < 8 || isDeleting)
            .accessibilityIdentifier("account-deletion.email")

            AuthenticationAppleButton {
                pendingMethod = .provider(.apple)
                isConfirmationPresented = true
            }
            .disabled(isDeleting)
            .accessibilityIdentifier("account-deletion.apple")

            OfficialGoogleSignInButton {
                pendingMethod = .provider(.google)
                isConfirmationPresented = true
            }
            .disabled(isDeleting)
            .accessibilityIdentifier("account-deletion.google")

            if isDeleting {
                HStack(spacing: AppSpacing.small) {
                    ProgressView()
                    Text(
                        String(
                            localized: "account_deletion.progress",
                            defaultValue: "Menghapus akun…"
                        )
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("account-deletion.progress")
            }
        } header: {
            Text(
                String(
                    localized: "account_deletion.reauthenticate",
                    defaultValue: "Autentikasi ulang"
                )
            )
        } footer: {
            Text(
                String(
                    localized: "account_deletion.reauthenticate.help",
                    defaultValue:
                        "Gunakan metode masuk yang terhubung ke akun ini."
                )
            )
        }
    }

    private func deleteAccount(
        using method: PendingDeletionMethod
    ) async {
        guard let repository = environment.repositories?.authentication else {
            errorMessage = String(
                localized: "account_deletion.error.configuration",
                defaultValue:
                    "Layanan akun belum tersedia. Coba lagi nanti."
            )
            pendingMethod = nil
            return
        }

        isDeleting = true
        errorMessage = nil
        defer {
            isDeleting = false
            pendingMethod = nil
        }

        do {
            switch method {
            case .email:
                try await repository.deleteAccount(
                    reauthentication: .email(
                        email: email,
                        password: password
                    )
                )
            case .provider(let provider):
                try await repository.deleteAccount(
                    reauthentication: .provider(provider)
                )
            }
            password = ""
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

private enum PendingDeletionMethod {
    case email
    case provider(AuthenticationProvider)
}

#Preview("Hapus akun") {
    AccountDeletionView(email: "peserta@example.com")
        .environment(\.appEnvironment, .preview)
        .environment(\.locale, Locale(identifier: "id-ID"))
}
