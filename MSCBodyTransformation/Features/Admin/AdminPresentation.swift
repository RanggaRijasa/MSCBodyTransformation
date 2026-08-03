import Foundation

nonisolated extension ProgramStatus {
    var adminTitle: String {
        switch self {
        case .draft: "Draft"
        case .preparingCommerce: "Menyiapkan pembayaran"
        case .scheduled: "Terjadwal"
        case .active: "Aktif"
        case .completed: "Selesai"
        case .archived: "Diarsipkan"
        }
    }
}

nonisolated enum AdminProgramStage: Int, CaseIterable, Sendable {
    case settings = 1
    case content = 2
    case review = 3
}

nonisolated struct AdminProgramFlowProgress: Equatable, Sendable {
    let issues: [AdminValidationIssue]

    func isComplete(_ stage: AdminProgramStage) -> Bool {
        switch stage {
        case .settings:
            issues.allSatisfy { !Self.settingsFields.contains($0.field) }
        case .content:
            issues.allSatisfy { !Self.contentFields.contains($0.field) }
        case .review:
            issues.isEmpty
        }
    }

    var completedStageCount: Int {
        AdminProgramStage.allCases.filter(isComplete).count
    }

    func issueCount(for stage: AdminProgramStage) -> Int {
        switch stage {
        case .settings:
            issues.count { Self.settingsFields.contains($0.field) }
        case .content:
            issues.count { Self.contentFields.contains($0.field) }
        case .review:
            issues.count
        }
    }

    private static let settingsFields: Set<AdminValidationField> = [
        .title,
        .cover,
        .dates,
        .timeZone,
        .scoring,
        .participantLimit
    ]

    private static let contentFields: Set<AdminValidationField> = [
        .days,
        .dayNumbers,
        .dayDates,
        .steps,
        .stepOrder,
        .media,
        .content
    ]
}

nonisolated extension SubmissionVerificationMode {
    var adminTitle: String {
        switch self {
        case .automatic: "Otomatis"
        case .coachReview: "Pemeriksaan Coach"
        }
    }
}

nonisolated extension PastStepPolicy {
    var adminTitle: String {
        switch self {
        case .available: "Tetap tersedia"
        case .readOnly: "Hanya baca"
        case .hidden: "Disembunyikan"
        }
    }
}

nonisolated extension FutureStepPolicy {
    var adminTitle: String {
        switch self {
        case .available: "Tersedia lebih awal"
        case .locked: "Terkunci"
        case .hidden: "Disembunyikan"
        }
    }
}

nonisolated extension AdminProgramPace {
    var adminTitle: String {
        switch self {
        case .selfPaced: "Mandiri"
        case .scheduled: "Terjadwal"
        }
    }
}

nonisolated extension AdminProgramDurationMode {
    var adminTitle: String {
        switch self {
        case .fixedDuration: "Durasi tetap"
        case .specificDates: "Tanggal tertentu"
        }
    }
}

nonisolated extension AdminStepContentKind {
    var adminTitle: String {
        switch self {
        case .article: "Artikel"
        case .video: "Video"
        case .form: "Form"
        case .quiz: "Kuis"
        case .initialWeighIn: "Timbang awal"
        case .dailyWeighIn: "Timbang harian"
        case .finalWeighIn: "Timbang akhir"
        }
    }

    var systemImage: String {
        switch self {
        case .article: "doc.text"
        case .video: "video"
        case .form: "list.clipboard"
        case .quiz: "checklist"
        case .initialWeighIn: "scalemass"
        case .dailyWeighIn: "scalemass"
        case .finalWeighIn: "scalemass.fill"
        }
    }
}

nonisolated extension AdminQuizQuestionKind {
    var adminTitle: String {
        switch self {
        case .shortAnswer: "Jawaban singkat"
        case .longAnswer: "Jawaban panjang"
        case .number: "Angka"
        case .singleChoice: "Pilihan tunggal"
        case .multipleChoice: "Pilihan ganda"
        case .imageChoice: "Pilihan gambar"
        case .photoUpload: "Unggah foto"
        case .heading: "Judul bagian"
        case .text: "Teks penjelas"
        }
    }

    var systemImage: String {
        switch self {
        case .shortAnswer: "text.cursor"
        case .longAnswer: "text.alignleft"
        case .number: "number"
        case .singleChoice: "circle"
        case .multipleChoice: "checklist"
        case .imageChoice: "photo.on.rectangle"
        case .photoUpload: "camera"
        case .heading: "textformat.size.larger"
        case .text: "text.justify.left"
        }
    }

}

nonisolated extension StepInstructionMediaKind {
    var adminTitle: String {
        switch self {
        case .image: "Gambar"
        case .video: "Video"
        }
    }
}

nonisolated extension UserRole {
    var adminTitle: String {
        switch self {
        case .participant: "Peserta"
        case .coach: "Coach"
        case .admin: "Admin"
        }
    }
}

nonisolated extension AuditEventKind {
    var adminTitle: String {
        switch self {
        case .programCreated: "Draft dibuat"
        case .programUpdated: "Draft diperbarui"
        case .submissionReviewed: "Bukti diperiksa"
        case .scoreAdjusted: "Poin disesuaikan"
        case .programPublished: "Program dipublikasikan"
        case .programArchived: "Program diarsipkan"
        case .coachApproved: "Coach disetujui"
        case .coachVisibilityChanged: "Visibilitas Coach diubah"
        case .coachTransferred: "Coach peserta diubah"
        case .participantEnrolled: "Peserta didaftarkan"
        case .managedContentUpdated: "Konten diperbarui"
        case .winnersLocked: "Pemenang dikunci"
        case .quizAttemptReopened: "Percobaan kuis dibuka"
        case .weighInCorrected: "Timbang dikoreksi"
        }
    }
}
