import SwiftUI
import Combine
import SnappyStorage

// Demonstrates the Combine-reactive PublishedService<T> layer.
//
// PublishedService<T> subclasses Service<T> and adds a @Published var published: Set<T>.
// published updates automatically on every save() and delete() — no manual reload() needed.
//
// Usage: subclass PublishedService<T> and use it as @StateObject.
// SwiftUI's @Published binding drives automatic view redraws.

final class NotePublishedService: PublishedService<Note> {
    init() {
        // Use a distinct fileName to keep this demo's data separate from SyncDemoView.
        super.init(destination: .local(.documentDirectory), fileName: "NotesCombine")
    }
}

struct CombineDemoView: View {

    @StateObject private var service = NotePublishedService()
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
                // service.published is @Published — the list rebuilds automatically
                // whenever service.save() or service.delete() is called.
                Section("Notes (\(service.published.count))") {
                    ForEach(sortedNotes) { note in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.title).font(.headline)
                            if !note.body.isEmpty {
                                Text(note.body).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        offsets.forEach { service.delete(sortedNotes[$0]) }
                    }
                }
            }
            .navigationTitle("Combine — PublishedService<T>")
            .toolbar { EditButton() }
        }
    }

    private var sortedNotes: [Note] {
        service.published.sorted { $0.createdAt < $1.createdAt }
    }

    private func addNote() {
        service.save(Note(title: newTitle, body: newBody))
        newTitle = ""
        newBody = ""
    }
}
