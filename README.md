# Chinese Poker UI

This folder contains a Flutter frontend for the local human-vs-bot Chinese Poker game.

## Install

1. Install the Flutter SDK from https://docs.flutter.dev/get-started/install.
2. Add Flutter to your system `PATH`.
3. Check your setup:

```bash
flutter doctor
```

4. Install project packages from this folder:

```bash
flutter pub get
```

## Run

Run in Chrome:

```bash
flutter run -d chrome
```

Or run on any connected Flutter device:

```bash
flutter run
```

## Test

```bash
flutter test
```

## Build for web

```bash
flutter build web
```

The generated output is written to `build/web/`. This folder should not be uploaded to GitHub unless you intentionally publish compiled artifacts.

## GitHub upload notes

Keep these in GitHub:

- `lib/`
- `test/`
- `web/`
- `assets/` when its artwork is licensed for redistribution
- `android/` source and Gradle configuration when Android builds are supported
- `pubspec.yaml`
- `pubspec.lock`
- `analysis_options.yaml`
- `.gitignore`
- `README.md`

Do not upload generated or local-only files:

- `build/`
- `.dart_tool/`
- `.idea/`
- `*.iml`
- `.pub-cache/`, `.pub/`, `coverage/`, and log files
- `android/local.properties`, which contains machine-specific SDK paths

## Game flow

- Each turn, a card is drawn from the deck.
- The human player chooses a column to place it into.
- The bot then chooses a column for its card.
- The game builds five columns, then gives each player one optional final exchange card.
- Final score is compared across the five columns.

See the repository-level [player manual](../GAME_INSTRUCTIONS.md) for the
complete rules and controls.
