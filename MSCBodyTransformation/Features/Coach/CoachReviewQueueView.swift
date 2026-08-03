import SwiftUI
import UIKit

@MainActor
struct CoachReviewQueueView: View {
    let features: CoachFeatureContainer

    @State private var presentedSheet: CoachReviewSheetDestination?
    @State private var scope: CoachEvidenceScope = .needsAction
    @State private var filterSelection = CoachEvidenceFilterSelection.all

    private var state: CoachReviewQueueState {
        features.reviewQueue
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
            case .loaded(let items):
                evidenceHub(items)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationTitle(Text("coach.review.title"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            if state.state == .idle {
                await state.load()
            }
        }
        .sheet(item: $presentedSheet) { destination in
            switch destination {
            case .detail(let item):
                CoachReviewDetailSheet(
                    item: item,
                    features: features
                )
            case .filters(let programs):
                CoachEvidenceFilterSheet(
                    programs: programs,
                    selection: filterSelection,
                    referenceDate: state.referenceDate
                ) { selection in
                    filterSelection = selection
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("coach.review.queue")
    }

    private func evidenceHub(_ items: [CoachReviewItem]) -> some View {
        VStack(spacing: 0) {
            fixedEvidenceControls(items)
            evidenceList(items)
        }
    }

    private func fixedEvidenceControls(
        _ items: [CoachReviewItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Picker("coach.review.scope.accessibility", selection: $scope) {
                ForEach(CoachEvidenceScope.allCases) { option in
                    if option == .needsAction {
                        Text(
                            "Perlu tindakan (\(pendingCount(in: items), format: .number.locale(CoachFormatting.locale)))"
                        )
                        .tag(option)
                    } else {
                        Text(option.titleKey)
                            .tag(option)
                    }
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)
            .frame(
                maxWidth: .infinity,
                minHeight: CoachReviewLayout.scopeControlHeight
            )
            .accessibilityIdentifier("coach.review.scope")

            filters(for: items)
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.small)
        .padding(.bottom, AppSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appBackground)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("coach.review.fixed-controls")
    }

    private func evidenceList(_ items: [CoachReviewItem]) -> some View {
        let visibleItems = filteredItems(from: items)

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.medium) {
                if visibleItems.isEmpty {
                    Group {
                        if scope == .needsAction {
                            ContentUnavailableView(
                                "coach.review.empty.action.title",
                                systemImage: "checkmark.circle",
                                description: Text(
                                    "coach.review.empty.action.message"
                                )
                            )
                        } else {
                            ContentUnavailableView(
                                "coach.review.empty.all.title",
                                systemImage: "photo.on.rectangle.angled",
                                description: Text(
                                    "coach.review.empty.all.message"
                                )
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xLarge)
                } else {
                    ForEach(visibleItems) { item in
                        Button {
                            presentedSheet = .detail(item)
                        } label: {
                            CoachEvidenceRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(
                            "coach.review.open.\(item.id)"
                        )
                    }
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.top, AppSpacing.xSmall)
            .padding(.bottom, AppSpacing.large)
        }
        .refreshable {
            await state.load()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("coach.review.evidence-list")
    }

    private func filters(
        for items: [CoachReviewItem]
    ) -> some View {
        FilterSummaryButton(
            title: "coach.review.filter.title",
            summary: filterSummary(in: items),
            identifier: "coach.review.filter.open"
        ) {
            presentedSheet = .filters(programs(in: items))
        }
        .accessibilityHint(Text("coach.review.filter.open_hint"))
    }

    private func filteredItems(
        from items: [CoachReviewItem]
    ) -> [CoachReviewItem] {
        items.filter { item in
            let matchesScope = scope == .all || item.needsCoachAction
            let matchesProgram = filterSelection.programID == nil
                || item.program.id == filterSelection.programID
            let matchesStatus = filterSelection.status.matches(item)
            let matchesRating = filterSelection.rating.matches(item)
            return matchesScope
                && matchesProgram
                && matchesStatus
                && matchesRating
        }
    }

    private func pendingCount(in items: [CoachReviewItem]) -> Int {
        items.filter(\.needsCoachAction).count
    }

    private func programs(in items: [CoachReviewItem]) -> [Program] {
        items.reduce(into: [UUID: Program]()) { programsByID, item in
            programsByID[item.program.id] = item.program
        }
        .values
        .sorted {
            $0.title.localizedCompare($1.title) == .orderedAscending
        }
    }

    private func filterSummary(
        in items: [CoachReviewItem]
    ) -> Text {
        let programTitle: Text
        if let programID = filterSelection.programID,
           let title = items.first(where: {
               $0.program.id == programID
           })?.program.title {
            programTitle = Text(verbatim: title)
        } else {
            programTitle = Text("coach.review.filter.all_programs")
        }

        return Text(
            "\(programTitle) · \(Text(filterSelection.status.titleKey)) · \(Text(filterSelection.rating.titleKey))"
        )
    }
}

private enum CoachEvidenceScope: String, CaseIterable, Identifiable {
    case needsAction
    case all

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .needsAction:
            "coach.review.scope.needs_action"
        case .all:
            "coach.review.scope.all"
        }
    }
}

private enum CoachReviewSheetDestination: Identifiable {
    case detail(CoachReviewItem)
    case filters([Program])

    var id: String {
        switch self {
        case .detail(let item):
            "detail-\(item.id)"
        case .filters:
            "filters"
        }
    }
}

private enum CoachEvidenceStatusFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all
    case needsApproval
    case automatic
    case approved
    case rejected

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all:
            "coach.review.filter.status.all"
        case .needsApproval:
            "coach.review.filter.status.needsApproval"
        case .automatic:
            "coach.review.filter.status.automatic"
        case .approved:
            "coach.review.filter.status.approved"
        case .rejected:
            "coach.review.filter.status.rejected"
        }
    }

    func matches(_ item: CoachReviewItem) -> Bool {
        switch self {
        case .all:
            true
        case .needsApproval:
            item.needsCoachAction
        case .automatic:
            item.step.verificationMode == .automatic
        case .approved:
            item.step.verificationMode == .coachReview
                && item.submission.status == .approved
        case .rejected:
            item.submission.status == .rejected
        }
    }
}

private enum CoachEvidenceRatingFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all
    case unrated
    case rated

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all:
            "coach.review.filter.rating.all"
        case .unrated:
            "coach.review.filter.rating.unrated"
        case .rated:
            "coach.review.filter.rating.rated"
        }
    }

