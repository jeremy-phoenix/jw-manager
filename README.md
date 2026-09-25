# Congregation Manager

A Flutter app for managing congregations, publishers, groups, and service
reports, with an optional end-to-end encrypted sync server.

## Repository layout

The Flutter app lives at the repository root. The .NET server and its tests
live together in `backend/`.

```text
lib/                               Flutter application
test/                              Flutter tests
assets/                            App assets and report templates
android/  ios/  windows/            Flutter platform projects
pubspec.yaml                       Flutter dependencies and app version
backend/
  CongregationManager.slnx          .NET solution
  Directory.Build.props            Shared .NET build settings
  CongregationManager.Server/       Sync API and deployment documentation
  CongregationManager.Server.Tests/ Server tests
scripts/                           Local server and Android signing helpers
.github/workflows/                 CI and release builds
```

## Run the Flutter app

Install the stable Flutter SDK compatible with `pubspec.yaml`. Run these
commands from the repository root:

```sh
flutter pub get
flutter run
```

To analyze and test the app:

```sh
flutter analyze
flutter test
```

Open the repository root in VS Code to use the included Flutter launch
configurations. The Dart package name remains `congregation_manager`.

## Run the sync server

Install the .NET 10 SDK. On Windows, run this from the repository root:

```powershell
.\scripts\Start-SyncServer.ps1
```

The launcher initializes a registration secret when needed and starts the
development server at `http://127.0.0.1:5080`. You can also double-click
`scripts/Start-SyncServer.cmd`.

Run the server tests from the repository root:

```sh
dotnet test backend/CongregationManager.slnx
```

See the [server guide](backend/CongregationManager.Server/README.md) for
configuration, encryption details, and Linux VPS deployment, and the
[Uptime Kuma guide](backend/CongregationManager.Server/deploy/uptime-kuma.md)
for monitoring. Android release signing is documented in the
[signing helper guide](scripts/android/README.md).

## Keyboard shortcuts

Use Ctrl on Windows/Linux or Command on macOS.

| Shortcut | Action |
| --- | --- |
| Ctrl+F | Focus search in Publishers, Groups, or Service Reports |
| Ctrl+N | Add a publisher/group, or generate reports for the selected period |
| Ctrl+A | Select visible publisher rows (text fields keep normal Select All) |
| Esc | Clear publisher selection when outside a text field |
| Shift+click | Select a range of publisher rows |
| Ctrl+S | Save a publisher, group, or congregation form |
| Enter | Commit a report field and move to the same column in the next visible row |

Right-click a publisher row for its actions. Switching navigation tabs preserves
sorting, selection, and scroll position. Selecting the current tab again returns
to that tab's first page.
