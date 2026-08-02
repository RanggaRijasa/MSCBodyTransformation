import PhotosUI
import SwiftUI

@MainActor
struct AdminContentView: View {
    let features: AdminFeatureContainer

    @State private var selectedContent: ManagedContent?
    @State private var posterPendingRemoval: ManagedContent?
    @State private var error: DomainError?

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                Text("Konten")
                    .font(AppTypography.screenTitle)
                    .foregroundStyle(Color.appPrimaryText)
                    .accessibilityIdentifier("admin.content.title")

                addContentSection
                galleryHeader
            }
            .frame(maxWidth: 760)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.top, AppSpacing.xSmall)
            .padding(.bottom, AppSpacing.xSmall)
            .frame(maxWidth: .infinity)

            Divider()

            ScrollView {
                galleryState
                    .frame(maxWidth: 760)
                    .padding(AppSpacing.medium)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Color.appBackground)
        .sheet(item: $selectedContent) { content in
            AdminPosterEditorSheet(
                initialContent: content,
                features: features
            )
        }
        .confirmationDialog(
            "Hapus poster dari galeri?",
            isPresented: Binding(
                get: { posterPendingRemoval != nil },
                set: {
                    if !$0 {
                        posterPendingRemoval = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Hapus dari galeri", role: .destructive) {
                guard let poster = posterPendingRemoval else {
                    return
                }
                posterPendingRemoval = nil
                Task { await archive(poster) }
            }
            Button("Batal", role: .cancel) {
                posterPendingRemoval = nil
            }
        } message: {
            Text("admin.content.poster.remove_message")
        }
        .alert(
            "Konten tidak dapat disimpan",
            isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )
        ) {
            Button("Tutup", role: .cancel) {}
        } message: {
            Text(error?.localizedAdminMessage ?? "")
        }
    }

    private var addContentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Tambah konten")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(Color.appPrimaryText)

            AdminContentTypeButton(
                title: "Poster pemenang",
                subtitle: "Tambahkan gambar vertikal untuk galeri Home.",
                systemImage: "photo.stack.fill"
            ) {
                selectedContent = features.makeWinnerBanner(
                    programID: nil,
                    sortOrder: nextPosterSortOrder
                )
            }
            .accessibilityIdentifier("admin.content.create-banner")
        }
    }

    private var galleryHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Poster pemenang")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(Color.appPrimaryText)

            Text("Ketuk poster untuk mengganti gambarnya.")
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
                .accessibilityIdentifier(
                    "admin.content.gallery-instruction"
                )
        }
    }

    @ViewBuilder
    private var galleryState: some View {
        switch features.contentState {
        case .loaded(let content):
            posterGrid(posters(from: content))
        case .empty:
            posterGrid([])
        case .idle, .loading:
            ProgressView("Memuat galeri…")
                .frame(maxWidth: .infinity, minHeight: 180)
        case .failed(let domainError):
            ErrorStateView(
                error: domainError,
                retryAction: { Task { await features.load() } }
            )
        case .offline:
            VStack(spacing: AppSpacing.small) {
                OfflineBanner()
                Button("Coba lagi") {
                    Task { await features.load() }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private func posterGrid(
        _ posters: [ManagedContent]
    ) -> some View {
        if posters.isEmpty {
            ContentUnavailableView(
                "Galeri masih kosong",
                systemImage: "photo.on.rectangle.angled",
                description: Text(
                    "Tambahkan poster pemenang pertama dari tombol di atas."
                )
            )
            .frame(maxWidth: .infinity, minHeight: 240)
            .background(
                Color.appSurface,
                in: RoundedRectangle(
                    cornerRadius: AppRadius.large,
                    style: .continuous
                )
            )
        } else {
            LazyVGrid(
                columns: galleryColumns,
                alignment: .leading,
                spacing: AppSpacing.medium
            ) {
                ForEach(
                    Array(posters.enumerated()),
                    id: \.element.id
                ) { index, poster in
                    AdminPosterGalleryCell(
                        poster: poster,
                        position: index + 1,
                        onEdit: {
                            selectedContent = poster
                        },
                        onRemove: {
                            posterPendingRemoval = poster
                        }
                    )
                }
            }
            .accessibilityIdentifier("admin.content.poster-gallery")
        }
    }

    private var galleryColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: AppSpacing.small),
            GridItem(.flexible(), spacing: AppSpacing.small)
        ]
    }

    private var currentPosters: [ManagedContent] {
        guard case .loaded(let content) = features.contentState else {
            return []
        }
        return posters(from: content)
    }

    private var nextPosterSortOrder: Int {
        (currentPosters.map(\.sortOrder).max() ?? 0) + 1
    }

    private func posters(
        from content: [ManagedContent]
    ) -> [ManagedContent] {
        content
            .filter {
                $0.kind == .winnerBanner && !$0.isArchived
            }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.updatedAt > $1.updatedAt
                }
                return $0.sortOrder < $1.sortOrder
            }
    }

    private func archive(_ poster: ManagedContent) async {
        var archived = poster
        archived.isArchived = true
        archived.isPublished = false
        archived.updatedAt = features.environment.clock.now()
        do {
            try await features.saveContent(archived)
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }
}

private struct AdminContentTypeButton: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 48, height: 48)
                    .background(
                        Color.brandPrimary.opacity(0.1),
                        in: RoundedRectangle(
                            cornerRadius: AppRadius.medium,
                            style: .continuous
                        )
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text(title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(Color.appPrimaryText)

                    Text(subtitle)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: AppSpacing.xSmall)

                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.brandPrimary)
                    .accessibilityHidden(true)
            }
            .padding(AppSpacing.small)
            .frame(maxWidth: .infinity)
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
        }
        .buttonStyle(.plain)
    }
}