    func matches(_ item: CoachReviewItem) -> Bool {
        switch self {
        case .all:
            true
        case .unrated:
            item.submission.coachRating == nil
        case .rated:
            item.submission.coachRating != nil
        }
    }
}

private struct CoachEvidenceFilterSelection: Equatable {
    var programID: UUID?
    var status: CoachEvidenceStatusFilter
    var rating: CoachEvidenceRatingFilter

    static let all = CoachEvidenceFilterSelection(
        programID: nil,
        status: .all,
        rating: .all
    )
}

private extension CoachReviewItem {
    var needsCoachAction: Bool {
        step.verificationMode == .coachReview
            && submission.status == .pending
    }
}

private struct CoachEvidenceFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    let programs: [Program]
    let referenceDate: Date
    let onApply: (CoachEvidenceFilterSelection) -> Void

    @State private var draftSelection: CoachEvidenceFilterSelection

    init(
        programs: [Program],
        selection: CoachEvidenceFilterSelection,
        referenceDate: Date,
        onApply: @escaping (CoachEvidenceFilterSelection) -> Void
    ) {
        self.programs = programs
        self.referenceDate = referenceDate
        self.onApply = onApply
        _draftSelection = State(initialValue: selection)
    }

    var body: some View {
        NavigationStack {
            Form {
                programSection
                statusSection
                ratingSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle(Text("coach.review.filter.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.brandPrimary)
                    .accessibilityIdentifier("coach.review.filter.close")
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                FilterSheetActionBar(
                    resetTitle: "coach.review.filter.reset",
                    applyTitle: "coach.review.filter.apply",
                    resetIdentifier: "coach.review.filter.reset",
                    applyIdentifier: "coach.review.filter.apply"
                ) {
                    draftSelection = .all
                } onApply: {
                    onApply(draftSelection)
                    dismiss()
                }
                .accessibilityIdentifier("coach.review.filter.action-bar")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("coach.review.filter.sheet")
    }

    private var programSection: some View {
        ProgramFilterSection(
            programs: programs,
            referenceDate: referenceDate,
            sectionTitle: "coach.review.filter.program",
            allProgramsTitle: "coach.review.filter.all_programs",
            optionIdentifierPrefix:
                "coach.review.filter.option.program",
            selection: $draftSelection.programID
        )
    }

    private var statusSection: some View {
        Section("coach.review.filter.status.title") {
            Picker(
                "coach.review.filter.status.title",
                selection: $draftSelection.status
            ) {
                ForEach(CoachEvidenceStatusFilter.allCases) { option in
                    Text(option.titleKey)
                        .tag(option)
                        .accessibilityIdentifier(
                            "coach.review.filter.option.status.\(option.rawValue)"
                        )
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }

    private var ratingSection: some View {
        Section("coach.review.filter.rating.title") {
            Picker(
                "coach.review.filter.rating.title",
                selection: $draftSelection.rating
            ) {
                ForEach(CoachEvidenceRatingFilter.allCases) { option in
                    Text(option.titleKey)
                        .tag(option)
                        .accessibilityIdentifier(
                            "coach.review.filter.option.rating.\(option.rawValue)"
                        )
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }
}

private enum CoachReviewLayout {
    static let scopeControlHeight: CGFloat = 50
}

private struct CoachEvidenceRow: View {
    let item: CoachReviewItem

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .top, spacing: AppSpacing.small) {
                UserAvatar(
                    displayName: item.participant.displayName,
                    imageName: item.participant.localPhotoReference,
                    size: 64
                )

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text(item.participant.displayName)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(Color.appPrimaryText)

                    Text(item.step.title)
                        .font(AppTypography.body)
                        .foregroundStyle(Color.appPrimaryText)

                    Text(
                        "\(item.program.title) • \(Text("participant.day.label")) \(item.day.dayNumber, format: .number.locale(CoachFormatting.locale))"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)

                    Label {
                        Text(
                            CoachFormatting.dateTime(
                                item.submission.submittedAt,
                                timeZoneIdentifier:
                                    item.program.timeZoneIdentifier
                            )
                        )
                        .monospacedDigit()
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                }

                Spacer(minLength: AppSpacing.xSmall)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appSecondaryText)
                    .frame(
                        width: 20,
                        height: AppControlMetrics.minimumTouchTarget,
                        alignment: .topTrailing
                    )
                    .accessibilityHidden(true)
            }

            Divider()

            CoachEvidenceRowStatus(item: item)
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
        .contentShape(
            RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
        )
        .accessibilityElement(children: .combine)
    }
}

private struct CoachEvidenceRowStatus: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let item: CoachReviewItem

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    statusLabel
                    ratingLabel
                }
            } else {
                HStack(alignment: .center, spacing: AppSpacing.small) {
                    statusLabel
                    Spacer(minLength: AppSpacing.xSmall)
                    ratingLabel
                }
            }
        }
        .font(AppTypography.secondary)
    }

    private var statusLabel: some View {
        Label(statusTitle, systemImage: statusSystemImage)
            .foregroundStyle(statusColor)
            .fixedSize(horizontal: true, vertical: true)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.xSmall)
            .background(
                statusBackgroundColor,
                in: RoundedRectangle(
                    cornerRadius: AppRadius.medium,
                    style: .continuous
                )
            )
    }

    private var ratingLabel: some View {
        Group {
            if let rating = item.submission.coachRating {
                Label {
                    Text(
                        "\(rating, format: .number.locale(CoachFormatting.locale))/5"
                    )
                } icon: {
                    Image(systemName: "star.fill")
                }
            } else {
                Label(
                    "coach.review.rating.unrated",
                    systemImage: "star"
                )
            }
        }
        .foregroundStyle(Color.appWarning)
        .fixedSize(horizontal: true, vertical: true)
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.xSmall)
        .background(
            Color.brandAccent.opacity(0.24),
            in: RoundedRectangle(
                cornerRadius: AppRadius.medium,
                style: .continuous
            )
        )
    }

    private var statusTitle: LocalizedStringKey {
        if item.step.verificationMode == .automatic {
            return "coach.review.status.automatic"
        }
        switch item.submission.status {
        case .pending:
            return "coach.review.status.needs_approval"
        case .approved:
            return "status.approved"
        case .rejected:
            return "status.rejected"
        }
    }

    private var statusSystemImage: String {
        if item.step.verificationMode == .automatic {
            return "checkmark.circle.fill"
        }
        switch item.submission.status {
        case .pending:
            return "exclamationmark.circle"
        case .approved:
            return "checkmark.circle.fill"
        case .rejected:
            return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        if item.step.verificationMode == .automatic {
            return .appSuccess
        }
        switch item.submission.status {
        case .pending:
            return .brandPrimary
        case .approved:
            return .appSuccess
        case .rejected:
            return .appDestructive
        }
    }

    private var statusBackgroundColor: Color {
        if item.step.verificationMode == .automatic {
            return .appSuccess.opacity(0.14)
        }
        switch item.submission.status {
        case .pending:
            return .brandPrimary.opacity(0.1)
        case .approved:
            return .appSuccess.opacity(0.14)
        case .rejected:
            return .appDestructive.opacity(0.14)
        }
    }

}

