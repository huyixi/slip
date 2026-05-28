import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppCoordinator {
    let noteStore: NoteStore
    let clipboardService: ClipboardService

    private var capturePanelController: CapturePanelController?
    private var openMainWindowHandler: (() -> Void)?

    init(noteStore: NoteStore, clipboardService: ClipboardService = ClipboardService()) {
        self.noteStore = noteStore
        self.clipboardService = clipboardService
    }

    func configure(openMainWindow: @escaping () -> Void) {
        openMainWindowHandler = openMainWindow
    }

    func showMainWindow() {
        openMainWindowHandler?()
        NSApp.activate(ignoringOtherApps: true)
    }

    func showCapturePanel() {
        if capturePanelController == nil {
            capturePanelController = CapturePanelController { [weak self] content in
                Task { @MainActor in
                    guard let self else { return }

                    do {
                        try self.noteStore.createNote(content: content)
                        self.closeCapturePanel()
                        self.showMainWindow()
                    } catch NoteStoreError.emptyContent {
                        return
                    } catch {
                        return
                    }
                }
            }
        }

        capturePanelController?.show()
    }

    func closeCapturePanel() {
        capturePanelController?.close()
    }
}
