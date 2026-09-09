# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Browny Application V3 — Flutter app for laundry service management. Targets Android and iOS (Web planned). Package name: `browny_applications_new`. Current version: `3.0.8+77`. Dart SDK `>=3.10.0 <4.0.0`. Pinned Flutter: `3.44.9` (Dart 3.12.2). SDK at `/opt/homebrew/share/flutter` is a git checkout held at tag `3.44.9` (detached HEAD). `flutter doctor` reporting channel `[user-branch]` / "unknown source" is **expected and harmless** for this pinned setup — do NOT run `flutter upgrade` or `flutter channel` (stable has since moved to 3.47.x). To change Flutter version: `git -C /opt/homebrew/share/flutter checkout <tag>` then `flutter --version`.

## Commonly Used Commands

```bash
flutter pub get                                          # install deps
flutter run                                              # run on connected device
dart run build_runner build --delete-conflicting-outputs # regen Retrofit/JSON/Hive after model changes
flutter gen-l10n                                         # regen ARB localizations
flutter analyze                                          # lint (uses analysis_options.yaml + flutter_lints)
flutter test                                             # run all tests
flutter test test/path/to/file_test.dart                 # run a single test file
flutter test --name "<test name>"                        # run single test by name
flutter build apk --release
flutter build ios --release
```

Code generation is required after editing any file with `@JsonSerializable`, `@RestApi`, or Hive `@HiveType` annotations — generated outputs (`*.g.dart`, `*.freezed.dart`) live next to source.

## Architecture

Clean Architecture + MVVM with **Provider** (`ChangeNotifier`) for state. Single Retrofit/Dio HTTP client, Hive (community edition `hive_ce`) for local storage, `go_router` for navigation, `flutter_screenutil` for responsive sizing.

### Layout

```
lib/
├── main.dart                  # Firebase init → AppEnvironment.loadEnv() → NotificationHelper → runApp
├── core/
│   ├── env/                   # AppEnvironment (abstract), DevEnvironment, PrdEnvironment — load env/{dev,prd}.json
│   ├── client/                # Dio/Retrofit setup
│   ├── data/{cache,remote,repo}/   # Hive cache, Retrofit AppClient, AppRepository base
│   ├── services/live_activity/     # iOS Live Activities bridge
│   ├── utils/                 # CrashlyticsHelper, NotificationHelper (FCM + flutter_local_notifications), etc.
│   ├── providers/             # shared ChangeNotifier providers
│   ├── viewmodels/            # AppViewModel (root)
│   └── widgets/               # shared UI
├── feature/<name>/            # one folder per feature: models/, repository/, viewmodel/, screens/ or view/, widgets/
│   e.g. authentication, home, transactions, wallet, coin, profile,
│        articles, contacts, invit_friend, lucky_scan, map, onboarding,
│        scaner, update
└── res/                       # generated localizations, colors, theme, icons (flutter_gen output)
```

`flutter_gen.output` is `lib/res/icons` (NOT the default `lib/gen/`).

### Data Flow

`View → ViewModel (ChangeNotifier) → Repository → AppClient (Retrofit/Dio) | AppLocalStorage (Hive)`

Each feature repository extends `AppRepository` (in `lib/core/data/repo/`) so it shares the configured `AppClient` + `AppLocalStorage`. All API responses extend `BaseModelResponse` (`success`, `message`, `errorType`).

### Environment

- Env JSON files live in `env/dev.json` and `env/prd.json` (loaded at runtime by `AppEnvironment.loadEnv()`).
- `main.dart` currently hard-codes `DevEnvironment()` — switch to `PrdEnvironment()` for production builds.
- Firebase config via `firebase_options.dart` (FlutterFire CLI generated).

### Localization

ARB files: `lib/res/strings/l10n/app_{en,th,zh}.arb` → generated `AppLocalizations`. Three locales: Thai (default), English, Chinese. Default language stored in Hive via `AppLocalStorage.getLanguage()` (falls back to `'th'`).

## Knowledge Graph (graphify) — consult on every coding task

This repo has a persistent **code knowledge graph** built by [graphify](https://github.com/safishamsi/graphify), scoped to `lib/` (the Flutter app source). It is AST-extracted (classes, functions, `references` / `extends` / `inherits` edges) — ~7,200 nodes / ~9,296 edges across 288 communities. Generated outputs live in `graphify-out/` (git-ignored):

- `graphify-out/graph.json` — raw graph data (source of truth for queries)
- `graphify-out/GRAPH_REPORT.md` — god nodes, community map, cross-feature bridges
- `graphify-out/graph.html` — interactive view

**Use the graph as a first step, not an afterthought:**

- **Before** answering any question about architecture, where a symbol lives, what calls/extends/references something, or how data flows — and before planning a change that spans multiple files — query the graph FIRST via the `/graphify` skill: `/graphify query "<question>"` (fast path: reads the existing graph, no rebuild). Cite `source_location` from the results rather than guessing.
- Prefer the graph over blind `grep` for understanding **relationships** (inheritance chains, `feature/*` ↔ `core/data` coupling, which ViewModel touches which repo). Known cross-community bridges worth checking: `CustomerProvider`, `ContentLocalizeData`, `BaseModelResponse`, `AddressRepo`, `BrownyShopSelectedViewModel`.
- **After** landing code changes under `lib/`, refresh the graph incrementally so it stays accurate: `/graphify lib --update` (re-extracts only changed files; AST-only, no LLM cost).
- If `graphify-out/` is missing (fresh clone), rebuild the graph with `/graphify lib`.
- Never hand-edit anything in `graphify-out/` — it is regenerated.

## Conventions & Gotchas

- **Generator compatibility**: `retrofit_generator: ^10.2.5` and `hive_ce_generator: ^1.11.1` were chosen to coexist — do not bump independently without verifying both still build.
- Use `hive_ce` / `hive_ce_flutter` (community edition). Do **not** add the original `hive` package.
- Adding a new feature: create `lib/feature/<name>/{models,repository,viewmodel,screens,widgets}/`. The repository should extend `AppRepository`; expose the viewmodel via Provider in `main.dart` or the relevant subtree.
- Adding new asset folders requires registering them under `flutter.assets` in `pubspec.yaml`.
- iOS app icons are managed via `icon_launcher.yaml` (`icons_launcher` package) — regenerate rather than hand-editing the `Assets.xcassets` PNGs.
- Native splash via `flutter_native_splash.yaml`.
- App auto-update prompts use the `upgrader` package; minimum supported versions are driven by remote env config, not pubspec.

## Commit Style

Commit messages in this repo are written in Thai, often as bulleted release notes (see `git log`). Match that style when committing on behalf of the user.
