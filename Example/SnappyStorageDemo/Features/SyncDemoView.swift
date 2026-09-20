import SwiftUI
import SnappyStorage

struct SyncDemoView: View {

    // MARK: - Properties

    private let service = Service<Note>()

    @State private var notes: [Note] = []
    @State private var newTitle = ""
    @State private var newBody = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Add Note") {
                    TextField("Title", text: $newTitle)
                    TextField("Body", text: $newBody)
                    Button("Save") { addNote() }
                        .disabled(newTitle.isEmpty)
                }
                Section("Notes (\(notes.count))") {
                    ForEach(notes) { note in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.title).font(.headline)
                            if !note.body.isEmpty {
                                Text(note.body).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteNotes)
                }
            }
            .navigationTitle("Sync — Service<T>")
            .toolbar { EditButton() }
            .onAppear { reload() }
        }
    }

    // MARK: - Helpers

    private func addNote() {
        let note = Note(title: newTitle, body: newBody)
        service.save(note)
        newTitle = ""
        newBody = ""
        reload()
    }

    private func deleteNotes(at offsets: IndexSet) {
        offsets.forEach { service.delete(notes[$0]) }
        reload()
    }

    private func reload() {
        notes = service.fetchAll().sorted { $0.createdAt < $1.createdAt }
    }
}
