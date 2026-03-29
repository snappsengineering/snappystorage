import SwiftUI
import SnappyStorage

// Demonstrates the synchronous Service<T> layer.
//
// Service<T> is a subclassable class that stores a Set<T> backed by a JSON file.
// All reads and writes are synchronous — no callbacks, publishers, or async/await required.
// Use it directly or subclass it to add domain-specific queries.
//
// Storage location:
//   .documentDirectory  — user-visible, backed up, accessible in Files app.
//                         Use for user-created content.
//   .applicationSupportDirectory — not user-visible, backed up.
//                         Use for app state and service data.
struct SyncDemoView: View {

    // Service<Note> uses documentDirectory by default.
    // fileName defaults to the type name ("Note"), producing Note.json.
    private let service = Service<Note>()

    @State private var notes: [Note] = []
    @State private var newTitle = ""
    @State private var newBody = ""

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

    // fetchAll() returns Set<Note>. Sort for stable display order.
    private func reload() {
        notes = service.fetchAll().sorted { $0.createdAt < $1.createdAt }
    }
}
