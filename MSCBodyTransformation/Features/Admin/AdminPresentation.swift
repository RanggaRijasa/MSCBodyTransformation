import Foundation

nonisolated extension ProgramStatus {
    var adminTitle: String {
        switch self {
        case .draft: "Draft"
        case .scheduled: "Terjadwal"
        case .active: "Aktif"
        case .completed: "Selesai"
        case .archived: "Diarsipkan"
        }
    }
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
        case .locked: "Terkunci"
        case .hidden: "Disembunyikan"
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
        case .inviteRedeemed: "Undangan digunakan"
        case .programPublished: "Program dipublikasikan"
        case .programArchived: "Program diarsipkan"
        case .coachApproved: "Coach disetujui"
        case .coachVisibilityChanged: "Visibilitas Coach diubah"
        case .participantEnrolled: "Peserta didaftarkan"
        case .managedContentUpdated: "Konten diperbarui"
        case .winnersLocked: "Pemenang dikunci"
        }
    }
}

nonisolated extension AdminProgramEditorState.Stage {
    var title: String {
        switch self {
        case .basics: "Dasar"
        case .dates: "Tanggal"
        case .scoring: "Skor"
        case .days: "Hari"
        case .steps: "Langkah"
        case .preview: "Pratinjau"
        case .publish: "Publikasi"
        }
    }
}
