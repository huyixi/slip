import AppKit
import SwiftUI

@MainActor
final class CapturePanelController: NSObject, NSWindowDelegate {
    private let onSave: (String) -> Void
    private var panel: NSPanel?

    init(onSave: @escaping (String) -> Void) {
        self.onSave = onSave
    }

    func show() {
        if panel == nil {
            panel = makePanel()
        }

        guard let panel else { return }

        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let rootView = CaptureView(
            onSave: { [weak self] content in
                self?.onSave(content)
            },
            onClose: { [weak self] in
                self?.close()
            }
        )

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 220),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.contentView = NSHostingView(rootView: rootView)
        panel.backgroundColor = .windowBackgroundColor
        panel.hasShadow = true
        return panel
    }
}