@MainActor
private struct CoachReviewDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let item: CoachReviewItem
    let features: CoachFeatureContainer

    @State private var selectedEvidence: StepSubmissionAnswer?
    @State private var selectedRating: Int
    @State private var persistedRating: Int
    @State private var isApproveConfirmationPresented = false
    @State private var navigationPath: [CoachReviewDetailDestination] = []
    @State private var actionError: String?

    init(
        item: CoachReviewItem,
        features: CoachFeatureContainer
    ) {
        self.item = item
        self.features = features
        let rating = item.submission.coachRating ?? 0
        _selectedRating = State(initialValue: rating)
        _persistedRating = State(initialValue: rating)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(
                        alignment: .leading,
                        spacing: AppSpacing.large
                    ) {
                        CoachEvidenceModeBanner(item: item)
                        contextCard
                        evidenceContent
                        ratingSection

                        if let actionError {
                            Label(
                                actionError,
                                systemImage: "exclamationmark.circle"
                            )
                            .font(AppTypography.secondary)
                            .foregroundStyle(Color.appDestructive)
                        }
                    }
                    .padding(AppSpacing.medium)
                }

                bottomActionBar
            }
            .background(Color.appBackground)
            .navigationTitle(
                Text(
                    item.step.verificationMode == .automatic
                        ? "coach.review.detail.view_title"
                        : "coach.review.sheet.title"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(
                for: CoachReviewDetailDestination.self
            ) { destination in
                switch destination {
                case .rejection:
                    CoachEvidenceRejectionView(
                        item: item,
                        features: features,
                        ratingToSave: selectedRating != persistedRating
                            ? selectedRating
                            : nil
                    )
                }
            }
        }
        .presentationDetents([.large])
        .sheet(item: $selectedEvidence) { evidence in
            CoachEvidenceViewer(evidence: evidence)
        }
        .confirmationDialog(
            "coach.review.confirm.title",
            isPresented: $isApproveConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("coach.review.approve") {
                approve()
            }
            Button("action.cancel", role: .cancel) {}
        } message: {
            Text("coach.review.confirm.approve")
        }
        .onChange(of: features.reviewQueue.lastDecision) { _, decision in
            guard decision?.submissionID == item.id,
                  decision?.status == .rejected else {
                return
            }
            dismiss()
        }
    }

    private var contextCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.small) {
                UserAvatar(
                    displayName: item.participant.displayName,
                    imageName: item.participant.localPhotoReference
                )

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text(item.participant.displayName)
                        .font(AppTypography.cardTitle)
                    Text(item.program.title)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.xSmall) {
                    CoachContextTag(
                        title: Text(
                            "Hari \(item.day.dayNumber, format: .number.locale(CoachFormatting.locale))"
                        ),
                        systemImage: "calendar"
                    )
                    CoachContextTag(
                        title: Text(verbatim: item.step.title),
                        systemImage: "checklist"
                    )
                }

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    CoachContextTag(
                        title: Text(
                            "Hari \(item.day.dayNumber, format: .number.locale(CoachFormatting.locale))"
                        ),
                        systemImage: "calendar"
                    )
                    CoachContextTag(
                        title: Text(verbatim: item.step.title),
                        systemImage: "checklist"
                    )
                }
            }

            Text(item.step.instructions)
                .font(AppTypography.body)
                .foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
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

    private var evidenceContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("coach.review.evidence.title")
                .font(AppTypography.sectionTitle)

            if item.submission.typedAnswers.isEmpty {
                Text("coach.review.evidence.empty")
                    .foregroundStyle(Color.appSecondaryText)
            } else {
                ForEach(item.submission.typedAnswers) { answer in
                    typedAnswerCard(answer)
                }
            }

            if let result = item.submission.quizResult {
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text("Hasil kuis")
                        .font(AppTypography.cardTitle)
                    LabeledContent(
                        "Jawaban benar",
                        value: "\(result.correctAnswerCount) dari "
                            + "\(result.totalQuestionCount)"
                    )
                    LabeledContent("Nilai", value: "\(result.percentage)%")
                    LabeledContent(
                        "Status",
                        value: result.isPassed ? "Lulus" : "Belum lulus"
                    )
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

            if hasUnavailablePhotoEvidence {
                Label(
                    "coach.evidence.unavailable.action_notice",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appDestructive)
                .accessibilityIdentifier(
                    "coach.review.evidence.unavailable"
                )
            }

            let submittedAt = CoachFormatting.dateTime(
                item.submission.submittedAt,
                timeZoneIdentifier: item.program.timeZoneIdentifier
            )
            Text("Dikirim \(submittedAt)")
            .font(AppTypography.secondary.monospacedDigit())
            .foregroundStyle(Color.appSecondaryText)
        }
    }

    private func typedAnswerCard(
        _ answer: StepSubmissionAnswer
    ) -> some View {
        let question = item.step.content?.questions.first {
            $0.id == answer.questionID
        }
        return VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(question?.prompt ?? "Jawaban peserta")
                .font(AppTypography.cardTitle)
            if answer.localPhotoReference != nil {
                Button {
                    selectedEvidence = answer
                } label: {
                    CoachEvidencePhotoPreview(evidence: answer)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("coach.review.evidence.open")
            } else {
                Text(answerSummary(answer, question: question))
                    .font(AppTypography.body)
            }
            if let question, let key = question.answerKey {
                Divider()
                Text("Jawaban benar")
                    .font(AppTypography.secondary.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(answerKeySummary(key, question: question))
                    .font(AppTypography.secondary)
                    .foregroundStyle(.secondary)
            }
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
    }

    private func answerSummary(
        _ answer: StepSubmissionAnswer,
        question: ProgramQuestionDefinition?
    ) -> String {
        if let text = answer.textValue, !text.isEmpty {
            return text
        }
        if let number = answer.numberValue {
            return number.formatted(
                .number.locale(Locale(identifier: "id-ID"))
            )
        }
        if !answer.selectedOptionIDs.isEmpty {
            let titles = question?.options.filter {
                answer.selectedOptionIDs.contains($0.id)
            }.map(\.title) ?? []
            return titles.isEmpty ? "Pilihan tersimpan" : titles.joined(
                separator: ", "
            )
        }
        if answer.localPhotoReference != nil {
            return "Foto peserta terlampir"
        }
        return "Belum dijawab"
    }

    private func answerKeySummary(
        _ key: ProgramQuestionAnswerKey,
        question: ProgramQuestionDefinition
    ) -> String {
        if let number = key.numberValue {
            return number.formatted(
                .number.locale(Locale(identifier: "id-ID"))
            )
        }
        if !key.selectedOptionIDs.isEmpty {
            return question.options.filter {
                key.selectedOptionIDs.contains($0.id)
            }.map(\.title).joined(separator: ", ")
        }
        return key.acceptedTextValues.joined(separator: ", ")
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.xSmall) {
                Text("coach.review.rating.title")
                    .font(AppTypography.sectionTitle)
                Text("coach.review.rating.optional")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.appSecondaryText)
                    .padding(.horizontal, AppSpacing.xSmall)
                    .padding(.vertical, AppSpacing.xxSmall)
                    .background(
                        Color.appSecondaryBackground,
                        in: Capsule()
                    )
            }

            HStack(spacing: AppSpacing.xSmall) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        selectedRating = rating
                    } label: {
                        Image(
                            systemName: rating <= selectedRating
                                ? "star.fill"
                                : "star"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            rating <= selectedRating
                                ? Color.brandAccent
                                : Color.appSecondaryText
                        )
                        .frame(
                            maxWidth: .infinity,
                            minHeight: AppControlMetrics.minimumTouchTarget
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        Text(
                            "\(rating, format: .number.locale(CoachFormatting.locale)) bintang"
                        )
                    )
                    .accessibilityIdentifier(
                        "coach.review.rating.\(rating)"
                    )
                }
            }

            if selectedRating > 0 {
                Text(
                    "\(selectedRating, format: .number.locale(CoachFormatting.locale)) dari 5"
                )
                .font(AppTypography.secondary.monospacedDigit())
                .foregroundStyle(Color.appPrimaryText)
            }

            Text("coach.review.rating.helper")
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
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

    @ViewBuilder
    private var bottomActionBar: some View {
        if item.needsCoachAction {
            HStack(spacing: AppSpacing.small) {
                Button(role: .destructive) {
                    navigationPath.append(.rejection)
                } label: {
                    Text("coach.review.reject")
                        .font(AppTypography.button)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(
                    CoachReviewSecondaryActionButtonStyle(
                        foregroundColor: .appDestructive
                    )
                )
                .disabled(
                    features.reviewQueue.isPerformingAction
                        || hasUnavailablePhotoEvidence
                )
                .accessibilityIdentifier("coach.review.reject")

                Button {
                    isApproveConfirmationPresented = true
                } label: {
                    Text(
                        "Setujui • \(item.program.effectiveScoringConfiguration.pointsPerActivity, format: .number.locale(CoachFormatting.locale)) poin"
                    )
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(
                    features.reviewQueue.isPerformingAction
                        || hasUnavailablePhotoEvidence
                )
                .accessibilityIdentifier("coach.review.approve")
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(.bar)
        } else {
            HStack(spacing: AppSpacing.small) {
                Button("coach.review.rating.skip") {
                    dismiss()
                }
                .font(AppTypography.button)
                .frame(maxWidth: .infinity, minHeight: 50)

                Button {
                    saveRatingAndClose()
                } label: {
                    Text("coach.review.rating.save")
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(
                    selectedRating == 0
                        || selectedRating == persistedRating
                        || features.reviewQueue.isPerformingAction
                )
                .accessibilityIdentifier("coach.review.rating.save")
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(.bar)
        }
    }

    private func approve() {
        Task {
            do {
                try await saveRatingIfNeeded()
                try await features.review(
                    item: item,
                    status: .approved,
                    note: nil
                )
                actionError = nil
                dismiss()
            } catch let error as DomainError {
                actionError = CoachFormatting.reason(error)
            } catch {
                actionError = String(
                    localized: "coach.error.generic",
                    defaultValue: "Terjadi kendala. Coba lagi."
                )
            }
        }
    }

    private var hasUnavailablePhotoEvidence: Bool {
        item.submission.photoAnswers.contains { answer in
            guard let reference = answer.localPhotoReference else {
                return false
            }
            return LocalMediaImageResolver.image(reference: reference) == nil
        }
    }

    private func saveRatingAndClose() {
        Task {
            do {
                try await saveRatingIfNeeded()
                actionError = nil
                dismiss()
            } catch let error as DomainError {
                actionError = CoachFormatting.reason(error)
            } catch {
                actionError = String(
                    localized: "coach.error.generic",
                    defaultValue: "Terjadi kendala. Coba lagi."
                )
            }
        }
    }

    private func saveRatingIfNeeded() async throws {
        guard selectedRating > 0,
              selectedRating != persistedRating else {
            return
        }
        try await features.saveRating(
            item: item,
            rating: selectedRating
        )
        persistedRating = selectedRating
    }
}

private enum CoachReviewDetailDestination: String, Hashable {
    case rejection
}

private struct CoachReviewSecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    var foregroundColor: Color = .brandPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, AppSpacing.medium)
            .foregroundStyle(foregroundColor)
            .background(
                configuration.isPressed
                    ? foregroundColor.opacity(0.08)
                    : Color.appSurface,
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
                .stroke(foregroundColor, lineWidth: 1)
            }
            .opacity(isEnabled ? 1 : 0.45)
    }
}

private struct CoachEvidenceModeBanner: View {
    let item: CoachReviewItem

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(color)
                .frame(
                    width: AppControlMetrics.minimumTouchTarget,
                    height: AppControlMetrics.minimumTouchTarget
                )

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(titleKey)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.appPrimaryText)
                message
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            color.opacity(0.08),
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
            .stroke(color.opacity(0.35), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var titleKey: LocalizedStringKey {
        if item.step.verificationMode == .automatic {
            return "coach.review.banner.automatic.title"
        }
        switch item.submission.status {
        case .pending:
            return "coach.review.banner.pending.title"
        case .approved:
            return "coach.review.banner.approved.title"
        case .rejected:
            return "coach.review.banner.rejected.title"
        }
    }

    @ViewBuilder
    private var message: some View {
        if item.step.verificationMode == .automatic {
            Text(
                "\(item.program.effectiveScoringConfiguration.pointsPerActivity, format: .number.locale(CoachFormatting.locale)) poin sudah diberikan saat peserta mengirim jawaban."
            )
        } else {
            switch item.submission.status {
            case .pending:
                Text(
                    "\(item.program.effectiveScoringConfiguration.pointsPerActivity, format: .number.locale(CoachFormatting.locale)) poin diberikan setelah jawaban disetujui."
                )
            case .approved:
                Text(
                    "\(item.program.effectiveScoringConfiguration.pointsPerActivity, format: .number.locale(CoachFormatting.locale)) poin sudah diberikan kepada peserta."
                )
            case .rejected:
                Text(
                    "\(item.program.effectiveScoringConfiguration.pointsPerActivity, format: .number.locale(CoachFormatting.locale)) poin tidak diberikan untuk jawaban ini."
                )
            }
        }
    }

    private var systemImage: String {
        if item.step.verificationMode == .automatic {
            return "checkmark.circle.fill"
        }
        switch item.submission.status {
        case .pending:
            return "info.circle.fill"
        case .approved:
            return "checkmark.circle.fill"
        case .rejected:
            return "xmark.circle.fill"
        }
    }

    private var color: Color {
        if item.step.verificationMode == .automatic {
            return .appSuccess
        }
        switch item.submission.status {
        case .pending:
            return .appWarning
        case .approved:
            return .appSuccess
        case .rejected:
            return .appDestructive
        }
    }
}

private struct CoachContextTag: View {
    let title: Text
    let systemImage: String

    var body: some View {
        Label {
            title
        } icon: {
            Image(systemName: systemImage)
        }
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appSecondaryText)
            .padding(.horizontal, AppSpacing.xSmall)
            .padding(.vertical, AppSpacing.xxSmall)
            .background(
                Color.appSecondaryBackground,
                in: RoundedRectangle(
                    cornerRadius: AppRadius.small,
                    style: .continuous
                )
            )
    }
}

