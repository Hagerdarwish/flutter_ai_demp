# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project

**MeetFlow AI** (`meetflow_ai`) — a Flutter app that turns meeting audio/video files or public transcript/recording links into structured, AI-generated documentation: summaries, minutes, decisions, and trackable action items.

## Commands

```bash
flutter pub get                 # install deps
flutter run                     # run on connected device/emulator
flutter analyze                 # lint (flutter_lints + custom_lint/riverpod_lint)
dart run custom_lint            # run riverpod_lint checks specifically
flutter test                    # run tests (no test/ dir exists yet)
flutter test test/foo_test.dart # run a single test file
flutter build apk / ios         # release builds
```

No API key flags are needed at runtime — Gemini auth is handled by Firebase AI Logic server-side (see AI section). The legacy rules mention `--dart-define=GEMINI_API_KEY=...`, but the current code does **not** read it; it uses `firebase_ai` instead.

### Firebase setup (required before the app runs)

`lib/firebase_options.dart` is **not** checked in and must be generated:

```bash
flutterfire configure           # generates lib/firebase_options.dart
```

Then in the Firebase Console enable **Authentication → Email/Password**, create a **Cloud Firestore** database, and enable **Firebase AI Logic** (Gemini). Without `firebase_options.dart`, the app shows a setup-error screen (`_FirebaseSetupErrorApp` in `lib/main.dart`).

> Note: `lib/main.dart` is currently incomplete/broken on the working tree (missing `Firebase.initializeApp`, the `ProviderScope`/`MeetFlowApp` wiring, and the `firebase_options` import). A working `main()` must `WidgetsFlutterBinding.ensureInitialized()`, init Firebase, then `runApp(const ProviderScope(child: MeetFlowApp()))`, falling back to `_FirebaseSetupErrorApp` on init failure.

## Architecture

**Feature-first clean architecture.** Each feature under `lib/features/<name>/` is split into `data/` (repositories talking to Firebase), `domain/` (entities + repository interfaces), and `presentation/` (`pages/` + `providers/`). Shared code lives in `lib/core/` (`constants/`, `theme/`, `services/`, `errors/`, `widgets/`, `utils/`) and app-wide wiring in `lib/app/` (`MeetFlowApp` + `router/`).

Features: `auth`, `home`, `meeting_import`, `meetings`, `tasks`, `settings`.

### State management — Riverpod (no codegen in practice)

Despite `riverpod_generator`/`riverpod_annotation` being deps, providers are written **manually** (plain `Provider`/`StreamProvider`/`StateNotifierProvider`), not generated. Follow the existing manual style.

Key cross-feature provider: `currentUserProvider` (in `features/auth/.../auth_provider.dart`) exposes the current `AppUser?`. Nearly every data provider does `ref.watch(currentUserProvider)` and returns empty/throws when null — this is how per-user scoping is enforced. `firebaseAuthUserProvider` is a lightweight raw-`User?` stream used **only** by the router's splash redirect (fast, no Firestore round-trip), separate from `authNotifierProvider` which resolves the full `AppUser` from Firestore.

### Routing — GoRouter

`appRouterProvider` in `lib/app/router/app_router.dart`. Structure: a `SplashPage` (listens to `firebaseAuthUserProvider` and redirects to home or login), unauthenticated auth routes, a `ShellRoute` (`AppShell`) wrapping the 4 bottom-nav tabs (home/meetings/tasks/settings), and full-screen routes for import + meeting details. Route paths are centralized in `route_names.dart`. There is **no** global redirect guard — auth gating happens via the splash page and provider null-checks.

### Firestore data model

All data is namespaced per user. Collection names live in `core/constants/app_constants.dart`:

```
users/{userId}/meetings/{meetingId}
users/{userId}/meetings/{meetingId}/decisions/{id}
users/{userId}/meetings/{meetingId}/tasks/{id}     # tasks scoped to a meeting
users/{userId}/tasks/{id}                           # SAME task duplicated at user level for the Tasks tab
```

Action items are **written twice** (under the meeting and under the user) in one batch so the global Tasks tab can query without a collection-group query — see `MeetingsRepository.saveMeetingResult`. Entities own their (de)serialization via `fromFirestore`/`toFirestore`/`fromAiMap`. Repositories under `meetings`/`tasks` are plain classes instantiated directly in providers (only `auth` formalizes a `domain/repositories` interface).

### AI pipeline (the core flow)

`MeetingImportNotifier` (`features/meeting_import/.../meeting_import_provider.dart`) drives a state machine `ImportStep { idle, pickingFile, uploading, processing, saving, done, error }`:

1. Create a **draft** meeting in Firestore with `status: processing`.
2. Call `GeminiService.processMeetingFile(File)` or `processMeetingUrl(String)`.
3. `saveMeetingResult` batch-writes summary fields onto the meeting + fans out decisions/tasks; sets `status: completed`.
4. On any failure, `markMeetingFailed` flips the draft to `status: failed` (using the known ID even if the in-memory object never received it).

`GeminiService` (`core/services/gemini_service.dart`) is an **abstract** interface with `GeminiServiceImpl` using `firebase_ai` (`FirebaseAI.googleAI().generativeModel(...)`). Keep it abstract — the intent is to later swap the direct-from-client impl for a backend proxy. The model is `gemini-2.5-flash` (`AppConstants.geminiModel`). Files are sent as `InlineDataPart` with MIME inferred from extension; URLs are fetched via `http` and sent as text or inline bytes depending on content-type.

**AI output contract:** the model is instructed (via `_systemPrompt`) to return **only** JSON matching a fixed schema (`title`, `shortSummary`, `detailedSummary`, `minutesOfMeeting[]`, `decisions[]{text,owner}`, `tasks[]{title,description,assignee,dueDate,priority,status}`, `participants[]`, `followUps[]`), and to respond in the **same language** as the meeting (Arabic in → Arabic out). The response is parsed defensively by `JsonParser.parseMeetingResult` in `core/utils/json_parser.dart` — keep parsing tolerant of markdown fences / stray text. Errors are funneled through `AIException` and humanized in `GeminiServiceImpl._humanizeError`.

## Conventions & constraints

- **Material 3**, light + dark themes in `core/theme/`; theme mode via `themeModeProvider` (in `settings_page.dart`).
- File constraints in `AppConstants`: allowed extensions `mp3/wav/m4a/mp4/mov`, max 50 MB.
- Errors: throw typed exceptions from `core/errors/app_exception.dart` (`AuthException`, `AIException`, `FileException`, `StorageException`); UI reads `.message`.
- **MVP boundaries (do not cross without being asked):** no Firebase Storage — never store raw meeting files in Firestore, only metadata + AI results; no paid APIs/UI kits; no hardcoded secrets; no backend (Gemini called directly from client for now).
- When generating code: provide complete files, name the file path, keep imports intact, avoid overengineering.
