import SwiftData
import XCTest
@testable import SlipApp

@MainActor
final class NoteStoreTests: XCTestCase {
    private func makeStore(now: @escaping () -> Date = Date.init) throws -> NoteStore {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Note.self, configurations: configuration)
        return NoteStore(modelContext: ModelContext(container), now: now)
    }

    func testCreateNoteTrimsContentAndSortsNewestFirst() async throws {
        var dates = [
            Date(timeIntervalSince1970: 100),
            Date(timeIntervalSince1970: 200)
        ]
        let store = try makeStore {
            dates.removeFirst()
        }

        try store.createNote(content: " first ")
        try store.createNote(content: "\nsecond\n")

        await store.loadNotes()

        XCTAssertEqual(store.notes.map(\.content), ["second", "first"])
    }

    func testCreateNoteRejectsWhitespaceOnlyContent() async throws {
        let store = try makeStore()

        XCTAssertThrowsError(try store.createNote(content: " \n\t ")) { error in
            XCTAssertEqual(error as? NoteStoreError, .emptyContent)
        }

        await store.loadNotes()
        XCTAssertTrue(store.notes.isEmpty)
    }

    func testDeleteNoteRemovesItFromStore() async throws {
        let store = try makeStore()
        let note = try store.createNote(content: "temporary")

        try store.delete(note)
        await store.loadNotes()

        XCTAssertTrue(store.notes.isEmpty)
    }
}