private struct AdminPosterGalleryCell: View {
    let poster: ManagedContent
    let position: Int
    let onEdit: () -> Void
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onEdit) {
                WinnerPosterImage(
                    reference: poster.localMediaReference,
                    alternativeText: poster.title
                )
                .contentShape(
                    RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                Text("Edit poster urutan \(position)")
            )
            .accessibilityIdentifier(
                "admin.content.poster.\(poster.id)"
            )

            Menu {
                Button("Ganti poster", action: onEdit)
                Button(
                    "Hapus dari galeri",
                    role: .destructive,
                    action: onRemove
                )
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appPrimaryText)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
            }
            .padding(AppSpacing.xSmall)
            .accessibilityLabel(
                Text("Tindakan poster urutan \(position)")
            )
            .accessibilityIdentifier(
                "admin.content.poster-menu.\(poster.id)"
            )

            Text(position, format: .number.locale(Locale(identifier: "id-ID")))
                .font(AppTypography.label.monospacedDigit().weight(.bold))
                .foregroundStyle(Color.appPrimaryText)
                .frame(minWidth: 32, minHeight: 32)
                .background(.regularMaterial, in: Circle())
                .padding(AppSpacing.xSmall)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
    }
}

struct AdminPosterEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let features: AdminFeatureContainer

    @State private var content: ManagedContent
    @State private var error: DomainError?
    @State private var isSaving = false
    @State private var selectedPosterItem: PhotosPickerItem?
    @State private var posterMedia = LocalEvidenceMediaState()

    init(
        initialContent: ManagedContent,
        features: AdminFeatureContainer
    ) {
        _content = State(initialValue: initialContent)
        self.features = features
    }

    var body: some View {
        let pickerTitle = content.localMediaReference == nil
            ? String(
                localized: "admin.content.poster.pick",
                defaultValue: "Pilih poster dari Foto"
            )
            : String(
                localized: "admin.content.poster.replace",
                defaultValue: "Ganti poster dari Foto"
            )
        let pickerFont = AppTypography.button

        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    WinnerPosterImage(
                        reference: content.localMediaReference,
                        alternativeText: "Poster pemenang"
                    )
                    .frame(maxWidth: 240)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(
                        "admin.content.poster-preview"
                    )

                    if posterMedia.isProcessing {
                        ProgressView(
                            value: posterMedia.progress,
                            total: 1
                        ) {
                            Text("Memproses poster…")
                        }
                    }

                    PhotosPicker(
                        selection: $selectedPosterItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label(
                            pickerTitle,
                            systemImage: "photo.on.rectangle"
                        )
                        .font(pickerFont)
                        .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.brandPrimary)
                    .disabled(posterMedia.isProcessing)
                    .accessibilityIdentifier(
                        "admin.content.poster-picker"
                    )

                    if content.localMediaReference != nil {
                        Button("Hapus gambar", role: .destructive) {
                            posterMedia.remove()
                            content.localMediaReference = nil
                            selectedPosterItem = nil
                        }
                        .frame(minHeight: 44)
                    }

                    if let mediaError = posterMedia.error {
                        Label(
                            mediaErrorMessage(mediaError),
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appDestructive)
                    }

                    Label(
                        "admin.content.poster.editor_help",
                        systemImage: "info.circle"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: 520)
                .padding(AppSpacing.medium)
                .frame(maxWidth: .infinity)
            }
            .background(Color.appBackground)
            .navigationTitle("Poster pemenang")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Menyimpan…" : "Simpan") {
                        Task { await save() }
                    }
                    .disabled(
                        isSaving
                            || posterMedia.isProcessing
                            || content.localMediaReference?.isEmpty != false
                    )
                    .accessibilityIdentifier("admin.content.save-banner")
                }
            }
            .alert(
                "Konten tidak dapat disimpan",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                Button("Tutup", role: .cancel) {}
            } message: {
                Text(error?.localizedAdminMessage ?? "")
            }
            .onChange(of: selectedPosterItem) { _, item in
                guard let item else { return }
                Task { await importPoster(item) }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let now = features.environment.clock.now()
        var updated = content
        updated.title = "Poster pemenang \(content.sortOrder)"
        updated.body = "Poster gambar untuk galeri Home peserta."
        updated.programID = nil
        updated.visibleFrom = updated.visibleFrom ?? now
        updated.visibleUntil = nil
        updated.isPublished = true
        updated.isArchived = false
        updated.updatedAt = now

        do {
            try await features.saveContent(updated)
            dismiss()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }

    private func importPoster(_ item: PhotosPickerItem) async {
        await posterMedia.importPhoto(item)
        if let result = posterMedia.result {
            content.localMediaReference = result.localURL.path
        }
    }

    private func mediaErrorMessage(
        _ error: LocalMediaError
    ) -> String {
        switch error {
        case .unsupportedMIMEType:
            "Pilih gambar JPEG, PNG, HEIC, atau HEIF."
        case .inputTooLarge:
            "Ukuran poster terlalu besar. Pilih gambar hingga 20 MB."
        case .invalidImage:
            "Poster tidak dapat dibaca. Pilih gambar lain."
        case .processingFailed:
            "Poster gagal diproses. Coba lagi."
        case .permissionDenied:
            "Akses Foto ditolak. Periksa izin aplikasi di Pengaturan."
        case .cameraUnavailable:
            "Kamera tidak tersedia pada perangkat ini."
        case .cameraUsageDescriptionMissing:
            "Kamera belum dikonfigurasi untuk build ini."
        }
    }
}
