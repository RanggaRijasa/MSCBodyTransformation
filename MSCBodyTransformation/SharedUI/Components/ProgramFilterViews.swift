import SwiftUI

nonisolated struct ProgramFilterCatalog: Equatable, Sendable {
    let currentPrograms: [Program]
    let historyPrograms: [Program]
    let selectedHistoryProgram: Program?

    init(
        programs: [Program],
        selectedProgramID: UUID?,
        referenceDate: Date
    ) {
        let uniquePrograms = programs.reduce(
            into: [UUID: Program]()
        ) { programsByID, program in
            programsByID[program.id] = program
        }
        .values

        currentPrograms = uniquePrograms
            .filter {
                let status = $0.lifecycleStatus(at: referenceDate)
                return status == .active || status == .scheduled
            }
            .sorted {
                Self.currentProgramComesBefore(
                    $0,
                    $1,
                    referenceDate: referenceDate
                )
            }

        historyPrograms = uniquePrograms
            .filter {
                let status = $0.lifecycleStatus(at: referenceDate)
                return status == .completed || status == .archived
            }
            .sorted(by: Self.historyProgramComesBefore)

        selectedHistoryProgram = historyPrograms.first {
            $0.id == selectedProgramID
        }
    }

    var programsShownInMainPicker: [Program] {
        guard let selectedHistoryProgram else {
            return currentPrograms
        }
        return currentPrograms + [selectedHistoryProgram]
    }

    private static func currentProgramComesBefore(
        _ left: Program,
        _ right: Program,
        referenceDate: Date
    ) -> Bool {
        let leftStatus = left.lifecycleStatus(at: referenceDate)
        let rightStatus = right.lifecycleStatus(at: referenceDate)

        if leftStatus != rightStatus {
            return leftStatus == .active
        }

        if leftStatus == .active,
           left.endDate != right.endDate {
            return left.endDate < right.endDate
        }

        if left.startDate != right.startDate {
            return left.startDate < right.startDate
        }

        return left.title.localizedStandardCompare(right.title)
            == .orderedAscending
    }

    private static func historyProgramComesBefore(
        _ left: Program,
        _ right: Program
    ) -> Bool {
        if left.endDate != right.endDate {
            return left.endDate > right.endDate
        }
        if left.startDate != right.startDate {
            return left.startDate > right.startDate
        }
        return left.title.localizedStandardCompare(right.title)
            == .orderedAscending
    }
}

struct ProgramFilterSection: View {
    let programs: [Program]
    let referenceDate: Date
    let sectionTitle: LocalizedStringKey
    let allProgramsTitle: LocalizedStringKey
    let optionIdentifierPrefix: String

    @Binding var selection: UUID?

    private var catalog: ProgramFilterCatalog {
        ProgramFilterCatalog(
            programs: programs,
            selectedProgramID: selection,
            referenceDate: referenceDate
        )
    }

    var body: some View {
        Section(sectionTitle) {
            Picker(sectionTitle, selection: $selection) {
                Text(allProgramsTitle)
                    .tag(UUID?.none)
                    .accessibilityIdentifier(
                        "\(optionIdentifierPrefix).all"
                    )

                ForEach(catalog.programsShownInMainPicker) { program in
                    Text(verbatim: program.title)
                        .tag(Optional(program.id))
                        .accessibilityIdentifier(
                            "\(optionIdentifierPrefix).\(program.id)"
                        )
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()

            if !catalog.historyPrograms.isEmpty {
                NavigationLink {
                    ProgramHistoryFilterView(
                        programs: catalog.historyPrograms,
                        selection: $selection,
                        optionIdentifierPrefix: optionIdentifierPrefix
                    )
                } label: {
                    Label(
                        "filter.program.history",
                        systemImage: "clock.arrow.circlepath"
                    )
                }
                .accessibilityIdentifier(
                    "\(optionIdentifierPrefix).history"
                )
            }
        }
    }
}

private struct ProgramHistoryFilterView: View {
    @Environment(\.dismiss) private var dismiss

    let programs: [Program]
    @Binding var selection: UUID?
    let optionIdentifierPrefix: String

    @State private var query = ""

    private var filteredPrograms: [Program] {
        let normalizedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !normalizedQuery.isEmpty else {
            return programs
        }
        return programs.filter {
            $0.title.localizedCaseInsensitiveContains(normalizedQuery)
        }
    }

    var body: some View {
        List {
            if filteredPrograms.isEmpty {
                ContentUnavailableView(
                    "filter.program.history.empty.title",
                    systemImage: "magnifyingglass",
                    description: Text(
                        "filter.program.history.empty.message"
                    )
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredPrograms) { program in
                    Button {
                        selection = program.id
                        dismiss()
                    } label: {
                        HStack(spacing: AppSpacing.small) {
                            VStack(
                                alignment: .leading,
                                spacing: AppSpacing.xxSmall
                            ) {
                                Text(verbatim: program.title)
                                    .font(AppTypography.body)
                                    .foregroundStyle(Color.appPrimaryText)

                                Text(
                                    program.endDate,
                                    format: .dateTime
                                        .day()
                                        .month(.wide)
                                        .year()
                                        .locale(
                                            Locale(identifier: "id-ID")
                                        )
                                )
                                .font(AppTypography.secondary)
                                .foregroundStyle(Color.appSecondaryText)
                            }

                            Spacer()

                            if selection == program.id {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.brandPrimary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight:
                                AppControlMetrics.minimumTouchTarget,
                            alignment: .leading
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(
                        "\(optionIdentifierPrefix).history.\(program.id)"
                    )
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle(Text("filter.program.history"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $query,
            prompt: Text("filter.program.history.search")
        )
        .accessibilityIdentifier("app.filter.program-history")
    }
}
