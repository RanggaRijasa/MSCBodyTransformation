import SwiftUI

enum AsyncContentState<Value> {
    case idle
    case loading
    case empty
    case loaded(Value)
    case failed(DomainError)
    case offline(Value?)
}

struct AsyncContentView<Value, Content: View>: View {
    let state: AsyncContentState<Value>
    let emptyTitle: LocalizedStringKey
    let emptyMessage: LocalizedStringKey
    let retryAction: (() -> Void)?
    @ViewBuilder let content: (Value) -> Content

    init(
        state: AsyncContentState<Value>,
        emptyTitle: LocalizedStringKey = "state.empty.title",
        emptyMessage: LocalizedStringKey = "state.empty.message",
        retryAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.state = state
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self.retryAction = retryAction
        self.content = content
    }

    @ViewBuilder
    var body: some View {
        switch state {
        case .idle, .loading:
            LoadingStateView()
        case .empty:
            EmptyStateView(
                title: emptyTitle,
                message: emptyMessage,
                systemImage: "tray"
            )
        case .loaded(let value):
            content(value)
        case .failed(let error):
            ErrorStateView(error: error, retryAction: retryAction)
        case .offline(let value):
            VStack(spacing: AppSpacing.medium) {
                OfflineBanner()
                if let value {
                    content(value)
                } else {
                    EmptyStateView(
                        title: "state.offline.empty.title",
                        message: "state.offline.empty.message",
                        systemImage: "wifi.slash"
                    )
                }
            }
        }
    }
}

struct LoadingStateView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.small) {
                ProgressView()
                Text("state.loading")
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appSecondaryText)
            }

            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(
                    cornerRadius: AppRadius.medium,
                    style: .continuous
                )
                .fill(Color.appBorder.opacity(0.45))
                .frame(height: 72)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("state.loading"))
    }
}

struct EmptyStateView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let systemImage: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        }
        .foregroundStyle(Color.appPrimaryText)
    }
}

struct ErrorStateView: View {
    let error: DomainError
    let retryAction: (() -> Void)?

    init(error: DomainError, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }

    var body: some View {
        let message = DomainErrorMessageMapper.message(for: error)

        ContentUnavailableView {
            Label(
                LocalizedStringKey(message.titleKey),
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text(LocalizedStringKey(message.messageKey))
        } actions: {
            if let retryAction {
                Button("action.retry", action: retryAction)
                    .buttonStyle(.borderedProminent)
                    .tint(.brandPrimary)
            }
        }
    }
}

struct OfflineBanner: View {
    var body: some View {
        Label("state.offline.banner", systemImage: "wifi.slash")
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appPrimaryText)
            .padding(.horizontal, AppSpacing.medium)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(
                Color.brandAccent.opacity(0.28),
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
                .stroke(Color.appWarning.opacity(0.6), lineWidth: 1)
            }
            .accessibilityIdentifier("state.offline-banner")
    }
}

#Preview("State — loading") {
    LoadingStateView()
        .padding()
}

#Preview("State — kosong") {
    EmptyStateView(
        title: "state.empty.title",
        message: "state.empty.message",
        systemImage: "tray"
    )
}

#Preview("State — error") {
    ErrorStateView(error: .offline)
}

#Preview("State — offline") {
    OfflineBanner()
        .padding()
}
