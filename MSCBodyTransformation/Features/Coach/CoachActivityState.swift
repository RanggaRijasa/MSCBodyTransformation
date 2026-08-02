import Foundation
import Observation

@MainActor
@Observable
final class CoachActivityState {
    private let environment: AppEnvironment
    private let service: CoachDataService

    var state: CoachFeatureLoadState<CoachActivitySnapshot> = .idle
    var selectedProgramID: UUID?
    var kindFilter: CoachActivityKindFilter = .all
    var timeRange: CoachActivityTimeRange = .today

    init(environment: AppEnvironment) {
        self.environment = environment
        service = CoachDataService(environment: environment)
    }

    var referenceDate: Date {
        environment.clock.now()
    }

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = CoachFormatting.locale
        calendar.timeZone = TimeZone(identifier: "Asia/Makassar") ?? .gmt
        return calendar
    }

    var snapshot: CoachActivitySnapshot? {
        guard case .loaded(let snapshot) = state else {
            return nil
        }
        return snapshot
    }

    var availablePrograms: [Program] {
        snapshot?.programs ?? []
    }

    var filteredItems: [CoachActivityItem] {
        guard let snapshot else {
            return []
        }
        let startDate = timeRange.startDate(
            referenceDate: referenceDate,
            calendar: calendar
        )
        return snapshot.items
            .filter { $0.occurredAt >= startDate }
            .filter { $0.occurredAt <= referenceDate }
            .filter {
                selectedProgramID == nil
                    || $0.programID == selectedProgramID
            }
            .filter { kindFilter.includes($0.kind) }
            .sorted { $0.occurredAt > $1.occurredAt }
    }

    var sections: [CoachActivitySection] {
        let groupedItems = Dictionary(
            grouping: filteredItems
        ) { item in
            calendar.startOfDay(for: item.occurredAt)
        }
        return groupedItems
            .map { day, items in
                CoachActivitySection(
                    day: day,
                    items: items.sorted { $0.occurredAt > $1.occurredAt }
                )
            }
            .sorted { $0.day > $1.day }
    }

    var hasOlderMatchingActivity: Bool {
        guard let snapshot else {
            return false
        }
        let startOfToday = calendar.startOfDay(for: referenceDate)
        let earliestHistoryDate = CoachActivityTimeRange.lastThirtyDays
            .startDate(
                referenceDate: referenceDate,
                calendar: calendar
            )
        return snapshot.items.contains { item in
            item.occurredAt >= earliestHistoryDate
                && item.occurredAt < startOfToday
                && (
                    selectedProgramID == nil
                        || item.programID == selectedProgramID
                )
                && kindFilter.includes(item.kind)
        }
    }

    func showPreviousActivity() {
        timeRange = .lastThirtyDays
    }

    func resetFilters() {
        selectedProgramID = nil
        kindFilter = .all
        timeRange = .today
    }

    func load() async {
        state = .loading
        do {
            let identity = try await service.identity()
            let snapshot = try await service.activitySnapshot(
                coachID: identity.profile.id
            )
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(snapshot)
        } catch is CancellationError {
            return
        } catch let error as DomainError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown)
        }
    }
}

