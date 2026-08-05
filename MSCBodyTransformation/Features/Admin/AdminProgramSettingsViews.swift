import PhotosUI
import SwiftUI

@MainActor
struct AdminProgramInformationView: View {
    @Binding var draft: AdminProgramDraft
    @State private var selectedCoverItem: PhotosPickerItem?
    @State private var coverMedia = LocalEvidenceMediaState()

    var body: some View {
        let coverPickerTitle: String =
            draft.coverLocalReference == nil
                ? String(
                    localized: "admin.program.cover.choose",
                    defaultValue: "Pilih gambar cover"
                )
                : String(
                    localized: "admin.program.cover.replace",
                    defaultValue: "Ganti gambar cover"
                )

        Form {
            Section("Identitas program") {
                TextField("Nama", text: $draft.title)
                TextField("Kategori", text: $draft.category)
                TextField(
                    "Deskripsi",
                    text: $draft.summary,
                    axis: .vertical
                )
                .lineLimit(3...8)
            }

            Section("Pembayaran") {
                Picker("Jenis program", selection: pricingMode) {
                    Text("Gratis").tag(ProgramPricingMode.free)
                    Text("Berbayar").tag(ProgramPricingMode.paid)
                }
                .pickerStyle(.segmented)

                if pricingMode.wrappedValue == .paid {
                    TextField(
                        "Harga yang diinginkan",
                        value: desiredPrice,
                        format: .number.locale(Locale(identifier: "id-ID"))
                    )
                    .keyboardType(.numberPad)
                    Text(
                        "Harga ini menjadi acuan provisioning. Harga yang "
                            + "ditampilkan kepada peserta tetap berasal dari "
                            + "App Store atau Google Play."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }

            Section {
                ProgramCoverImage(
                    reference: draft.coverLocalReference,
                    alternativeText: draft.coverAlternativeText
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: AppRadius.medium,
                        style: .continuous
                    )
                )
                .accessibilityIdentifier("admin.program.cover.preview")
                .listRowSeparator(.hidden)

                if coverMedia.isProcessing {
                    ProgressView(
                        value: coverMedia.progress,
                        total: 1
                    ) {
                        Text("Memproses cover…")
                    }
                    .listRowSeparator(.hidden)
                }

                PhotosPicker(
                    selection: $selectedCoverItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: AppSpacing.small) {
                        Label {
                            Text(verbatim: coverPickerTitle)
                        } icon: {
                            Image(systemName: "photo.on.rectangle")
                        }
                        Spacer(minLength: AppSpacing.small)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.appSecondaryText)
                    }
                    .font(AppTypography.body)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 44,
                        alignment: .leading
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(coverMedia.isProcessing)
                .accessibilityIdentifier("admin.program.cover.picker")
                .listRowSeparator(.hidden)

                if draft.coverLocalReference != nil {
                    Button(role: .destructive) {
                        coverMedia.remove()
                        draft.coverLocalReference = nil
                        selectedCoverItem = nil
                    } label: {
                        Label(
                            "Hapus gambar cover",
                            systemImage: "trash"
                        )
                        .font(AppTypography.body)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 44,
                            alignment: .leading
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                }

                if let error = coverMedia.error {
                    Label(
                        coverErrorMessage(error),
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appDestructive)
                    .listRowSeparator(.hidden)
                }

                TextField(
                    "Teks alternatif cover",
                    text: $draft.coverAlternativeText,
                    axis: .vertical
                )
                .lineLimit(2...5)
            } header: {
                Text("Cover program")
            } footer: {
                Text(
                    "Cover selalu berupa gambar rasio lebar. Jelaskan "
                        + "isinya secara singkat untuk pengguna VoiceOver."
                )
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Info program")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("admin.program.info")
        .onChange(of: selectedCoverItem) { _, item in
            guard let item else { return }
            Task { await importCover(item) }
        }
    }

    private func importCover(_ item: PhotosPickerItem) async {
        await coverMedia.importPhoto(item)
        if let result = coverMedia.result {
            draft.coverLocalReference = result.localURL.path
        }
    }

    private func coverErrorMessage(_ error: LocalMediaError) -> String {
        switch error {
        case .unsupportedMIMEType:
            "Pilih gambar JPEG, PNG, HEIC, atau HEIF."
        case .inputTooLarge:
            "Ukuran cover terlalu besar. Pilih gambar hingga 20 MB."
        case .invalidImage:
            "Cover tidak dapat dibaca. Pilih gambar lain."
        case .processingFailed:
            "Cover gagal diproses. Coba lagi."
        case .permissionDenied:
            "Akses Foto ditolak. Periksa izin aplikasi di Pengaturan."
        case .cameraUnavailable:
            "Kamera tidak tersedia pada perangkat ini."
        case .cameraUsageDescriptionMissing:
            "Kamera belum dikonfigurasi untuk build ini."
        }
    }

    private var pricingMode: Binding<ProgramPricingMode> {
        Binding(
            get: {
                draft.commerceConfiguration?.pricingMode
                    ?? (draft.price == nil ? .free : .paid)
            },
            set: { mode in
                if mode == .free {
                    draft.price = nil
                    draft.commerceConfiguration =
                        ProgramCommerceConfiguration(
                            pricingMode: .free,
                            desiredPrice: nil,
                            platformAvailability:
                                CommercePlatform.allCases.map {
                                    ProgramPlatformAvailability(
                                        platform: $0,
                                        isEnabled: true,
                                        provisioningStatus: .notRequired
                                    )
                                }
                        )
                } else {
                    let price = draft.price ?? 0
                    draft.price = price
                    draft.commerceConfiguration =
                        ProgramCommerceConfiguration(
                            pricingMode: .paid,
                            desiredPrice: price,
                            platformAvailability:
                                CommercePlatform.allCases.map {
                                    ProgramPlatformAvailability(
                                        platform: $0,
                                        isEnabled: true,
                                        provisioningStatus: .notRequested
                                    )
                                }
                        )
                }
            }
        )
    }

    private var desiredPrice: Binding<Decimal> {
        Binding(
            get: {
                draft.commerceConfiguration?.desiredPrice
                    ?? draft.price
                    ?? 0
            },
            set: { price in
                draft.price = price
                draft.commerceConfiguration?.desiredPrice = price
            }
        )
    }
}

@MainActor
struct AdminProgramScheduleView: View {
    @Binding var draft: AdminProgramDraft

    var body: some View {
        Form {
            Section {
                Label(
                    "Jadwal dikunci setelah peserta bergabung.",
                    systemImage: "info.circle"
                )
                .foregroundStyle(Color.appInfo)
            }

            Section {
                Picker("Pola program", selection: $draft.pace) {
                    ForEach(AdminProgramPace.allCases, id: \.self) { pace in
                        Text(pace.adminTitle).tag(pace)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Pola penyelesaian")
            } footer: {
                Text(
                    draft.pace == .scheduled
                        ? "Langkah tersedia pada hari yang ditentukan."
                        : "Peserta dapat memulai sesuai waktunya."
                )
            }

            Section("Jadwal program") {
                Picker("Jenis durasi", selection: $draft.durationMode) {
                    ForEach(
                        AdminProgramDurationMode.allCases,
                        id: \.self
                    ) { mode in
                        Text(mode.adminTitle).tag(mode)
                    }
                }

                DatePicker(
                    draft.durationMode == .fixedDuration
                        ? "Tanggal acuan"
                        : "Mulai",
                    selection: $draft.startDate,
                    displayedComponents: .date
                )

                if draft.durationMode == .specificDates {
                    DatePicker(
                        "Selesai",
                        selection: $draft.endDate,
                        displayedComponents: .date
                    )
                } else {
                    Stepper(
                        "Durasi: \(draft.fixedDurationDays.formatted(.number.locale(Locale(identifier: "id-ID")))) hari",
                        value: $draft.fixedDurationDays,
                        in: 1...365
                    )
                }

                Picker(
                    "Zona waktu",
                    selection: $draft.timeZoneIdentifier
                ) {
                    Text("WITA · Makassar").tag("Asia/Makassar")
                    Text("WIB · Jakarta").tag("Asia/Jakarta")
                    Text("WIT · Jayapura").tag("Asia/Jayapura")
                }
            }

            Section("Peserta") {
                LabeledContent("Akses", value: "Publik")

                Toggle(
                    "Batasi jumlah peserta",
                    isOn: participantLimitToggle
                )
                if draft.participantLimit != nil {
                    Stepper(
                        "Maksimal \(draft.participantLimit?.formatted(.number.locale(Locale(identifier: "id-ID"))) ?? "0") peserta",
                        value: participantLimitValue,
                        in: 1...10_000
                    )
                }

                Toggle(
                    "admin.program.registration_deadline.toggle",
                    isOn: registrationDeadlineToggle
                )
                .accessibilityIdentifier(
                    "admin.program.registration-deadline-toggle"
                )

                if draft.registrationClosesAt != nil {
                    DatePicker(
                        "admin.program.registration_deadline.picker",
                        selection: registrationDeadlineValue,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityIdentifier(
                        "admin.program.registration-deadline"
                    )

                    Text(
                        "admin.program.registration_deadline.help"
                    )
                    .font(.footnote)
                    .foregroundStyle(Color.appSecondaryText)
                }
            }

            Section {
                Label(
                    "Buka Konten setelah mengubah jadwal untuk "
                        + "menyinkronkan hari tanpa menghapus isi.",
                    systemImage: "arrow.triangle.2.circlepath"
                )
                .foregroundStyle(Color.appSecondaryText)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Jadwal dan peserta")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("admin.program.schedule")
    }

    private var participantLimitToggle: Binding<Bool> {
        Binding(
            get: { draft.participantLimit != nil },
            set: { isLimited in
                draft.participantLimit = isLimited ? 50 : nil
            }
        )
    }

    private var participantLimitValue: Binding<Int> {
        Binding(
            get: { draft.participantLimit ?? 50 },
            set: { draft.participantLimit = $0 }
        )
    }

    private var registrationDeadlineToggle: Binding<Bool> {
        Binding(
            get: { draft.registrationClosesAt != nil },
            set: { isLimited in
                draft.registrationClosesAt = isLimited
                    ? defaultRegistrationClosesAt
                    : nil
            }
        )
    }

    private var registrationDeadlineValue: Binding<Date> {
        Binding(
            get: {
                draft.registrationClosesAt ?? defaultRegistrationClosesAt
            },
            set: { draft.registrationClosesAt = $0 }
        )
    }

    private var defaultRegistrationClosesAt: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(identifier: draft.timeZoneIdentifier)
            ?? TimeZone(identifier: "Asia/Makassar")
            ?? .gmt
        let programStart = calendar.startOfDay(for: draft.startDate)
        return calendar.date(
            byAdding: .minute,
            value: -1,
            to: programStart
        ) ?? programStart
    }
}

@MainActor
struct AdminProgramRulesView: View {
    @Binding var draft: AdminProgramDraft

    var body: some View {
        Form {
            Section {
                TextField(
                    "Poin setiap langkah selesai",
                    value: $draft.pointsPerActivity,
                    format: .number.locale(Locale(identifier: "id-ID"))
                )
                .keyboardType(.numberPad)
            } header: {
                Text("Poin langkah")
            } footer: {
                Text(
                    "Diberikan saat langkah non-kuis disetujui. Kuis "
                        + "memberikan poin ini untuk setiap jawaban benar."
                )
            }

            Section {
                TextField(
                    "Poin setiap 1 kg turun",
                    value: $draft.weightPointsPerKilogram,
                    format: .number.locale(Locale(identifier: "id-ID"))
                )
                .keyboardType(.decimalPad)
            } header: {
                Text("Poin penurunan berat badan")
            } footer: {
                Text(
                    "Dihitung dari selisih timbang awal dan timbang akhir. "
                        + "Timbang harian hanya mencatat progres."
                )
            }

            Section("Kuis dan pemeriksaan") {
                Stepper(
                    "Nilai lulus kuis: \(draft.quizPassingPercentage)%",
                    value: $draft.quizPassingPercentage,
                    in: 0...100
                )
                Picker(
                    "Pemeriksaan default",
                    selection: $draft.verificationMode
                ) {
                    ForEach(
                        SubmissionVerificationMode.allCases,
                        id: \.self
                    ) { mode in
                        Text(mode.adminTitle).tag(mode)
                    }
                }
            }

            Section("Akses hari program") {
                Picker(
                    "Langkah lampau",
                    selection: $draft.pastStepPolicy
                ) {
                    ForEach(PastStepPolicy.allCases, id: \.self) {
                        Text($0.adminTitle).tag($0)
                    }
                }
                Picker(
                    "Langkah mendatang",
                    selection: $draft.futureStepPolicy
                ) {
                    ForEach(FutureStepPolicy.allCases, id: \.self) {
                        Text($0.adminTitle).tag($0)
                    }
                }
            }

            Section("Informasi wellness") {
                TextField(
                    "Informasi untuk peserta",
                    text: $draft.wellnessDisclaimer,
                    axis: .vertical
                )
                .lineLimit(3...8)
            }

            Section("Ringkasan aturan") {
                Text(
                    "Poin langkah: \(draft.pointsPerActivity) per langkah "
                        + "selesai atau per jawaban kuis yang benar. Poin "
                        + "penurunan berat: \(draft.weightPointsPerKilogram.formatted(.number.locale(Locale(identifier: "id-ID")))) per 1 kg dari timbang awal ke akhir."
                )
                Label(
                    "Skor ini masih berupa pratinjau lokal.",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundStyle(Color.appWarning)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Aturan dan poin")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("admin.program.rules")
    }
}

@MainActor
struct AdminProgramParticipantPreviewView: View {
    let draft: AdminProgramDraft

    @State private var previewRole: PreviewRole = .participant

    private var scenario: AdminProgramPreviewScenario {
        AdminProgramPreviewScenario(draft: draft)
    }

    var body: some View {
        VStack(spacing: 0) {
            previewRolePicker

            ScrollView {
                LazyVStack(
                    alignment: .leading,
                    spacing: AppSpacing.large
                ) {
                    previewExplanation

                    if previewRole == .coach {
                        monitoredParticipant
                    }

                    ProgramActivityRenderer(
                        program: scenario.program,
                        submissions: scenario.submissions,
                        focusedDayID: scenario.focusedDayID,
                        referenceDate: scenario.referenceDate,
                        capabilities: ProgramActivityCapabilities(
                            audience: previewRole.audience,
                            canOpenSteps: false
                        ),
                        accessibilityPrefix: "admin.program.preview",
                        accessForDay: scenario.access,
                        onOpenStep: { _ in }
                    )
                    .accessibilityIdentifier(
                        "admin.program.preview.renderer"
                    )
                }
                .frame(maxWidth: 720, alignment: .leading)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.bottom, AppSpacing.medium)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("admin.editor.preview")
        }
        .background(Color.appBackground)
        .navigationTitle(
            String(
                localized: "admin.program.preview.title",
                defaultValue: "Pratinjau program"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private var previewRolePicker: some View {
        Picker(
            String(
                localized: "admin.program.preview.role",
                defaultValue: "Peran pratinjau"
            ),
            selection: $previewRole
        ) {
            ForEach(PreviewRole.allCases) {
                Text($0.title)
                    .font(.subheadline.weight(.medium))
                    .frame(minHeight: AppSpacing.xLarge)
                    .tag($0)
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .frame(minHeight: AppControlMetrics.minimumTouchTarget)
        .accessibilityIdentifier(
            "admin.program.preview.role-picker"
        )
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.small)
        .padding(.bottom, AppSpacing.medium)
    }

    private var previewExplanation: some View {
        Label {
            Text(previewRole.explanation)
        } icon: {
            Image(systemName: "eye")
                .foregroundStyle(Color.appPrimaryText)
        }
        .font(AppTypography.secondary)
        .foregroundStyle(Color.appPrimaryText)
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.appSecondaryBackground,
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
        .accessibilityIdentifier("admin.program.preview.explanation")
    }

    private var monitoredParticipant: some View {
        CoachProgramParticipantContext(
            displayName: "Ayu Lestari",
            imageName: nil,
            accessibilityIdentifier:
                "admin.program.preview.monitored-participant"
        )
    }
}

nonisolated struct AdminProgramPreviewScenario: Sendable {
    let program: Program
    let focusedDayID: UUID?
    let referenceDate: Date
    let submissions: [StepSubmission]

    init(draft: AdminProgramDraft) {
        let publishedProgram = draft.program()
        program = publishedProgram
        let focusedDay = publishedProgram.days
            .sorted { $0.dayNumber < $1.dayNumber }
            .first
        let scenarioReferenceDate =
            focusedDay?.scheduledDate ?? publishedProgram.startDate
        focusedDayID = focusedDay?.id
        referenceDate = scenarioReferenceDate
        submissions = (focusedDay?.steps ?? [])
            .sorted { $0.order < $1.order }
            .prefix(2)
            .enumerated()
            .map { index, step in
                StepSubmission(
                    id: step.id,
                    enrollmentID: publishedProgram.id,
                    stepID: step.id,
                    status: index == 0 ? .approved : .pending,
                    submittedAt: scenarioReferenceDate,
                    reviewedAt: index == 0
                        ? scenarioReferenceDate
                        : nil,
                    reviewerID: nil,
                    reviewNote: nil
                )
            }
    }

    func access(for day: ProgramDay) -> ProgramDayAccess {
        ProgramDayAccessCalculator().access(
            for: day,
            in: program,
            now: referenceDate
        )
    }
}

private extension AdminProgramParticipantPreviewView {
    enum PreviewRole: String, CaseIterable, Identifiable {
        case participant
        case coach

        var id: String { rawValue }

        var title: String {
            switch self {
            case .participant:
                String(
                    localized: "role.participant",
                    defaultValue: "Peserta"
                )
            case .coach:
                String(
                    localized: "role.coach",
                    defaultValue: "Coach"
                )
            }
        }

        var explanation: String {
            switch self {
            case .participant:
                String(
                    localized:
                        "admin.program.preview.participant.explanation",
                    defaultValue:
                        "Tampilan ini sama dengan yang dilihat Peserta."
                )
            case .coach:
                String(
                    localized: "admin.program.preview.coach.explanation",
                    defaultValue:
                        "Tampilan ini sama dengan yang dilihat Coach."
                )
            }
        }

        var audience: ProgramActivityAudience {
            switch self {
            case .participant:
                .participant
            case .coach:
                .coach
            }
        }
    }
}
