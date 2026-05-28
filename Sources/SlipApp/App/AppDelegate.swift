import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var coordinator: AppCoordinator?
    private var hotKeyService: GlobalHotKeyService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        hotKeyService = GlobalHotKeyService {
            Task { @MainActor [weak self] in
                self?.coordinator?.showCapturePanel()
            }
        }

        hotKeyService?.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyService?.unregister()
    }
}
