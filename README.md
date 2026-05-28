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
