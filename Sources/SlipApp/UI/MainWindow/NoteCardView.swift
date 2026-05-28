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
        .frame(width: 240, alignment: .topLeading)
        .frame(minHeight: 150, alignment: .topLeading)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
