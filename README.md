# Inkwell

An elegant Obsidian-inspired note-taking app with chat viewer for Android.

## Features

- **Markdown Notes** - Full markdown editor with live preview
- **Bi-directional Links** - `[[wiki-style links]]` with backlink tracking
- **Knowledge Graph** - Visual node graph showing note connections
- **Chat Viewer** - Card-based UI for AI conversation exports
- **Custom Formatter** - Convert Gemini/Google Docs exports to simplified chat format
- **Import/Export** - Individual and bulk `.zip` export
- **Beautiful Design** - Dark elegant theme with smooth animations

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Provider
- **Storage**: Local filesystem + SharedPreferences
- **UI**: Material Design 3 with custom theming

## Getting Started

### Prerequisites

- Flutter SDK 3.22.0 or higher
- Android Studio or VS Code
- Android SDK

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/juagamesacc-pixel/Inkwell.git
   cd Inkwell
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building APK

```bash
flutter build apk --release
```

The APK will be available at `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
lib/
├── main.dart              # App entry point
├── app.dart               # MaterialApp configuration
├── models/                # Data models
│   ├── note.dart
│   ├── chat_message.dart
│   └── link.dart
├── services/              # Business logic
│   ├── storage_service.dart
│   ├── settings_service.dart
│   ├── formatter_service.dart
│   ├── search_service.dart
│   └── link_service.dart
├── screens/               # UI screens
│   ├── home_screen.dart
│   ├── editor_screen.dart
│   ├── chat_viewer_screen.dart
│   ├── graph_screen.dart
│   └── settings_screen.dart
├── widgets/               # Reusable widgets
│   ├── note_card.dart
│   ├── chat_bubble.dart
│   ├── thought_bubble.dart
│   ├── animated_search_bar.dart
│   ├── custom_markdown_builder.dart
│   └── graph_painter.dart
├── theme/                 # Theming
│   ├── app_theme.dart
│   └── colors.dart
└── utils/                 # Utilities
    ├── markdown_parser.dart
    └── zip_handler.dart
```

## Features in Detail

### Chat Viewer
The chat viewer displays AI conversations in a beautiful card-based UI. It supports:
- Import from Gemini/Google Docs export format
- Display of model thoughts (collapsible)
- Timestamps for each message
- Different bubble styles (compact, comfortable, spacious)

### Custom Formatter
Convert complex Gemini export JSON to a simplified chat format:
```json
{
  "1": {
    "user": "user message",
    "thoughts": "model thinking process",
    "model": "model response",
    "time": "2024-01-01T00:00:00.000Z"
  }
}
```

### Knowledge Graph
Visualize your notes as a graph with:
- Force-directed layout
- Circular layout
- Tree layout
- Interactive zoom and pan
- Node selection and navigation

## Settings

Extensive UI customization options:
- Theme (Light/Dark/System)
- Accent colors (9 options)
- Font size (12-24px)
- Font family (Inter, JetBrains Mono, Fira Code)
- Animation speed (0.5x - 2x)
- Chat bubble style
- Graph layout
- And more...

## License

MIT License

## Author

juagamesacc-pixel
