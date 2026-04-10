<div align="center">

<img src="assets\ic_launcher.png" alt="linkist Logo" width="96" height="96" />

# linkist

**A minimal, fast, and privacy-first link manager built with Flutter.**

Save, organise, and access your URLs — all stored locally on your device.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-lightgrey?logo=android)](https://flutter.dev/docs/deployment/android)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![GitHub Stars](https://img.shields.io/github/stars/debapriya2003/linkist?style=social)](https://github.com/debapriya2003/linkist)

[Features](#-features) · [Screenshots](#-screenshots) · [Getting Started](#-getting-started) · [Architecture](#-architecture) · [Contributing](#-contributing) · [Roadmap](#-roadmap)

</div>

---

## Overview

linkist is an open-source, offline-first link manager for Android and iOS. It stores everything locally in SQLite — no accounts, no cloud sync, no tracking. Your data stays on your device.

When you paste a URL, linkist automatically fetches the page title, description, and favicon so you never have to type metadata by hand. Links can be organised with custom categories and tags, searched instantly, and exported to a portable JSON file so you can move to a new device without losing anything.

---

## ✨ Features

### Core
- **Save links** with title, URL, description, category, and tags
- **Full-text search** across title, URL, description, and tags simultaneously
- **Category & tag filtering** via one-tap chip bar
- **Favorites** — star any link and filter to starred-only view
- **One-click copy** URL to clipboard
- **Open in browser** with native app handoff
- **Swipe actions** — swipe left to edit or delete, right to favorite
- **Sort** by Newest, Oldest, Title A–Z, or Most Visited
- **Compact / expanded** list view toggle
- **Visit count tracking** per link

### Smart Metadata
- **Auto-fetch page title** from `<title>` and Open Graph tags on paste
- **Favicon display** via Google's favicon service with local fallback
- **Smart tag suggestions** from domain heuristics (e.g. `github.com` → `dev`, `youtube.com` → `video`)
- **Description scraping** from `og:description` and `<meta name="description">`

### Backup & Restore
- **Export to JSON** — human-readable, versioned backup format
- **Share backup** via any installed app (email, Drive, WhatsApp, AirDrop…)
- **Save to device** — Downloads on Android, Documents on iOS
- **Import from file** with three conflict strategies: Skip, Overwrite, or Keep Both
- **Import preview** — inspect link count and export date before committing

### Design & UX
- **Material 3** design system throughout
- **Dark and light themes** — system-default aware
- **Space Grotesk + Inter** typography pairing
- **Staggered list animations** on load
- **Responsive layout** for phones and tablets
- **Empty states** with contextual calls to action

---

## 📱 Screenshots

> _Screenshots given below.

| Home  | Add Link | Backup & Restore |
|:-----------:|:--------:|:----------------:|
| <img src="assets\Screenshot 2026-04-11 022440.png" alt="linkist Logo"  /> |  <img src="assets/Screenshot 2026-04-11 022449.png" alt="linkist Logo"  /> | <img src="assets\Screenshot 2026-04-11 022459.png" alt="linkist Logo"  /> |

---

## 🚀 Getting Started

### Prerequisites

| Tool | Minimum version |
|------|----------------|
| Flutter SDK | 3.0.0 |
| Dart SDK | 3.0.0 |
| Android SDK | API 21 (Android 5.0) |
| Xcode | 14.0 (for iOS builds) |

### Installation

```bash
# Clone the repository
git clone https://github.com/debapriya2003/linkist.git
cd linkist

# Install dependencies
flutter pub get

# Create required asset directories
mkdir -p assets/icons assets/animations

# Run on a connected device or emulator
flutter run
```

### Platform-specific setup

<details>
<summary><strong>Android</strong></summary>

Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28" />
```

No additional setup is required. Minimum SDK is API 21.
</details>

<details>
<summary><strong>iOS</strong></summary>

Add the following keys to `ios/Runner/Info.plist`:

```xml
<key>NSDocumentsFolderUsageDescription</key>
<string>Used to save and restore your linkist backup file.</string>
```

Minimum deployment target is iOS 12.
</details>

### Building for release

```bash
# Android — signed APK
flutter build apk --release

# Android — App Bundle (recommended for Play Store)
flutter build appbundle --release

# iOS — archive for App Store / TestFlight
flutter build ios --release
```

---

## 🏗 Architecture

linkist follows a simple, pragmatic layered architecture using **Provider** for state management and **SQFLite** as the local database.

```
lib/
├── main.dart                        # Entry point, MaterialApp, theme wiring
│
├── models/
│   └── link_model.dart              # Data class with toMap / fromMap for SQLite
│
├── services/
│   ├── database_service.dart        # SQLite singleton — all CRUD operations
│   ├── metadata_service.dart        # HTTP fetch → HTML parse → PageMetadata
│   ├── export_import_service.dart   # JSON backup serialisation and file I/O
│   └── link_provider.dart           # ChangeNotifier — app state & business logic
│
├── screens/
│   ├── home_screen.dart             # Main list view, FAB, options menu
│   └── export_import_screen.dart    # Tabbed backup / restore UI
│
├── widgets/
│   ├── add_edit_link_sheet.dart     # Modal bottom sheet — create & edit links
│   ├── link_card.dart               # Slidable card with favicon, tags, actions
│   ├── search_filter_bar.dart       # Search field + filter chips + sort menu
│   ├── stats_header.dart            # Counts row (total / favorites / categories)
│   └── empty_state.dart             # Zero-results placeholder with CTA
│
└── utils/
    └── app_theme.dart               # Material 3 dark & light ThemeData
```

### Data flow

```
User action
    └─▶ LinkProvider (ChangeNotifier)
            ├─▶ DatabaseService (sqflite)   — persistence
            ├─▶ MetadataService (http/html) — page scraping
            └─▶ ExportImportService         — backup I/O
                    └─▶ notifyListeners()
                              └─▶ Widgets rebuild
```

### Database schema

```sql
CREATE TABLE links (
  id          TEXT     PRIMARY KEY,
  title       TEXT     NOT NULL,
  url         TEXT     NOT NULL,
  description TEXT,
  tags        TEXT,              -- JSON-encoded string array, e.g. '["dev","flutter"]'
  faviconUrl  TEXT,
  category    TEXT,
  isFavorite  INTEGER  DEFAULT 0,
  createdAt   INTEGER  NOT NULL, -- Unix epoch milliseconds
  updatedAt   INTEGER  NOT NULL, -- Unix epoch milliseconds
  visitCount  INTEGER  DEFAULT 0
);

CREATE INDEX idx_links_category  ON links(category);
CREATE INDEX idx_links_createdAt ON links(createdAt);
```

### Backup format

Exported files are versioned JSON and are human-readable:

```json
{
  "version": 1,
  "appName": "linkist",
  "exportedAt": "2025-04-11T10:30:00.000Z",
  "totalLinks": 42,
  "links": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Flutter documentation",
      "url": "https://docs.flutter.dev",
      "description": "The official Flutter docs.",
      "tags": "[\"dev\",\"flutter\",\"reference\"]",
      "faviconUrl": "https://docs.flutter.dev/favicon.ico",
      "category": "dev",
      "isFavorite": 1,
      "createdAt": 1712834400000,
      "updatedAt": 1712834400000,
      "visitCount": 7
    }
  ]
}
```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| [`sqflite`](https://pub.dev/packages/sqflite) | ^2.3.2 | Local SQLite database |
| [`path`](https://pub.dev/packages/path) | ^1.9.0 | Cross-platform file paths |
| [`http`](https://pub.dev/packages/http) | ^1.2.0 | Fetch remote page metadata |
| [`html`](https://pub.dev/packages/html) | ^0.15.4 | HTML parser for title/favicon scraping |
| [`url_launcher`](https://pub.dev/packages/url_launcher) | ^6.2.5 | Open URLs in the system browser |
| [`provider`](https://pub.dev/packages/provider) | — | Lightweight state management |
| [`flutter_slidable`](https://pub.dev/packages/flutter_slidable) | ^3.1.0 | Swipe-to-action list items |
| [`cached_network_image`](https://pub.dev/packages/cached_network_image) | ^3.3.1 | Disk-cached favicon rendering |
| [`flutter_staggered_animations`](https://pub.dev/packages/flutter_staggered_animations) | ^1.1.1 | Staggered list entry animations |
| [`animations`](https://pub.dev/packages/animations) | ^2.0.11 | Material motion transitions |
| [`google_fonts`](https://pub.dev/packages/google_fonts) | ^6.2.1 | Space Grotesk & Inter typefaces |
| [`share_plus`](https://pub.dev/packages/share_plus) | ^9.0.0 | Native OS share sheet |
| [`path_provider`](https://pub.dev/packages/path_provider) | ^2.1.3 | Resolve device storage directories |
| [`file_picker`](https://pub.dev/packages/file_picker) | ^8.1.2 | Native file picker for import |
| [`uuid`](https://pub.dev/packages/uuid) | ^4.3.3 | RFC 4122 UUID generation |
| [`intl`](https://pub.dev/packages/intl) | ^0.19.0 | Date/number formatting |
| [`flutter_svg`](https://pub.dev/packages/flutter_svg) | ^2.0.10+1 | SVG asset rendering |
| [`lottie`](https://pub.dev/packages/lottie) | ^3.1.0 | Lottie animation support |

---

## 🗺 Suggest if you are looking for these features

The following features are planned or under consideration. Contributions toward any of these are very welcome.

- [ ] **Browser share extension** — save links directly from Chrome / Safari share menu
- [ ] **Collections** — group links into named folders alongside categories
- [ ] **Bulk actions** — multi-select to delete, move, or tag multiple links at once
- [ ] **Link health check** — detect and flag broken or redirected URLs
- [ ] **Widgets** — Android home screen widget showing recent or pinned links
- [ ] **iCloud / Google Drive sync** — optional cloud backup (opt-in, no account required for core use)
- [ ] **CSV export** — for compatibility with spreadsheet tools
- [ ] **Custom sort** — manual drag-and-drop ordering
- [ ] **Reading mode** — in-app web view with distraction-free reader layout
- [ ] **Duplicate detection** — warn when saving a URL already in the vault

Have an idea not listed here? [Open a discussion](https://github.com/debapriya2003/linkist/discussions).

---

## 🤝 Contributing

Contributions of all kinds are welcome — bug fixes, features, documentation, translations, and design feedback.

### Setting up a development environment

```bash
git clone https://github.com/debapriya2003/linkist.git
cd linkist
flutter pub get
flutter run
```

### Workflow

1. **Fork** the repository and create a branch from `main`:
   ```bash
   git checkout -b feat/my-new-feature
   ```
2. **Make your changes.** Follow the existing code style and keep commits focused.
3. **Test** on at least one Android emulator or device.
4. **Open a pull request** against `main` with a clear description of what changed and why.

### Guidelines

- Keep pull requests small and scoped to a single concern.
- Write clear commit messages — use the conventional format `type(scope): description` (e.g. `fix(db): handle null tags on import`).
- Do not introduce new dependencies without prior discussion in an issue.
- UI changes should work in both dark and light themes and on small screens (360 dp width).
- All public methods should have a brief doc comment.

### Reporting bugs

Please [open an issue](https://github.com/debapriya2003/linkist/issues/new?template=bug_report.md) and include:
- Flutter and Dart versions (`flutter --version`)
- Device / OS version
- Steps to reproduce
- Expected vs actual behaviour

---

## 🔒 Privacy

linkist is built with privacy as a hard constraint, not an afterthought.

- **No accounts.** The app works entirely without signing in.
- **No analytics or telemetry.** Zero data is collected, transmitted, or sold.
- **No cloud dependency.** All data lives in SQLite on your device.
- **Network access** is used only to fetch metadata (title, favicon) for URLs you explicitly save. It makes no other outbound requests.
- **Backup files** are plain JSON stored wherever you choose. The app does not upload them anywhere.

---

## 📄 License

```
MIT License

Copyright (c) 2025 linkist Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgements

- [Flutter](https://flutter.dev) and the Dart team for the framework
- All [package authors](#-dependencies) whose work this project builds on
- Everyone who files issues, opens PRs, or stars the repo

---

<div align="center">

Made with ♥ and Flutter · [Report a bug](https://github.com/debapriya2003/linkist/issues) · [Request a feature](https://github.com/debapriya2003/linkist/discussions)

</div>