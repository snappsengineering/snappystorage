import SwiftUI
import Combine
import SnappyStorage

// MARK: - NotePublishedService

final class NotePublishedService: PublishedService<Note> {

    // MARK: - Lifecycle

    init() {
        super.init(destination: .local(.documentDirectory), fileName: "NotesCombine")
    }
}

// MARK: - CombineDemoView

struct CombineDemoView: View {

    // MARK: - Properties

    @StateObject private var service = NotePublishedService()
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

    // MARK: - Helpers

    private var sortedNotes: [Note] {
        service.published.sorted { $0.createdAt < $1.createdAt }
    }

    private func addNote() {
        service.save(Note(title: newTitle, body: newBody))
        newTitle = ""
        newBody = ""
    }
}
