import SwiftUI

@MainActor
struct ProfileOnboardingView: View {
    let state: AuthenticationFlowState

    var body: some View {
        @Bindable var bindableState = state

        AuthFlowContainer {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                AuthFlowHeader(
                    systemImage: "person.text.rectangle",
                    title: "auth.profile.title",
                    message: "auth.profile.message"
                )
                .accessibilityIdentifier("auth.profile")

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("auth.profile.section.identity")
                        .font(AppTypography.cardTitle)

                    AuthFormSurface {
                        TextField(
                            String(
                                localized: "auth.profile.field.name",
                                defaultValue: "Nama"
                            ),
                            text: $bindableState.displayName
                        )
                        .textContentType(.name)
                        .accessibilityIdentifier("auth.profile.name")

                        Divider()

                        TextField(
                            String(
                                localized: "auth.profile.field.phone",
                                defaultValue: "Nomor HP"
                            ),
                            text: $bindableState.phoneNumber
                        )
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .accessibilityIdentifier("auth.profile.phone")

                        Divider()

                        Picker(
                            "auth.profile.field.member_level",
                            selection: Binding(
                                get: { state.memberLevel },
                                set: { state.selectMemberLevel($0) }
                            )
                        ) {
                            ForEach(MemberLevel.allCases) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .accessibilityIdentifier("auth.profile.member-level")
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("auth.profile.section.purpose")
                        .font(AppTypography.cardTitle)

                    VStack(spacing: AppSpacing.small) {
                        PurposeSelectionCard(
                            title: "auth.profile.purpose.participant",
                            message: "auth.profile.purpose.participant_detail",
                            systemImage: "figure.walk",
                            isSelected:
                                state.accountPurpose == .participant,
                            isEnabled: true
                        ) {
                            state.accountPurpose = .participant
                        }
                        .accessibilityIdentifier(
                            "auth.profile.purpose.participant"
                        )

                        PurposeSelectionCard(
                            title: "auth.profile.purpose.coach",
                            message: "auth.profile.purpose.coach_detail",
                            systemImage: "person.2.fill",
                            isSelected:
                                state.accountPurpose == .coachApplicant,
                            isEnabled: state.memberLevel.isCoachLevelEligible
                        ) {
                            state.accountPurpose = .coachApplicant
                        }
                        .accessibilityIdentifier(
                            "auth.profile.purpose.coach"
                        )
                    }

                    if !state.memberLevel.isCoachLevelEligible {
                        Label(
                            "auth.profile.purpose.member_ineligible",
                            systemImage: "info.circle"
                        )
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                    }
                }

                if let errorMessage = state.errorMessage {
                    AuthErrorBanner(message: errorMessage)
                }

                Button {
                    state.completeProfile()
                } label: {
                    Text("action.continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(state.isSubmitting)
                .accessibilityIdentifier("auth.profile.continue")

                Text("auth.registration.draft_notice")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.appSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

@MainActor
struct ParticipantCoachQRRegistrationView: View {
    let state: AuthenticationFlowState

    @State private var showsScanner = false

    var body: some View {
        AuthFlowContainer {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                AuthFlowHeader(
                    systemImage: "qrcode.viewfinder",
                    title: "auth.participant_qr.title",
                    message: "auth.participant_qr.message"
                )
                .accessibilityIdentifier("auth.participant-qr")

                if let coach = state.selectedParticipantCoach {
                    AuthFormSurface {
                        HStack(spacing: AppSpacing.medium) {
                            UserAvatar(
                                displayName: coach.displayName,
                                size: 56
                            )
                            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                                Text(coach.displayName)
                                    .font(AppTypography.cardTitle)
                                Text(coach.city)
                                    .font(AppTypography.secondary)
                                    .foregroundStyle(
                                        Color.appSecondaryText
                                    )
                                Label(
                                    "auth.participant_qr.verified",
                                    systemImage: "checkmark.seal.fill"
                                )
                                .font(AppTypography.label)
                                .foregroundStyle(Color.appSuccess)
                            }
                            Spacer()
                        }
                    }
                    .accessibilityIdentifier(
                        "auth.participant-qr.selected-coach"
                    )
                } else {
                    Label(
                        "auth.participant_qr.required_notice",
                        systemImage: "lock.shield"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
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

                Button {
                    showsScanner = true
                } label: {
                    Label(
                        state.selectedParticipantCoach == nil
                            ? "auth.participant_qr.scan"
                            : "auth.participant_qr.scan_again",
                        systemImage: "qrcode.viewfinder"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    SecondaryActionButtonStyle(
                        foregroundColor: .appPrimaryText
                    )
                )
                .accessibilityIdentifier(
                    "auth.participant-qr.open-scanner"
                )

                if let errorMessage = state.errorMessage {
                    AuthErrorBanner(message: errorMessage)
                }

                Button {
                    Task { await state.createParticipantAccount() }
                } label: {
                    SubmittingButtonLabel(
                        title: "auth.participant_qr.create_account",
                        isSubmitting: state.isSubmitting
                    )
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(!state.canCreateParticipantAccount)
                .accessibilityIdentifier(
                    "auth.participant-qr.create-account"
                )

                Text("auth.registration.draft_notice")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.appSecondaryText)
            }
        }
        .sheet(isPresented: $showsScanner) {
            LocalQRScannerSheet { identifier in
                Task {
                    await state.selectScannedParticipantCoach(
                        identifier: identifier
                    )
                }
            }
        }
    }
}

@MainActor
struct CoachApplicationView: View {
    let state: AuthenticationFlowState

    var body: some View {
        @Bindable var bindableState = state

        AuthFlowContainer {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                AuthFlowHeader(
                    systemImage: "checklist.checked",
                    title: "coach.eligibility.title",
                    message: "coach.eligibility.message"
                )
                .accessibilityIdentifier("coach.eligibility")

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("coach.eligibility.section.level")
                        .font(AppTypography.cardTitle)

                    AuthFormSurface {
                        LabeledContent(
                            "auth.profile.field.member_level",
                            value: state.memberLevel.displayName
                        )
                        Divider()
                        Label(
                            state.eligibility.isLevelEligible
                                ? "coach.eligibility.satisfied"
                                : "coach.eligibility.not_satisfied",
                            systemImage: state.eligibility.isLevelEligible
                                ? "checkmark.circle.fill"
                                : "xmark.circle.fill"
                        )
                        .foregroundStyle(
                            state.eligibility.isLevelEligible
                                ? Color.appSuccess
                                : Color.appDestructive
                        )
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("coach.eligibility.section.requirements")
                        .font(AppTypography.cardTitle)

                    AuthFormSurface {
                        CoachRequirementCheckbox(
                            title: "coach.eligibility.requirement.hom_sts",
                            isChecked: $bindableState.hasCompletedHOMSTS
                        )
                        .accessibilityIdentifier("coach.eligibility.hom-sts")

                        Divider()

                        CoachRequirementCheckbox(
                            title: "coach.eligibility.requirement.ict",
                            isChecked: $bindableState.hasCompletedICT
                        )
                        .accessibilityIdentifier("coach.eligibility.ict")
                    }

                    Text("coach.eligibility.attestation_notice")
                        .font(AppTypography.label)
                        .foregroundStyle(Color.appSecondaryText)
                }

                if let preview = state.paymentPreview {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("coach.payment.summary")
                            .font(AppTypography.cardTitle)
                        PaymentSummarySurface(
                            memberLevel: state.memberLevel,
                            preview: preview
                        )
                    }
                }

                Label(
                    "coach.eligibility.approval_notice",
                    systemImage: "person.badge.clock"
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)

                if let errorMessage = state.errorMessage {
                    AuthErrorBanner(message: errorMessage)
                }

                Button {
                    state.continueToPayment()
                } label: {
                    Text("coach.eligibility.continue_payment")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(!state.eligibility.isComplete)
                .accessibilityIdentifier(
                    "coach.eligibility.continue-payment"
                )

                if !state.eligibility.isComplete {
                    Text("coach.eligibility.incomplete_help")
                        .font(AppTypography.label)
                        .foregroundStyle(Color.appSecondaryText)
                }
            }
        }
    }
}

@MainActor
struct CoachPaymentPreviewView: View {
    let state: AuthenticationFlowState

    var body: some View {
        AuthFlowContainer {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                AuthFlowHeader(
                    systemImage: "creditcard.fill",
                    title: "coach.payment.title",
                    message: "coach.payment.message"
                )
                .accessibilityIdentifier("coach.payment")

                if let preview = state.paymentPreview {
                    PaymentSummarySurface(
                        memberLevel: state.memberLevel,
                        preview: preview
                    )

#if DEBUG
                    Label(
                        "coach.payment.demo_notice",
                        systemImage: "hammer.fill"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appInfo)
#endif
                }

                if let errorMessage = state.errorMessage {
                    AuthErrorBanner(message: errorMessage)
                }

                Button {
                    Task { await state.performPurchase() }
                } label: {
                    SubmittingButtonLabel(
                        title: "coach.payment.continue_to_pay",
                        isSubmitting: state.isSubmitting
                    )
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(state.isSubmitting)
                .accessibilityIdentifier("coach.payment.purchase")

                Text("auth.registration.coach_commit_notice")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.appSecondaryText)
            }
        }
    }
}

@MainActor
struct CoachPendingApprovalView: View {
    let state: AuthenticationFlowState

    var body: some View {
        AuthFlowContainer {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                AuthFlowHeader(
                    systemImage: "clock.badge.checkmark",
                    title: "coach.pending.title",
                    message: "coach.pending.message"
                )
                .accessibilityIdentifier("coach.pending")

                AuthFormSurface {
                    Label {
                        Text(paymentVerifiedText)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .foregroundStyle(Color.appSuccess)

                    Divider()

                    Label {
                        Text(participantRoleText)
                    } icon: {
                        Image(systemName: "person.fill")
                    }
                    .foregroundStyle(Color.appSecondaryText)

                    Divider()

                    Label {
                        Text(adminReviewText)
                    } icon: {
                        Image(systemName: "person.badge.clock")
                    }
                    .foregroundStyle(Color.appSecondaryText)
                }

                Button {
                    Task { await state.finish() }
                } label: {
                    Text("coach.pending.finish")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("coach.pending.finish")
            }
        }
    }

    private var paymentVerifiedText: String {
        String(
            localized: "coach.pending.payment_verified",
            defaultValue: "Pembayaran terverifikasi"
        )
    }

    private var participantRoleText: String {
        String(
            localized: "coach.pending.participant_role",
            defaultValue: "Akun tetap sebagai Peserta"
        )
    }

    private var adminReviewText: String {
        String(
            localized: "coach.pending.admin_review",
            defaultValue: "Menunggu pemeriksaan Admin"
        )
    }
}

private struct PurposeSelectionCard: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let systemImage: String
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(
                        isSelected
                            ? Color.brandPrimary
                            : Color.appSecondaryText
                    )
                    .frame(
                        width: AppControlMetrics.minimumTouchTarget,
                        height: AppControlMetrics.minimumTouchTarget
                    )

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Label(title, systemImage: systemImage)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(Color.appPrimaryText)
                    Text(message)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected
                    ? Color.brandPrimary.opacity(0.08)
                    : Color.appSurface,
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
                .stroke(
                    isSelected ? Color.brandPrimary : Color.appBorder,
                    lineWidth: isSelected ? 2 : 1
                )
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

private struct CoachRequirementCheckbox: View {
    let title: LocalizedStringKey
    @Binding var isChecked: Bool

    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(spacing: AppSpacing.medium) {
                Image(
                    systemName: isChecked
                        ? "checkmark.square.fill"
                        : "square"
                )
                .font(.title3)
                .foregroundStyle(
                    isChecked
                        ? Color.brandPrimary
                        : Color.appSecondaryText
                )
                Text(title)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: AppControlMetrics.minimumTouchTarget,
                alignment: .leading
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChecked ? .isSelected : [])
        .accessibilityValue(
            Text(isChecked ? "state.checked" : "state.not_checked")
        )
    }
}

private struct PaymentSummarySurface: View {
    let memberLevel: MemberLevel
    let preview: CoachPaymentPreview

    var body: some View {
        AuthFormSurface {
            LabeledContent(
                "auth.profile.field.member_level",
                value: memberLevel.displayName
            )
            Divider()
            LabeledContent(
                "coach.payment.price",
                value: formattedPrice
            )
            .font(AppTypography.cardTitle.monospacedDigit())
            Divider()
            LabeledContent(
                "coach.payment.duration",
                value: String(
                    localized: "coach.payment.duration_value",
                    defaultValue: "3 bulan"
                )
            )
            Divider()
            Label(
                "coach.payment.no_auto_renew",
                systemImage: "calendar.badge.clock"
            )
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appSecondaryText)
        }
    }

    private var formattedPrice: String {
        Decimal(preview.amountMinorUnits).formatted(
            .currency(code: "IDR")
                .locale(Locale(identifier: "id-ID"))
                .precision(.fractionLength(0))
        )
    }
}
