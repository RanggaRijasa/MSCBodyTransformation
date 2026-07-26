import SwiftUI

@main
struct MSCBodyTransformationApp: App {
    @State private var router = AppRouter()
    private let appEnvironment = AppEnvironment.live

    var body: some Scene {
        WindowGroup {
            RootView(router: router)
                .environment(\.appEnvironment, appEnvironment)
                .environment(
                    \.locale,
                    appEnvironment.configuration.locale
                )
        }
    }
}
