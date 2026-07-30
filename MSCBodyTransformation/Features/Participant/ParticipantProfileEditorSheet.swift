import PhotosUI
import SwiftUI

@MainActor
struct ParticipantProfileEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let store: ParticipantJourneyStore
    let profile: ParticipantProfile
    let email: String

    @State private var displayName: String
    @State private var phoneNumber: String
    @State private var photoReference: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var mediaState = LocalEvidenceMediaState()
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        store: ParticipantJourneyStore,
        profile: ParticipantProfile,
        email: String
    ) {
        self.store = store
        self.profile = profile
        self.email = email
        _displayName = State(initialValue: profile.displayName)
        _phoneNumber = State(initialValue: profile.phoneNumber ?? "")
        _photoReference = State(
            initialValue: profile.localPhotoReference
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
                        displayName
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                            || mediaState.isProcessing
                            || isSaving
                    )
                    .accessibilityIdentifier(
                        "participant.profile.editor.save"
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
        return Section {
            VStack(spacing: AppSpacing.medium) {
                UserAvatar(
                    displayName: displayName,
                    imageName: photoReference,
                    size: 112
                )
                .accessibilityIdentifier(
                    "participant.profile.editor.photo"
                )

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
                    "participant.profile.editor.photo-picker"
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
        Section("participant.profile.data") {
            LabeledContent("participant.profile.field.name") {
                TextField(
                    "participant.profile.field.name",
                    text: $displayName
                )
                .multilineTextAlignment(.trailing)
                .textContentType(.name)
                .accessibilityIdentifier(
                    "participant.profile.editor.name"
                )
            }

            LabeledContent("participant.profile.field.phone") {
                TextField(
                    "participant.profile.field.phone",
                    text: $phoneNumber
                )
                .multilineTextAlignment(.trailing)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .accessibilityIdentifier(
                    "participant.profile.editor.phone"
                )
            }

            LabeledContent(
                "participant.profile.field.email",
                value: email
            )
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
                try await store.updateParticipantProfile(
                    displayName: displayName,
                    phoneNumber: phoneNumber,
                    localPhotoReference: photoReference
                )
                dismiss()
            } catch let error as DomainError {
                errorMessage = ParticipantFormatting.fieldReason(error)
            } catch {
                errorMessage = String(
                    localized: "participant.error.generic"
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
