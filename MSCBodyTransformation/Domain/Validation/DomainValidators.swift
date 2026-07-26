import Foundation

nonisolated struct WeighInValidator: Sendable {
    static let minimumWeightKilograms = Decimal(25)
    static let maximumWeightKilograms = Decimal(350)

    func validate(weightKilograms: Decimal) throws {
        guard weightKilograms >= Self.minimumWeightKilograms,
              weightKilograms <= Self.maximumWeightKilograms else {
            throw DomainError.validation(
                field: "weightKilograms",
                reason: "Masukkan berat badan antara 25 kg dan 350 kg."
            )
        }
    }
}

nonisolated struct WeighInWindowValidator: Sendable {
    func validate(
        type: WeighInType,
        now: Date,
        program: Program
    ) throws {
        guard type == .final else {
            return
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(identifier: program.timeZoneIdentifier) ?? .gmt
        let finalDay = program.days.max(by: {
            $0.dayNumber < $1.dayNumber
        })?.scheduledDate ?? program.endDate

        guard calendar.compare(
            now,
            to: finalDay,
            toGranularity: .day
        ) != .orderedAscending else {
            throw DomainError.validation(
                field: "weightKilograms",
                reason: "Berat badan akhir baru dapat dikirim pada hari terakhir program."
            )
        }
    }
}

nonisolated struct IndonesianWeightInputParser: Sendable {
    func parse(_ input: String) throws -> Decimal {
        let normalized = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Decimal(
            string: normalized,
            locale: Locale(identifier: "en_US_POSIX")
        ) else {
            throw DomainError.validation(
                field: "weightKilograms",
                reason: "Gunakan angka berat badan yang valid, misalnya 78,5."
            )
        }
        return value
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
