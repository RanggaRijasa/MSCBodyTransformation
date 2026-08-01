import SwiftUI
import UIKit

@MainActor
struct CoachInviteView: View {
    let state: CoachInviteComposerState
    let router: ShellTabRouter

    @State private var actionError: String?
    @State private var sharePayload: CoachIdentifierSharePayload?

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
            case .loaded(let snapshot):
                identifierContent(snapshot.profile)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .task {
            if state.state == .idle {
                await state.load()
            }
        }
        .sheet(item: $sharePayload) { payload in
            NativeShareSheet(activityItems: payload.activityItems)
        }
        .accessibilityIdentifier("coach.invite")
    }

    private func identifierContent(_ profile: CoachProfile) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                SectionHeader(
                    title: "coach.identifier.title",
                    subtitle: "coach.identifier.message"
                )

                VStack(spacing: AppSpacing.medium) {
                    UserAvatar(
                        displayName: profile.displayName,
                        size: 64
                    )
                    Text(profile.displayName)
                        .font(AppTypography.sectionTitle)
                    Text(profile.city)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)

                    CoachQRCodeView(
                        payload: qrPayload(for: profile),
                        coachName: profile.displayName
                    )

                    Button {
                        share(profile)
                    } label: {
                        Label(
                            "coach.identifier.share",
                            systemImage: "square.and.arrow.up"
                        )
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.brandPrimary)
                    .accessibilityIdentifier("coach.invite.share")
                }
                .padding(AppSpacing.large)
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

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Label(
                        "coach.identifier.how_to.first",
                        systemImage: "1.circle.fill"
                    )
                    Label(
                        "coach.identifier.how_to.second",
                        systemImage: "2.circle.fill"
                    )
                    Label(
                        "coach.identifier.how_to.third",
                        systemImage: "3.circle.fill"
                    )
                }
                .font(AppTypography.body)

                Label(
                    "coach.identifier.stable_notice",
                    systemImage: "checkmark.shield.fill"
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)

                if let actionError {
                    Label(
                        actionError,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(Color.appDestructive)
                }
            }
            .frame(maxWidth: 620, alignment: .leading)
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity)
        }
        .refreshable {
            await state.load()
        }
    }

    private func qrPayload(for profile: CoachProfile) -> String {
        (
            try? LocalInvitePayloadParser()
                .url(forOpaqueToken: profile.enrollmentIdentifier)
                .absoluteString
        ) ?? ""
    }

    private func share(_ profile: CoachProfile) {
        let payload = qrPayload(for: profile)
        guard !payload.isEmpty,
              let image = LocalQRCodeGenerator().image(
                  payload: payload
              ) else {
            actionError = String(
                localized: "coach.identifier.share_error",
                defaultValue: "QR coach belum dapat dibagikan."
            )
            return
        }

        let message =
            "Pindai QR coach \(profile.displayName) saat mendaftar "
            + "program MSC Body Transformation."
        sharePayload = CoachIdentifierSharePayload(
            id: profile.id,
            activityItems: [message, UIImage(cgImage: image)]
        )
        actionError = nil
    }
}

@MainActor
private struct CoachIdentifierSharePayload: Identifiable {
    let id: UUID
    let activityItems: [Any]
}

#Preview("QR pendaftaran Coach") {
    NavigationStack {
        CoachInvitePreview()
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

@MainActor
private struct CoachInvitePreview: View {
    @State private var state = CoachInviteComposerState(
        environment: .preview
    )
    @State private var router = ShellTabRouter()

    var body: some View {
        CoachInviteView(state: state, router: router)
            .navigationTitle(Text("tab.coach.invite"))
    }
}
