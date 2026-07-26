import SwiftUI

struct DemoPlaceholderView: View {
    let role: DemoRole

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                Image(systemName: role.systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 64, height: 64)
                    .background(
                        Color.brandAccent,
                        in: Circle()
                    )
                    .accessibilityHidden(true)

                VStack(spacing: AppSpacing.xSmall) {
                    Text("demo.placeholder.title")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.appPrimaryText)

                    Text(LocalizedStringKey(role.titleLocalizationKey))
                        .font(.headline)
                        .foregroundStyle(Color.brandPrimary)
                        .accessibilityIdentifier("demo.role")
                }

                Text("demo.placeholder.description")
                    .font(.body)
                    .foregroundStyle(Color.appSecondaryText)
                    .multilineTextAlignment(.center)

                Label("demo.placeholder.offline", systemImage: "wifi.slash")
                    .font(.subheadline)
                    .foregroundStyle(Color.appPrimaryText)
                    .padding(AppSpacing.medium)
                    .adaptiveDemoSurface()
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.xxLarge)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(Text(LocalizedStringKey(role.titleLocalizationKey)))
        .navigationBarTitleDisplayMode(.inline)
    }
}
