# Slip MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS menu bar inbox app where users press `Cmd + Option + N`, capture a plain-text note, save it locally, and review, copy, or delete notes in an Apple Notes-like card wall.

**Architecture:** Use a small SwiftPM-based macOS SwiftUI app so the project can be built and tested from the command line before an Xcode project is introduced. Keep AppKit-only responsibilities in focused services: the global hotkey service registers `Cmd + Option + N`, and the capture panel controller owns the floating `NSPanel`. Keep SwiftData persistence behind a `NoteStore` so unit tests can exercise note creation, deletion, sorting, and empty-content rejection with an in-memory container.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit, SwiftData, Carbon global hotkey APIs, XCTest, Swift Package Manager, macOS 14+.

---

## File Structure

- Create: `Package.swift`  
  Declares the macOS executable target and test target.
- Create: `Makefile`  
  Provides `make build`, `make test`, `make run`, and `make app` commands.
- Create: `Sources/SlipApp/SlipApp.swift`  
  SwiftUI app entry point, menu bar extra, main window scene, and app lifecycle wiring.
- Create: `Sources/SlipApp/App/AppDelegate.swift`  
  Coordinates startup, activation policy, global hotkey registration, and panel/window presentation.
- Create: `Sources/SlipApp/App/AppCoordinator.swift`  
  Shared object that owns `NoteStore`, `ClipboardService`, and UI presentation commands.
- Create: `Sources/SlipApp/Models/Note.swift`  
  SwiftData note model with `id`, `content`, `createdAt`, and `updatedAt`.
- Create: `Sources/SlipApp/Storage/NoteStore.swift`  
  Main actor store for create, load, delete, and sorted note state.
- Create: `Sources/SlipApp/Services/ClipboardService.swift`  
  Copies complete note content to the macOS pasteboard.
- Create: `Sources/SlipApp/Services/GlobalHotKeyService.swift`  
  Registers and unregisters the `Cmd + Option + N` hotkey through Carbon.
- Create: `Sources/SlipApp/UI/Capture/CapturePanelController.swift`  
  Creates, centers, focuses, and closes the quick capture `NSPanel`.
- Create: `Sources/SlipApp/UI/Capture/CaptureView.swift`  
  Plain-text capture input with `Cmd + Enter` save and `Esc` close.
- Create: `Sources/SlipApp/UI/MainWindow/NotesWindowView.swift`  
  Main window layout with search placeholder and responsive note grid.
- Create: `Sources/SlipApp/UI/MainWindow/NoteCardView.swift`  
  Note preview card with created time, Copy, and Delete actions.
- Create: `Sources/SlipApp/Support/DateFormatting.swift`  
  User-facing created-time formatting for note cards.
- Create: `Tests/SlipAppTests/NoteStoreTests.swift`  
  Tests note persistence behavior with an in-memory SwiftData container.
- Create: `Tests/SlipAppTests/DateFormattingTests.swift`  
  Tests card timestamp labels.
- Modify: `README.md`  
  Add local build, test, run, and MVP scope notes.

---

### Task 1: Create the SwiftPM macOS App Skeleton

**Files:**
- Create: `Package.swift`
- Create: `Makefile`
- Create: `Sources/SlipApp/SlipApp.swift`
- Create: `Sources/SlipApp/App/AppDelegate.swift`
- Create: `Sources/SlipApp/App/AppCoordinator.swift`

- [ ] **Step 1: Add the Swift package manifest**

Create `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Slip",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Slip", targets: ["SlipApp"])
    ],
    targets: [
        .executableTarget(
            name: "SlipApp",
            path: "Sources/SlipApp"
        ),
        .testTarget(
            name: "SlipAppTests",
            dependencies: ["SlipApp"],
            path: "Tests/SlipAppTests"
        )
    ]
)
```

- [ ] **Step 2: Add command helpers**

Create `Makefile`:

```make
.PHONY: build test run app clean

build:
	swift build

test:
	swift test

run:
	swift run Slip

app: build
	rm -rf .build/Slip.app
	mkdir -p .build/Slip.app/Contents/MacOS
	mkdir -p .build/Slip.app/Contents/Resources
	cp .build/debug/Slip .build/Slip.app/Contents/MacOS/Slip
	/usr/libexec/PlistBuddy -c "Clear dict" .build/Slip.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string Slip" .build/Slip.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string app.slip.mvp" .build/Slip.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :CFBundleName string Slip" .build/Slip.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" .build/Slip.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 14.0" .build/Slip.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" .build/Slip.app/Contents/Info.plist

clean:
	rm -rf .build
```

