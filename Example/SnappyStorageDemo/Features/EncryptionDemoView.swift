import SwiftUI
import PhotosUI
import SnappyStorage

struct EncryptionDemoView: View {

    // MARK: - Properties

    private let prefsService = SingleValueService<UserPreferences>(
        destination: .local(.documentDirectory),
        fileName: "UserPreferences"
    )
    @State private var prefs = UserPreferences()

    private let photoService = Service<Photo>(
        destination: .local(.documentDirectory),
        fileName: "Photos",
        encryption: Encryption(keyString: "demo-secret-replace-with-keychain-key")
    )
    @State private var photos: [Photo] = []
    @State private var pickerItem: PhotosPickerItem?
    @State private var caption = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                preferencesSection
                photosSection
            }
            .navigationTitle("Encryption + Single Value")
            .onAppear { loadAll() }
            .onChange(of: pickerItem) { _, item in
                Task { await savePickedPhoto(item) }
            }
        }
    }

    // MARK: - SingleValueService views

    private var preferencesSection: some View {
        Section {
            TextField("Display Name", text: $prefs.displayName)
                .onChange(of: prefs.displayName) { _, _ in savePrefs() }
            Toggle("Notifications", isOn: $prefs.notificationsEnabled)
                .onChange(of: prefs.notificationsEnabled) { _, _ in savePrefs() }
        } header: {
            Text("User Preferences — SingleValueService<T>")
        } footer: {
            Text("Stored as a single UserPreferences.json. Persists across app launches.")
        }
    }

    // MARK: - Encrypted photos views

    private var photosSection: some View {
        Section {
            TextField("Caption (optional)", text: $caption)
            PhotosPicker("Pick a Photo — saved encrypted", selection: $pickerItem, matching: .images)
            ForEach(photos) { photo in
                HStack(spacing: 12) {
                    if let uiImage = UIImage(data: photo.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipped()
                            .cornerRadius(8)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(photo.caption.isEmpty ? "(no caption)" : photo.caption)
                            .font(.subheadline)
                        Text(photo.savedAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { offsets in
                offsets.forEach { photoService.delete(photos[$0]) }
                loadPhotos()
            }
        } header: {
            Text("Encrypted Photos — Service<Photo> + Encryption")
        } footer: {
            Text("Photos are AES-256-GCM encrypted on disk. Opening Photos.json in a file browser shows only ciphertext.")
        }
    }

    // MARK: - Helpers

    private func loadAll() {
        prefs = prefsService.fetch() ?? UserPreferences()
        loadPhotos()
    }

    private func loadPhotos() {
        photos = photoService.fetchAll().sorted { $0.savedAt < $1.savedAt }
    }

    private func savePrefs() {
        try? prefsService.save(prefs)
    }

    private func savePickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self) else { return }
        photoService.save(Photo(imageData: data, caption: caption))
        caption = ""
        pickerItem = nil
        loadPhotos()
    }
}
