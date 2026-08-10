import SwiftUI

enum LegalDocumentKind: Sendable {
    case privacy
    case terms

    var title: String {
        switch self {
        case .privacy:
            String(
                localized: "participant.legal.privacy.title",
                defaultValue: "Privasi"
            )
        case .terms:
            String(
                localized: "participant.legal.terms.title",
                defaultValue: "Ketentuan penggunaan"
            )
        }
    }

    var systemImage: String {
        switch self {
        case .privacy: "hand.raised"
        case .terms: "doc.text"
        }
    }

    fileprivate var bundleURLKey: String {
        switch self {
        case .privacy: AppConfiguration.privacyPolicyURLEnvironmentKey
        case .terms: AppConfiguration.termsOfUseURLEnvironmentKey
        }
    }

    fileprivate var sections: [LegalDocumentSection] {
        switch self {
        case .privacy: LegalDocumentContent.privacySections
        case .terms: LegalDocumentContent.termsSections
        }
    }
}

struct LegalDocumentView: View {
    let kind: LegalDocumentKind

    private var publicURL: URL? {
        guard let rawValue = Bundle.main.object(
            forInfoDictionaryKey: kind.bundleURLKey
        ) as? String,
              let url = URL(string: rawValue),
              url.scheme?.lowercased() == "https",
              url.host != nil else {
            return nil
        }
        return url
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                Label(kind.title, systemImage: kind.systemImage)
                    .font(AppTypography.screenTitle)
                    .foregroundStyle(Color.appPrimaryText)

                Text(
                    String(
                        localized: "legal.document.updated",
                        defaultValue: "Diperbarui 9 Agustus 2026"
                    )
                )
                .font(AppTypography.label)
                .foregroundStyle(Color.appSecondaryText)

                ForEach(kind.sections) { section in
                    VStack(
                        alignment: .leading,
                        spacing: AppSpacing.small
                    ) {
                        Text(section.title)
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(Color.appPrimaryText)
                        Text(section.body)
                            .font(AppTypography.body)
                            .foregroundStyle(Color.appSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let publicURL {
                    Link(destination: publicURL) {
                        Label(
                            String(
                                localized: "legal.document.open_online",
                                defaultValue: "Buka versi daring"
                            ),
                            systemImage: "arrow.up.right.square"
                        )
                        .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("legal.open-online")
                }

                Text(
                    String(
                        localized: "legal.document.bundled_notice",
                        defaultValue: "Salinan ini tersedia di aplikasi agar tetap dapat dibaca saat koneksi bermasalah."
                    )
                )
                .font(AppTypography.label)
                .foregroundStyle(Color.appSecondaryText)
            }
            .padding(AppSpacing.large)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground)
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(
            kind == .privacy ? "legal.privacy" : "legal.terms"
        )
    }
}

private struct LegalDocumentSection: Identifiable, Sendable {
    let id: String
    let title: String
    let body: String
}

private enum LegalDocumentContent {
    static let privacySections = [
        section(
            id: "privacy.scope",
            titleKey: "legal.privacy.scope.title",
            titleDefault: "Data yang diproses",
            bodyKey: "legal.privacy.scope.body",
            bodyDefault: "Kami memproses nama, email, nomor HP, ID akun, peran, profil, keikutsertaan program, jawaban, berat badan, foto atau video bukti, skor, riwayat pembelian, serta data operasional yang diperlukan untuk menjalankan layanan."
        ),
        section(
            id: "privacy.purpose",
            titleKey: "legal.privacy.purpose.title",
            titleDefault: "Tujuan penggunaan",
            bodyKey: "legal.privacy.purpose.body",
            bodyDefault: "Data digunakan untuk autentikasi, membuat profil, menghubungkan Participant dengan Coach, menjalankan program, menilai kiriman, menghitung skor, menampilkan peringkat, memproses akses berbayar, mencegah penyalahgunaan, dan memenuhi kewajiban keamanan."
        ),
        section(
            id: "privacy.providers",
            titleKey: "legal.privacy.providers.title",
            titleDefault: "Penyedia layanan",
            bodyKey: "legal.privacy.providers.body",
            bodyDefault: "Autentikasi dapat melibatkan Google atau Apple. Data aplikasi disimpan melalui Supabase. Pembelian diproses oleh Apple melalui StoreKit. MSC Body Transformation tidak menerima nomor kartu atau detail rekening pembayaran Anda."
        ),
        section(
            id: "privacy.media",
            titleKey: "legal.privacy.media.title",
            titleDefault: "Foto, video, dan data wellness",
            bodyKey: "legal.privacy.media.body",
            bodyDefault: "Foto atau video bukti dan berat badan merupakan data pribadi yang sensitif. Media diproses untuk kebutuhan program, metadata yang tidak diperlukan dihapus sebelum unggah, dan akses dibatasi sesuai peran. Aplikasi ini tidak memberikan diagnosis atau saran medis."
        ),
        section(
            id: "privacy.retention",
            titleKey: "legal.privacy.retention.title",
            titleDefault: "Penyimpanan dan penghapusan",
            bodyKey: "legal.privacy.retention.body",
            bodyDefault: "Data disimpan selama akun atau kewajiban program, keamanan, audit, dan transaksi masih memerlukannya. Saat akun dihapus, akses dicabut dan data pribadi serta media dihapus. Catatan pemenang, audit, atau transaksi yang wajib dipertahankan dapat disimpan tanpa identitas pribadi."
        ),
        section(
            id: "privacy.tracking",
            titleKey: "legal.privacy.tracking.title",
            titleDefault: "Pelacakan dan iklan",
            bodyKey: "legal.privacy.tracking.body",
            bodyDefault: "Aplikasi tidak menggunakan data untuk pelacakan lintas aplikasi atau situs dan tidak menjual data pribadi untuk periklanan."
        ),
        section(
            id: "privacy.control",
            titleKey: "legal.privacy.control.title",
            titleDefault: "Kontrol Anda",
            bodyKey: "legal.privacy.control.body",
            bodyDefault: "Anda dapat memperbarui profil, keluar, atau meminta penghapusan akun dari layar Profil. Pertanyaan privasi dapat dikirim melalui kanal dukungan yang tercantum pada halaman aplikasi di App Store."
        )
    ]

    static let termsSections = [
        section(
            id: "terms.service",
            titleKey: "legal.terms.service.title",
            titleDefault: "Penggunaan layanan",
            bodyKey: "legal.terms.service.body",
            bodyDefault: "Gunakan aplikasi secara jujur, aman, dan sesuai program. Anda bertanggung jawab atas ketepatan data, jawaban, berat badan, dan media yang dikirim serta dilarang mengunggah konten milik orang lain tanpa izin."
        ),
        section(
            id: "terms.wellness",
            titleKey: "legal.terms.wellness.title",
            titleDefault: "Informasi wellness",
            bodyKey: "legal.terms.wellness.body",
            bodyDefault: "Program berfokus pada kebiasaan dan wellness, bukan layanan medis, diagnosis, atau pengganti konsultasi profesional. Hentikan aktivitas dan cari bantuan profesional bila Anda merasa tidak aman atau mengalami keluhan kesehatan."
        ),
        section(
            id: "terms.enrollment",
            titleKey: "legal.terms.enrollment.title",
            titleDefault: "Program dan Coach",
            bodyKey: "legal.terms.enrollment.body",
            bodyDefault: "Pendaftaran Participant memerlukan QR Coach yang aktif. Kapasitas, jadwal, cutoff, langkah, bukti, penilaian, dan aturan skor mengikuti program yang dipublikasikan. Akses Coach berlaku tiga bulan setelah pembayaran terverifikasi dan menjadi nonaktif saat masa akses berakhir."
        ),
        section(
            id: "terms.purchase",
            titleKey: "legal.terms.purchase.title",
            titleDefault: "Pembelian dan pengembalian dana",
            bodyKey: "legal.terms.purchase.body",
            bodyDefault: "Program berbayar dan akses Coach dibeli melalui Apple. Tidak tersedia pengembalian dana sukarela setelah pembelian. Hak pengembalian dana, pembatalan, atau pencabutan oleh Apple tetap berlaku dan dapat menyebabkan akses terkait dihentikan."
        ),
        section(
            id: "terms.coach",
            titleKey: "legal.terms.coach.title",
            titleDefault: "Pengajuan Coach",
            bodyKey: "legal.terms.coach.body",
            bodyDefault: "Pengajuan Coach pertama harus memenuhi kelayakan dan diterima Admin sebelum pembayaran. Renewal dilakukan manual dan tidak memerlukan persetujuan ulang selama approval belum dicabut. Coach dengan Participant aktif tidak dapat menghapus akun sebelum pengalihan diselesaikan oleh Admin."
        ),
        section(
            id: "terms.ranking",
            titleKey: "legal.terms.ranking.title",
            titleDefault: "Peringkat dan pemenang",
            bodyKey: "legal.terms.ranking.body",
            bodyDefault: "Skor authoritative dihitung server dari kiriman yang disetujui, berat badan, dan penyesuaian yang teraudit. Keputusan pemenang mengikuti snapshot final yang dikunci Admin. Jika hadiah diumumkan untuk suatu program, syarat hadiah tersebut akan dicantumkan pada detail program."
        ),
        section(
            id: "terms.account",
            titleKey: "legal.terms.account.title",
            titleDefault: "Akun dan penegakan",
            bodyKey: "legal.terms.account.body",
            bodyDefault: "Jaga keamanan akun dan jangan membagikan akses. Kami dapat membatasi akun atau kiriman yang melanggar aturan, memalsukan bukti, menyalahgunakan pembayaran, mengganggu layanan, atau membahayakan pengguna lain."
        ),
        section(
            id: "terms.changes",
            titleKey: "legal.terms.changes.title",
            titleDefault: "Perubahan ketentuan",
            bodyKey: "legal.terms.changes.body",
            bodyDefault: "Perubahan penting akan dicantumkan pada versi terbaru dokumen. Penggunaan layanan setelah perubahan berlaku berarti Anda menerima ketentuan terbaru."
        )
    ]

    private static func section(
        id: String,
        titleKey: StaticString,
        titleDefault: String.LocalizationValue,
        bodyKey: StaticString,
        bodyDefault: String.LocalizationValue
    ) -> LegalDocumentSection {
        LegalDocumentSection(
            id: id,
            title: String(localized: titleKey, defaultValue: titleDefault),
            body: String(localized: bodyKey, defaultValue: bodyDefault)
        )
    }
}
