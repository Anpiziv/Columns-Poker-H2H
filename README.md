# Poker Columns

A unique Poker game style which I play with my friends. After I didn't find a game-app of this version I decided to create one on my own.

This repository contains a Flutter frontend for the local human-vs-bot Columns Poker game which we call "Chinese Poker", however Chinese Poker is a different Poker style.

Currently the gameplay is human vs bot. I plan in the future to support multiplayer mode.

## Install

1. Install the Flutter SDK from https://docs.flutter.dev/get-started/install. (Windows or Linux)
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