- [ ] **Step 3: Create the app coordinator**

Create `Sources/SlipApp/App/AppCoordinator.swift`:

```swift
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
                    try? self?.noteStore.createNote(content: content)
                    self?.showMainWindow()
                }
            }
        }

        capturePanelController?.show()
    }

    func closeCapturePanel() {
        capturePanelController?.close()
    }
}
```

- [ ] **Step 4: Create the app delegate**

Create `Sources/SlipApp/App/AppDelegate.swift`:

```swift
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
```

- [ ] **Step 5: Create the SwiftUI entry point**

Create `Sources/SlipApp/SlipApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct SlipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow

    @State private var coordinator: AppCoordinator

    init() {
        let container = try! ModelContainer(for: Note.self)
        let store = NoteStore(modelContext: ModelContext(container))
        _coordinator = State(initialValue: AppCoordinator(noteStore: store))
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
```

- [ ] **Step 6: Build and capture missing-type failures**

Run:

```bash
make build
```

Expected: build fails with errors for the types that later tasks create, including `Note`, `NoteStore`, `ClipboardService`, `CapturePanelController`, `GlobalHotKeyService`, and `NotesWindowView`.

- [ ] **Step 7: Commit the skeleton**

```bash
git add Package.swift Makefile Sources/SlipApp/SlipApp.swift Sources/SlipApp/App/AppDelegate.swift Sources/SlipApp/App/AppCoordinator.swift
git commit -m "chore: add macOS app skeleton"
```

---

### Task 2: Implement the Note Model and SwiftData Store

**Files:**
- Create: `Sources/SlipApp/Models/Note.swift`
- Create: `Sources/SlipApp/Storage/NoteStore.swift`
- Create: `Tests/SlipAppTests/NoteStoreTests.swift`

- [ ] **Step 1: Write failing persistence tests**

Create `Tests/SlipAppTests/NoteStoreTests.swift`:

```swift
import XCTest
import SwiftData
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter NoteStoreTests
```

Expected: FAIL because `Note`, `NoteStore`, and `NoteStoreError` do not exist.

- [ ] **Step 3: Add the SwiftData note model**

Create `Sources/SlipApp/Models/Note.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Note: Identifiable {
    @Attribute(.unique) var id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

- [ ] **Step 4: Add the store**

Create `Sources/SlipApp/Storage/NoteStore.swift`:

```swift
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
        let descriptor = FetchDescriptor<Note>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        notes = (try? modelContext.fetch(descriptor)) ?? []
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
```

- [ ] **Step 5: Run store tests**

Run:

```bash
swift test --filter NoteStoreTests
```

Expected: PASS.

- [ ] **Step 6: Commit the data layer**

```bash
git add Sources/SlipApp/Models/Note.swift Sources/SlipApp/Storage/NoteStore.swift Tests/SlipAppTests/NoteStoreTests.swift
git commit -m "feat: add local note persistence"
```

---

### Task 3: Implement Clipboard and Date Formatting Support

**Files:**
- Create: `Sources/SlipApp/Services/ClipboardService.swift`
- Create: `Sources/SlipApp/Support/DateFormatting.swift`
- Create: `Tests/SlipAppTests/DateFormattingTests.swift`

- [ ] **Step 1: Write failing date formatting tests**

Create `Tests/SlipAppTests/DateFormattingTests.swift`:

```swift
import XCTest
@testable import SlipApp

final class DateFormattingTests: XCTestCase {
    func testFormatsTodayAsTime() {
        let calendar = Calendar(identifier: .gregorian)
        let formatter = NoteDateFormatter(calendar: calendar)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let label = formatter.label(for: now, relativeTo: now)

        XCTAssertFalse(label.isEmpty)
        XCTAssertTrue(label.contains(":"))
    }

    func testFormatsYesterdayAsYesterday() {
        let calendar = Calendar(identifier: .gregorian)
        let formatter = NoteDateFormatter(calendar: calendar)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!

        XCTAssertEqual(formatter.label(for: yesterday, relativeTo: now), "Yesterday")
    }
}
```

- [ ] **Step 2: Run tests to verify formatter failure**

Run:

```bash
swift test --filter DateFormattingTests
```

Expected: FAIL because `NoteDateFormatter` does not exist.

- [ ] **Step 3: Add date formatting**

Create `Sources/SlipApp/Support/DateFormatting.swift`:

```swift
import Foundation

