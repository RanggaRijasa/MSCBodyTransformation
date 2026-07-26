import Foundation

nonisolated struct WeighInValidator: Sendable {
    func validate(weightKilograms: Decimal) throws {
        guard weightKilograms > 0 else {
            throw DomainError.validation(
                field: "weightKilograms",
                reason: "Berat badan harus lebih dari nol."
            )
        }
    }
}

nonisolated struct StepSubmissionValidator: Sendable {
    func validate(
        step: ProgramStep,
        evidence: [SubmissionEvidence]
    ) throws {
        for requirement in step.requirements where requirement.isRequired {
            switch requirement.kind {
            case .photoEvidence:
                guard evidence.contains(where: {
                    $0.kind == .photo && $0.localReference?.isEmpty == false
                }) else {
                    throw DomainError.validation(
                        field: "photoEvidence",
                        reason: "Bukti foto wajib ditambahkan."
                    )
                }
            case .textAnswer:
                guard evidence.contains(where: {
                    $0.kind == .text
                        && $0.textValue?
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty == false
                }) else {
                    throw DomainError.validation(
                        field: "textAnswer",
                        reason: "Jawaban wajib diisi."
                    )
                }
            }
        }
    }
}
