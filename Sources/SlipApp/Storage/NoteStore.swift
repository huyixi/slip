import Foundation
import Observation
import SwiftData

enum NoteStoreError: Error, Equatable {
    case emptyContent
}

@MainActor
@Observable
final class NoteStore {
    private let modelContext: ModelContext
    private let now: () -> Date
    private(set) var notes: [Note] = []

    init(modelContext: ModelContext, now: @escaping () -> Date = Date.init) {
        self.modelContext = modelContext
        self.now = now
    }

    func loadNotes() async {
        refreshSynchronously()
    }

    @discardableResult
    func createNote(content rawContent: String) throws -> Note {
        let content = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !content.isEmpty else {
            throw NoteStoreError.emptyContent
        }

        let timestamp = now()
        let note = Note(content: content, createdAt: timestamp, updatedAt: timestamp)
        modelContext.insert(note)
        try modelContext.save()
        refreshSynchronously()
        return note
    }

    func delete(_ note: Note) throws {
        modelContext.delete(note)
        try modelContext.save()
        refreshSynchronously()
    }

    private func refreshSynchronously() {
        let descriptor = FetchDescriptor<Note>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        notes = (try? modelContext.fetch(descriptor)) ?? []
    }
}