struct NoteDateFormatter {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func label(for date: Date, relativeTo now: Date = Date()) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return date.formatted(date: .omitted, time: .shortened)
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        }

        return date.formatted(date: .abbreviated, time: .omitted)
    }
}
```

- [ ] **Step 4: Add clipboard service**

Create `Sources/SlipApp/Services/ClipboardService.swift`:

```swift
import AppKit

struct ClipboardService {
    func copy(_ content: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }
}
```

- [ ] **Step 5: Run support tests**

Run:

```bash
swift test --filter DateFormattingTests
```

Expected: PASS.

- [ ] **Step 6: Commit support services**

```bash
git add Sources/SlipApp/Services/ClipboardService.swift Sources/SlipApp/Support/DateFormatting.swift Tests/SlipAppTests/DateFormattingTests.swift
git commit -m "feat: add note support services"
```

---

### Task 4: Implement the Global Hotkey Service

**Files:**
- Create: `Sources/SlipApp/Services/GlobalHotKeyService.swift`

- [ ] **Step 1: Add the Carbon global hotkey service**

Create `Sources/SlipApp/Services/GlobalHotKeyService.swift`:

```swift
import Carbon
import Foundation

final class GlobalHotKeyService {
    private let onPressed: () -> Void
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?

    init(onPressed: @escaping () -> Void) {
        self.onPressed = onPressed
    }

    func register() {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else {
                    return noErr
                }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr, hotKeyID.id == 1 else {
                    return noErr
                }

                let service = Unmanaged<GlobalHotKeyService>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                service.onPressed()
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )

        var hotKeyID = EventHotKeyID(signature: OSType(0x534C4950), id: 1)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_N),
            UInt32(cmdKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    deinit {
        unregister()
    }
}
```

- [ ] **Step 2: Build to validate Carbon integration**

Run:

```bash
make build
```

Expected: build still fails only for the missing UI types from later tasks.

- [ ] **Step 3: Commit hotkey service**

```bash
git add Sources/SlipApp/Services/GlobalHotKeyService.swift
git commit -m "feat: register global note hotkey"
```

---

### Task 5: Implement the Quick Capture Panel

**Files:**
- Create: `Sources/SlipApp/UI/Capture/CapturePanelController.swift`
- Create: `Sources/SlipApp/UI/Capture/CaptureView.swift`

- [ ] **Step 1: Create the capture view**

Create `Sources/SlipApp/UI/Capture/CaptureView.swift`:

```swift
import SwiftUI

struct CaptureView: View {
    @State private var content = ""
    @FocusState private var isTextFocused: Bool

    let onSave: (String) -> Void
    let onClose: () -> Void

    private var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextEditor(text: $content)
                .font(.system(size: 17, weight: .regular, design: .default))
                .scrollContentBackground(.hidden)
                .focused($isTextFocused)
                .overlay(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("Write a note...")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }

            HStack {
                Text("⌘↩ Save")
                    .foregroundStyle(canSave ? .secondary : .tertiary)

                Spacer()

                Text("Esc Close")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 12, weight: .medium))
        }
        .padding(20)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            DispatchQueue.main.async {
                isTextFocused = true
            }
        }
        .onExitCommand {
            onClose()
        }
        .overlay {
            Button("Save") {
                save()
            }
            .keyboardShortcut(.return, modifiers: .command)
            .opacity(0)
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
        }
    }

    private func save() {
        guard canSave else { return }
        onSave(content)
        content = ""
    }
}
```

- [ ] **Step 2: Create the panel controller**

Create `Sources/SlipApp/UI/Capture/CapturePanelController.swift`:

```swift
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
                self?.close()
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
```

- [ ] **Step 3: Build and manually verify capture panel**

Run:

```bash
make run
```

Expected:
- The app starts as a menu bar app.
- Selecting `New Note` opens a centered `520 × 220` panel.
- The text input is focused.
- `Esc` closes the panel without saving.
- Empty `Cmd + Enter` does not create a note.

- [ ] **Step 4: Commit capture UI**

```bash
git add Sources/SlipApp/UI/Capture/CapturePanelController.swift Sources/SlipApp/UI/Capture/CaptureView.swift
git commit -m "feat: add quick capture panel"
```

---

### Task 6: Implement the Main Notes Window and Cards

**Files:**
- Create: `Sources/SlipApp/UI/MainWindow/NotesWindowView.swift`
- Create: `Sources/SlipApp/UI/MainWindow/NoteCardView.swift`

- [ ] **Step 1: Create the note card view**

Create `Sources/SlipApp/UI/MainWindow/NoteCardView.swift`:

```swift
import SwiftUI

