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
