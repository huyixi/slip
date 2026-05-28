import SwiftData
import SwiftUI

@main
struct SlipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow

    @State private var coordinator: AppCoordinator

    init() {
        let coordinator = AppCoordinator(noteStore: ModelContainerFactory.makeNoteStore())
        _coordinator = State(initialValue: coordinator)
        appDelegate.coordinator = coordinator
    }

    var body: some Scene {
        Window("Slip", id: "main") {
            NotesWindowView()
                .environment(coordinator)
                .frame(minWidth: 640, minHeight: 420)
                .onAppear {
                    appDelegate.coordinator = coordinator
                    coordinator.configure {
                        openWindow(id: "main")
                    }
                }
                .task {
                    await coordinator.noteStore.loadNotes()
                }
        }
        .defaultSize(width: 900, height: 640)
        .windowResizability(.contentMinSize)

        MenuBarExtra("Slip", systemImage: "note.text") {
            Button("New Note") {
                coordinator.showCapturePanel()
            }

            Button("Open Notes") {
                coordinator.showMainWindow()
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
    }
}
