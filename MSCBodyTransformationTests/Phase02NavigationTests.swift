import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Navigasi Phase 02")
struct Phase02NavigationTests {
    @Test("Setiap role menghasilkan lima tab yang tepat")
    func rolesProduceCorrectTabs() {
        #expect(
            AppTab.tabs(for: .participant) == [
                .participant(.today),
                .participant(.program),
                .participant(.leaderboard),
                .participant(.coaches),
                .participant(.profile)
            ]
        )
        #expect(
            AppTab.tabs(for: .coach) == [
                .coach(.dashboard),
                .coach(.participants),
                .coach(.invite),
                .coach(.leaderboard),
                .coach(.profile)
            ]
        )
        #expect(
            AppTab.tabs(for: .admin) == [
                .admin(.overview),
                .admin(.programs),
                .admin(.people),
                .admin(.content),
                .admin(.settings)
            ]
        )
    }

    @Test("Peserta tidak dapat membuka route admin")
    @MainActor
    func participantCannotOpenAdminRoute() {
        let router = ShellTabRouter()
        let participantTab = AppTab.participant(.today)

        router.navigate(
            to: .admin(.programEditor(nil)),
            in: participantTab
        )

        #expect(router.path(for: participantTab).isEmpty)
        #expect(router.presentedAlert == .unavailableRoute)
    }

    @Test("Path setiap tab dipertahankan secara terpisah")
    @MainActor
    func pathsArePreservedPerTab() {
        let router = ShellTabRouter()
        let today = AppTab.participant(.today)
        let program = AppTab.participant(.program)
        let programID = UUID(
            uuid: (
                16, 0, 0, 0,
                0, 0,
                0, 0,
                0, 0,
                0, 0, 0, 0, 0, 1
            )
        )

        router.navigate(
            to: .participant(.localInvite("MSC7HARI")),
            in: today
        )
        router.navigate(
            to: .participant(.programDetail(programID, .program)),
            in: program
        )

        #expect(
            router.path(for: today) == [
                .participant(.localInvite("MSC7HARI"))
            ]
        )
        #expect(
            router.path(for: program) == [
                .participant(.programDetail(programID, .program))
            ]
        )
    }

    @Test("Deep link lokal menghasilkan kode undangan")
    func localInviteDeepLinkParsesCode() throws {
        let url = try #require(
            URL(string: "msc-demo://join/msc7hari")
        )

        #expect(
            LocalInviteDeepLinkParser().inviteCode(from: url)
                == "MSC7HARI"
        )
    }

#if DEBUG
    @Test("Launch argument memilih role dan skenario Debug")
    func debugLaunchArgumentsSelectRoleAndScenario() {
        let configuration = DebugLaunchConfiguration(
            arguments: [
                "MSCBodyTransformation",
                "-DemoRole", "admin",
                "-DemoScenario", "admin_draft_editor",
                "-SkipDemoLanding"
            ]
        )

        #expect(configuration.role == .admin)
        #expect(configuration.scenario == .adminDraftCMS)
        #expect(configuration.skipsLanding)
    }
#endif
}

@Suite("Design system Phase 02")
struct Phase02DesignSystemTests {
    @Test("Reduce Motion menonaktifkan animation token")
    @MainActor
    func reduceMotionDisablesAnimationToken() {
        #expect(AppMotion.quick(reduceMotion: true) == nil)
        #expect(AppMotion.standard(reduceMotion: true) == nil)
        #expect(AppMotion.quick(reduceMotion: false) != nil)
    }

    @Test("Semua status memiliki icon yang menyertai warna")
    @MainActor
    func everyStatusHasAnIcon() {
        for kind in AppStatusKind.allCases {
            #expect(
                !AppStatusStyle.style(for: kind).systemImage.isEmpty
            )
        }
    }
}
