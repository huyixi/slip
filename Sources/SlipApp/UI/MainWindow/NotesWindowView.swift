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
