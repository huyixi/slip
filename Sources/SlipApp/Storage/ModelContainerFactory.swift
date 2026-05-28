import Foundation
import SwiftData

enum ModelContainerFactory {
    @MainActor
    static func makeNoteStore() -> NoteStore {
        do {
            let container = try makePersistentContainer()
            return NoteStore(modelContext: ModelContext(container))
        } catch {
            let fallback = try! ModelContainer(
                for: Note.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            return NoteStore(modelContext: ModelContext(fallback))
        }
    }

    private static func makePersistentContainer() throws -> ModelContainer {
        let applicationSupportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let slipDirectoryURL = applicationSupportURL.appendingPathComponent("Slip", isDirectory: true)
        try FileManager.default.createDirectory(at: slipDirectoryURL, withIntermediateDirectories: true)

        let storeURL = slipDirectoryURL.appendingPathComponent("Slip.store")
        let configuration = ModelConfiguration(url: storeURL)
        return try ModelContainer(for: Note.self, configurations: configuration)
    }
}