private struct CoachEvidencePhotoPreview: View {
    let evidence: StepSubmissionAnswer

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .background(Color.appSecondaryBackground)
                } else {
                    VStack(spacing: AppSpacing.small) {
                        Image(systemName: "photo.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.brandPrimary)
                        Text("coach.evidence.photo")
                            .font(AppTypography.secondary)
                            .foregroundStyle(Color.appSecondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appSecondaryBackground)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(4.0 / 3.0, contentMode: .fit)

            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appPrimaryText)
                .frame(
                    width: AppControlMetrics.minimumTouchTarget,
                    height: AppControlMetrics.minimumTouchTarget
                )
                .background(.ultraThinMaterial, in: Circle())
                .padding(AppSpacing.small)
                .accessibilityHidden(true)

            if LocalMediaImageResolver.isBundledEvidenceFixture(
                evidence.localPhotoReference ?? ""
            ) {
                Text("coach.evidence.demo_badge")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.appPrimaryText)
                    .padding(.horizontal, AppSpacing.xSmall)
                    .padding(.vertical, AppSpacing.xxSmall)
                    .background(.regularMaterial, in: Capsule())
                    .padding(AppSpacing.small)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
            }
        }
        .clipShape(
            RoundedRectangle(
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("coach.evidence.thumbnail"))
        .accessibilityHint(Text("coach.review.evidence.open_hint"))
    }

    private var image: UIImage? {
        LocalMediaImageResolver.image(
            reference: evidence.localPhotoReference ?? ""
        )
    }
}

