import SwiftUI
import SnappyStorage

// MARK: - AsyncNoteViewModel

@MainActor
final class AsyncNoteViewModel: ObservableObject {

    // MARK: - Properties

    @Published var notes: [Note] = []

    private let service = try! ActorService<Note>(
        destination: .local(.documentDirectory),
        fileName: "NotesActor"
    )

    // MARK: - Public

    func observeUpdates() async {
        for await collection in await service.updates {
            notes = collection.sorted { $0.createdAt < $1.createdAt }
        }
    }

    func addNote(title: String, body: String) async {
        await service.save(Note(title: title, body: body))
    }

    func deleteNote(_ note: Note) async {
        await service.delete(note)
    }
}

// MARK: - AsyncDemoView

struct AsyncDemoView: View {

    // MARK: - Properties

    @StateObject private var viewModel = AsyncNoteViewModel()
    @State private var newTitle = ""
    @State private var newBody = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Add Note") {
                    TextField("Title", text: $newTitle)
                    TextField("Body", text: $newBody)
                    Button("Save") {
                        let title = newTitle
                        let body = newBody
                        newTitle = ""
                        newBody = ""
                        Task { await viewModel.addNote(title: title, body: body) }
                    }
                    .disabled(newTitle.isEmpty)
                }
                Section("Notes (\(viewModel.notes.count))") {
                    ForEach(viewModel.notes) { note in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.title).font(.headline)
                            if !note.body.isEmpty {
                                Text(note.body).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        offsets.forEach { index in
                            let note = viewModel.notes[index]
                            Task { await viewModel.deleteNote(note) }
                        }
                    }
                }
            }
            .navigationTitle("Async — ActorService<T>")
            .toolbar { EditButton() }
            .task { await viewModel.observeUpdates() }
        }
    }
}
