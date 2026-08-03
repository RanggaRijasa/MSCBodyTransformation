import Foundation

nonisolated struct AdminDraftContentDuplicator {
    func duplicatedStep(
        _ source: AdminStepDraft,
        id: UUID,
        order: Int,
        title: String? = nil
    ) -> AdminStepDraft {
        AdminStepDraft(
            id: id,
            order: order,
            title: title ?? source.title,
            instructions: source.instructions,
            mediaKind: source.mediaKind,
            localMediaReference: source.localMediaReference,
            isActive: source.isActive,
            verificationMode: source.verificationMode,
            contentKind: source.contentKind,
            isVideoRequiredToWatch: source.isVideoRequiredToWatch,
            isVideoAutoplayEnabled: source.isVideoAutoplayEnabled,
            quiz: duplicatedQuestionGroup(source.quiz, stepID: id),
            publishedContent: nil
        )
    }

    private func duplicatedQuestionGroup(
        _ source: AdminQuizDraft?,
        stepID: UUID
    ) -> AdminQuizDraft? {
        guard let source else { return nil }
        return AdminQuizDraft(
            title: source.title,
            questions: source.questions.enumerated().map {
                index, question in
                let questionID =
                    AdminProgramDraftValidator().childIdentifier(
                        parent: stepID,
                        discriminator: index + 1_000
                    )
                let optionIDs = question.options.indices.map { optionIndex in
                    AdminProgramDraftValidator().childIdentifier(
                        parent: questionID,
                        discriminator: optionIndex + 1
                    )
                }
                let optionMap = Dictionary(
                    uniqueKeysWithValues: zip(question.optionIDs, optionIDs)
                )
                return AdminQuizQuestionDraft(
                    id: questionID,
                    order: index + 1,
                    kind: question.kind,
                    prompt: question.prompt,
                    options: question.options,
                    optionIDs: optionIDs,
                    optionMediaReferences:
                        question.optionMediaReferences,
                    answerKey: question.answerKey.map {
                        ProgramQuestionAnswerKey(
                            acceptedTextValues: $0.acceptedTextValues,
                            numberValue: $0.numberValue,
                            selectedOptionIDs:
                                $0.selectedOptionIDs.compactMap {
                                    optionMap[$0]
                                },
                            matchingMode: $0.matchingMode
                        )
                    }
                )
            }
        )
    }
}

nonisolated struct AdminDayContentCopyService {
    private let firstCopyDiscriminator = 10_000

    func callAsFunction(
        draft: AdminProgramDraft,
        sourceDayID: UUID,
        targetDayIDs: Set<UUID>
    ) throws -> AdminProgramDraft {
        guard let sourceDay = draft.days.first(where: {
            $0.id == sourceDayID
        }) else {
            throw DomainError.notFound(resource: "Hari sumber")
        }

        let targets = targetDayIDs.subtracting([sourceDayID])
        guard !targets.isEmpty else {
            throw DomainError.validation(
                field: "targetDayIDs",
                reason: "Pilih minimal satu hari tujuan."
            )
        }

        let availableDayIDs = Set(draft.days.map(\.id))
        guard targets.isSubset(of: availableDayIDs) else {
            throw DomainError.notFound(resource: "Hari tujuan")
        }

        var result = draft
        var usedStepIDs = Set(draft.days.flatMap(\.steps).map(\.id))
        let duplicator = AdminDraftContentDuplicator()

        for dayIndex in result.days.indices
        where targets.contains(result.days[dayIndex].id) {
            let targetDayID = result.days[dayIndex].id
            var copiedSteps: [AdminStepDraft] = []

            for (stepIndex, sourceStep) in sourceDay.steps.enumerated() {
                let stepID = availableIdentifier(
                    parent: targetDayID,
                    startingAt: firstCopyDiscriminator + stepIndex,
                    excluding: usedStepIDs
                )
                usedStepIDs.insert(stepID)
                copiedSteps.append(
                    duplicator.duplicatedStep(
                        sourceStep,
                        id: stepID,
                        order: stepIndex + 1
                    )
                )
            }

            result.days[dayIndex].summary = sourceDay.summary
            result.days[dayIndex].steps = copiedSteps
        }

        return AdminProgramDraftValidator().normalized(result)
    }

    private func availableIdentifier(
        parent: UUID,
        startingAt value: Int,
        excluding identifiers: Set<UUID>
    ) -> UUID {
        var discriminator = value
        while true {
            let identifier = AdminProgramDraftValidator().childIdentifier(
                parent: parent,
                discriminator: discriminator
            )
            if !identifiers.contains(identifier) {
                return identifier
            }
            discriminator += 1
        }
    }
}