@MainActor
private struct CoachEvidenceRejectionView: View {
    @Environment(\.dismiss) private var dismiss

    let item: CoachReviewItem
    let features: CoachFeatureContainer
    let ratingToSave: Int?

    @State private var reason = ""
    @State private var actionError: String?
    @State private var isSaving = false
    @FocusState private var isReasonFocused: Bool

    private let maximumReasonLength = 300

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    participantSummary
                    reasonEditor

                    Label(
                        "coach.review.rejection.resubmit_note",
                        systemImage: "info.circle"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appPrimaryText)
                    .padding(AppSpacing.small)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color.appSecondaryBackground,
                        in: RoundedRectangle(
                            cornerRadius: AppRadius.medium,
                            style: .continuous
                        )
                    )

                    if let actionError {
                        Label(
                            actionError,
                            systemImage: "exclamationmark.circle"
                        )
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appDestructive)
                    }
                }
                .padding(AppSpacing.medium)
            }

            HStack(spacing: AppSpacing.small) {
                Button("action.cancel") {
                    dismiss()
                }
                .buttonStyle(CoachReviewSecondaryActionButtonStyle())
                .disabled(isSaving)
                .accessibilityIdentifier(
                    "coach.review.rejection.cancel"
                )

                Button {
                    reject()
                } label: {
                    Text("coach.review.rejection.submit")
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(
                    reason.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty || isSaving
                )
                .accessibilityIdentifier(
                    "coach.review.rejection.submit"
                )
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(.bar)
        }
        .background(Color.appBackground)
        .navigationTitle(Text("coach.review.rejection.sheet_title"))
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(isSaving)
        .onChange(of: reason) { _, newValue in
            if newValue.count > maximumReasonLength {
                reason = String(newValue.prefix(maximumReasonLength))
            }
        }
    }

    private var participantSummary: some View {
        HStack(spacing: AppSpacing.small) {
            UserAvatar(
                displayName: item.participant.displayName,
                imageName: item.participant.localPhotoReference
            )
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(item.participant.displayName)
                    .font(AppTypography.cardTitle)
                Text(item.step.title)
                    .font(AppTypography.body)
                Text(
                    "\(item.program.title) • \(Text("participant.day.label")) \(item.day.dayNumber, format: .number.locale(CoachFormatting.locale))"
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
            }
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

    private var reasonEditor: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text("coach.review.rejection_reason.title")
                .font(AppTypography.cardTitle)

            ZStack(alignment: .topLeading) {
                if reason.isEmpty {
                    Text("coach.review.rejection_reason.placeholder")
                        .font(AppTypography.body)
                        .foregroundStyle(Color.appSecondaryText)
                        .padding(.horizontal, AppSpacing.small)
                        .padding(.vertical, AppSpacing.medium)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $reason)
                    .font(AppTypography.body)
                    .scrollContentBackground(.hidden)
                    .padding(AppSpacing.xSmall)
                    .focused($isReasonFocused)
                    .accessibilityIdentifier(
                        "coach.review.rejection-reason"
                    )
            }
            .frame(minHeight: 150)
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

            HStack(alignment: .top) {
                Text("coach.review.rejection_reason.footer")
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                Spacer(minLength: AppSpacing.small)
                Text(
                    "\(reason.count, format: .number.locale(CoachFormatting.locale))/\(maximumReasonLength, format: .number.locale(CoachFormatting.locale))"
                )
                .font(AppTypography.secondary.monospacedDigit())
                .foregroundStyle(Color.appSecondaryText)
            }
        }
    }

    private func reject() {
        Task {
            isSaving = true
            defer { isSaving = false }

            do {
                if let ratingToSave, ratingToSave > 0 {
                    try await features.saveRating(
                        item: item,
                        rating: ratingToSave
                    )
                }
                try await features.review(
                    item: item,
                    status: .rejected,
                    note: reason
                )
                actionError = nil
                dismiss()
            } catch let error as DomainError {
                actionError = CoachFormatting.reason(error)
            } catch {
                actionError = String(
                    localized: "coach.error.generic",
                    defaultValue: "Terjadi kendala. Coba lagi."
                )
            }
        }
    }
}

#Preview("Pusat bukti Coach") {
    NavigationStack {
        CoachReviewQueuePreview()
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

@MainActor
private struct CoachReviewQueuePreview: View {
    @State private var features = CoachFeatureContainer(
        environment: .preview
    )

    var body: some View {
        CoachReviewQueueView(features: features)
            .task {
                await features.prepareIdentity()
            }
    }
}
