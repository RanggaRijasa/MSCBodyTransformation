import PhotosUI
import SwiftUI

@MainActor
struct CoachProfileEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let state: CoachProfileState
    let snapshot: CoachProfileSnapshot

    @State private var displayName: String
    @State private var biography: String
    @State private var city: String
    @State private var photoReference: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var mediaState = LocalEvidenceMediaState()
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        state: CoachProfileState,
        snapshot: CoachProfileSnapshot
    ) {
        self.state = state
        self.snapshot = snapshot
        _displayName = State(initialValue: snapshot.profile.displayName)
        _biography = State(initialValue: snapshot.profile.biography)
        _city = State(initialValue: snapshot.profile.city)
        _photoReference = State(
            initialValue: snapshot.profile.localPhotoReference
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                identitySection
            }
            .navigationTitle("participant.profile.edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("participant.profile.save") {
                        save()
                    }
                    .disabled(
                        requiredFieldsAreEmpty
                            || mediaState.isProcessing
                            || isSaving
                    )
                    .accessibilityIdentifier(
                        "coach.profile.editor.save"
                    )
                }
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    ProgressView("participant.profile.saving")
                        .padding(AppSpacing.medium)
                        .background(
                            Color.appSecondaryBackground,
                            in: RoundedRectangle(
                                cornerRadius: AppRadius.medium,
                                style: .continuous
                            )
                        )
                }
            }
            .alert(
                "participant.profile.save_failed",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: {
                        if !$0 {
                            errorMessage = nil
                        }
                    }
                )
            ) {
                Button("action.close", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .interactiveDismissDisabled(isSaving)
    }

    private var photoSection: some View {
        Section {
            VStack(spacing: AppSpacing.medium) {
                UserAvatar(
                    displayName: displayName,
                    imageName: photoReference,
                    size: 112
                )
                .accessibilityIdentifier("coach.profile.editor.photo")

                Group {
                    if photoReference == nil {
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label(
                                "participant.profile.photo.choose",
                                systemImage: "photo.on.rectangle"
                            )
                            .frame(minHeight: 44)
                        }
                    } else {
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label(
                                "participant.profile.photo.change",
                                systemImage: "photo.on.rectangle"
                            )
                            .frame(minHeight: 44)
                        }
                    }
                }
                .accessibilityIdentifier(
                    "coach.profile.editor.photo-picker"
                )
                .onChange(of: selectedPhotoItem) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        await mediaState.importPhoto(newItem)
                        applyProcessedPhoto()
                    }
                }

                if photoReference != nil {
                    Button(
                        "participant.profile.photo.remove",
                        role: .destructive
                    ) {
                        mediaState.remove()
                        photoReference = nil
                        selectedPhotoItem = nil
                    }
                    .frame(minHeight: 44)
                }

                if mediaState.isProcessing {
                    ProgressView(
                        value: mediaState.progress,
                        total: 1
                    )
                }

                if let mediaError = mediaState.error {
                    Text(mediaErrorMessage(mediaError))
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appDestructive)
                }
            }
            .frame(maxWidth: .infinity)
        } header: {
            Text("participant.profile.photo")
        } footer: {
            Text("participant.profile.photo.help")
        }
    }

    private var identitySection: some View {
        Section {
            LabeledContent("participant.profile.field.name") {
                TextField(
                    "participant.profile.field.name",
                    text: $displayName
                )
                    .multilineTextAlignment(.trailing)
                    .textContentType(.name)
                    .accessibilityIdentifier(
                        "coach.profile.editor.name"
                    )
            }

            LabeledContent("participant.profile.field.city") {
                TextField(
                    "participant.profile.field.city",
                    text: $city
                )
                    .multilineTextAlignment(.trailing)
                    .textContentType(.addressCity)
                    .accessibilityIdentifier(
                        "coach.profile.editor.city"
                    )
            }

            LabeledContent(
                "participant.profile.field.email",
                value: snapshot.user.email
            )

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("coach.profile.biography")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.appSecondaryText)

                TextField(
                    "coach.profile.biography.prompt",
                    text: $biography,
                    axis: .vertical
                )
                .lineLimit(3...8)
                .accessibilityIdentifier(
                    "coach.profile.editor.biography"
                )
            }
        } header: {
            Text("participant.profile.data")
        } footer: {
            Text("coach.profile.required_fields")
        }
    }

    private var requiredFieldsAreEmpty: Bool {
        [displayName, biography, city].contains {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func applyProcessedPhoto() {
        guard let result = mediaState.result else { return }
        photoReference = result.localURL.path
    }

    private func save() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await state.save(
                    displayName: displayName,
                    biography: biography,
                    city: city,
                    localPhotoReference: photoReference
                )
                dismiss()
            } catch let error as DomainError {
                errorMessage = CoachFormatting.reason(error)
            } catch {
                errorMessage = String(
                    localized: "coach.error.generic",
                    defaultValue: "Terjadi kendala. Coba lagi."
                )
            }
        }
    }

    private func mediaErrorMessage(
        _ error: LocalMediaError
    ) -> String {
        switch error {
        case .unsupportedMIMEType:
            "Pilih gambar JPG, PNG, HEIC, atau HEIF."
        case .inputTooLarge:
            "Ukuran foto terlalu besar."
        case .invalidImage:
            "Foto tidak dapat dibaca."
        case .permissionDenied:
            "Izinkan akses Foto untuk memilih foto profil."
        case .cameraUnavailable, .cameraUsageDescriptionMissing:
            "Kamera tidak tersedia."
        case .processingFailed:
            "Foto gagal diproses. Coba pilih foto lain."
        }
    }
}