struct NoteCardView: View {
    let note: Note
    let dateFormatter: NoteDateFormatter
    let onCopy: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(note.content)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .lineLimit(8)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Text(dateFormatter.label(for: note.createdAt))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete")
            }
        }
        .padding(14)
        .frame(width: 240, minHeight: 150, alignment: .topLeading)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
```

- [ ] **Step 2: Create the main window**

Create `Sources/SlipApp/UI/MainWindow/NotesWindowView.swift`:

```swift
import SwiftUI

struct NotesWindowView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var searchText = ""

    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 18, alignment: .top)
    ]

    var body: some View {
        VStack(spacing: 0) {
            searchBar

            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                    ForEach(coordinator.noteStore.notes) { note in
                        NoteCardView(
                            note: note,
                            dateFormatter: NoteDateFormatter(),
                            onCopy: {
                                coordinator.clipboardService.copy(note.content)
                            },
                            onDelete: {
                                try? coordinator.noteStore.delete(note)
                            }
                        )
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .disabled(true)
        }
        .padding(.horizontal, 24)
        .frame(height: 64)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.5))
                .frame(height: 1)
        }
    }
}
```

- [ ] **Step 3: Build and manually verify main window**

Run:

```bash
make run
```

Expected:
- Selecting `Open Notes` opens a `900 × 640` main window.
- Window cannot shrink below `640 × 420`.
- Search field is visible but disabled and does not filter notes.
- Notes appear as a responsive card grid.
- Long content is truncated after 8 lines.
- Copy copies the full content.
- Delete removes the note immediately.

- [ ] **Step 4: Commit main window UI**

```bash
git add Sources/SlipApp/UI/MainWindow/NotesWindowView.swift Sources/SlipApp/UI/MainWindow/NoteCardView.swift
git commit -m "feat: add notes card wall"
```

---

### Task 7: Wire Menu Bar Actions, Save Flow, and Reload Behavior

**Files:**
- Modify: `Sources/SlipApp/SlipApp.swift`
- Modify: `Sources/SlipApp/App/AppCoordinator.swift`
- Modify: `Sources/SlipApp/UI/Capture/CaptureView.swift`
- Modify: `Sources/SlipApp/UI/Capture/CapturePanelController.swift`

- [ ] **Step 1: Ensure saved notes reload into the main window**

Modify the save callback in `Sources/SlipApp/App/AppCoordinator.swift` to close the panel only after a successful create:

```swift
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
```

- [ ] **Step 2: Remove duplicate panel closing from the controller save callback**

Modify `Sources/SlipApp/UI/Capture/CapturePanelController.swift` so the controller delegates save decisions to the coordinator:

```swift
let rootView = CaptureView(
    onSave: { [weak self] content in
        self?.onSave(content)
    },
    onClose: { [weak self] in
        self?.close()
    }
)
```

- [ ] **Step 3: Keep typed content when empty save is rejected**

Modify the command-return block in `Sources/SlipApp/UI/Capture/CaptureView.swift` so it clears content only after sending non-empty content:

```swift
private func save() {
    guard canSave else { return }
    onSave(content)
    content = ""
}
```

- [ ] **Step 4: Build the fully wired app**

Run:

```bash
make build
```

Expected: PASS.

- [ ] **Step 5: Manually verify the core path**

Run:

```bash
make run
```

Expected:
- `Cmd + Option + N` opens the capture panel while the app is in the background.
- Typing `hello slip` then pressing `Cmd + Enter` saves the note.
- The panel closes after save.
- The main window opens and shows the new note.
- Pressing `Esc` in the capture panel closes it without creating a note.

- [ ] **Step 6: Commit integration**

```bash
git add Sources/SlipApp/SlipApp.swift Sources/SlipApp/App/AppCoordinator.swift Sources/SlipApp/UI/Capture/CaptureView.swift Sources/SlipApp/UI/Capture/CapturePanelController.swift
git commit -m "feat: wire capture save flow"
```

---

### Task 8: Add App Bundle Packaging and Persistence Verification

**Files:**
- Modify: `Makefile`
- Modify: `README.md`

- [ ] **Step 1: Build the app bundle**

Run:

```bash
make app
```

Expected:
- `.build/Slip.app` exists.
- `.build/Slip.app/Contents/MacOS/Slip` exists.
- `.build/Slip.app/Contents/Info.plist` contains `LSUIElement` set to `true`.

- [ ] **Step 2: Launch the bundle**

Run:

```bash
open .build/Slip.app
```

Expected:
- Slip appears in the macOS menu bar.
- It does not show as a normal Dock app.
- `New Note`, `Open Notes`, and `Quit` are available from the menu bar extra.

- [ ] **Step 3: Verify notes persist after restart**

Manual verification:
- Open `.build/Slip.app`.
- Capture a note with content `persistent note`.
- Quit from the menu bar.
- Open `.build/Slip.app` again.
- Select `Open Notes`.

Expected: the `persistent note` card is still visible.

- [ ] **Step 4: Update README**

Modify `README.md`:

````markdown
# slip

Slip is a native macOS quick-capture inbox for temporary plain-text notes.

## MVP scope

- Menu bar app
- Global shortcut: `Cmd + Option + N`
- Quick capture panel
- Local note persistence
- Apple Notes-like card wall
- Copy and delete note content

## Development

```bash
make build
make test
make run
make app
```

The MVP targets macOS 14+ because it uses SwiftData.
````

- [ ] **Step 5: Commit packaging and docs**

```bash
git add Makefile README.md
git commit -m "chore: document app build workflow"
```

---

### Task 9: Final MVP Acceptance Pass

**Files:**
- No file changes expected unless a verification step fails.

- [ ] **Step 1: Run automated checks**

Run:

```bash
make test
make build
make app
```

Expected: all commands pass.

- [ ] **Step 2: Verify acceptance criteria manually**

Run:

```bash
open .build/Slip.app
```

Checklist:
- [ ] App in background: `Cmd + Option + N` opens quick capture panel.
- [ ] Panel opens centered.
- [ ] Text input is focused.
- [ ] Plain text can be typed.
- [ ] `Cmd + Enter` saves non-empty content.
- [ ] Empty content does not create a note.
- [ ] `Esc` closes without saving.
- [ ] Saved note appears in the main window card wall.
- [ ] Search UI is present and does not filter content.
- [ ] Long note content shows only a 6 to 8 line preview.
- [ ] Copy copies full note content.
- [ ] Delete removes the note.
- [ ] Quit and relaunch preserves saved notes.

- [ ] **Step 3: Confirm out-of-scope features remain absent**

Checklist:
- [ ] No edit note action.
- [ ] No note detail panel.
- [ ] No sidebar.
- [ ] No folders.
- [ ] No tags.
- [ ] No archive.
- [ ] No pinning.
- [ ] No markdown preview.
- [ ] No rich text toolbar.
- [ ] No AI feature.
- [ ] No sync feature.

- [ ] **Step 4: Commit final verification fixes only if needed**

If a verification fix was made, run `git status --short`, stage only the files changed by that verification fix, and commit them with this message:

```bash
git commit -m "fix: complete mvp acceptance flow"
```

If no verification fix was made, do not create an empty commit.

---

## Spec Coverage Review

- Product positioning: covered by the README update and app scope in Tasks 1, 8, and 9.
- Capture first, review only: enforced by one write entry point in Tasks 5 and 7, and read-only cards in Task 6.
- Core user path: implemented across Tasks 4, 5, 6, and 7.
- Menu bar app: implemented in Task 1 and verified in Task 8.
- Global shortcut `Cmd + Option + N`: implemented in Task 4 and verified in Task 9.
- Quick capture panel: implemented in Task 5 and integrated in Task 7.
- Plain-text input: implemented with `TextEditor` in Task 5.
- `Cmd + Enter` save and `Esc` close: implemented in Task 5 and verified in Task 7.
- Empty content rejection: implemented and tested in Task 2.
- Local persistence: implemented and tested in Task 2, verified after restart in Task 8.
- Main window card wall: implemented in Task 6.
- Search UI placeholder only: implemented as disabled UI in Task 6 and verified in Task 9.
- Note content preview and created time: implemented in Task 6 with date support from Task 3.
- Copy complete content: implemented in Tasks 3 and 6.
- Delete note: implemented in Tasks 2 and 6.
- Long text truncation: implemented with `lineLimit(8)` in Task 6.
- Apple Notes-like visual style: implemented through low-density layout, light borders, weak shadow, card spacing, and native colors in Task 6.
- Out-of-scope exclusions: verified explicitly in Task 9.
