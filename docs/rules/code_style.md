# Code Style Rules

---

## General Principles

Write clean, readable, maintainable Dart code.

Follow:
- Null safety (required)
- Clear, descriptive naming
- Small, focused widgets
- Small, single-responsibility methods
- Feature-first clean architecture
- Repository pattern
- Service abstraction
- Riverpod for state management

---

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Files | `snake_case` | `login_page.dart` |
| Classes | `PascalCase` | `LoginPage` |
| Variables | `camelCase` | `meetingTitle` |
| Private vars | `_camelCase` | `_isLoading` |
| Constants | `camelCase` in const class | `maxFileSizeMb` |

---

## Providers Naming

| Provider | Name |
|----------|------|
| Auth | `authProvider` |
| Meetings list | `meetingsProvider` |
| Meeting details | `meetingDetailsProvider` |
| Tasks | `tasksProvider` |
| Meeting import | `meetingImportProvider` |
| Theme | `themeProvider` |

---

## Pages and Widgets Naming

**Pages:** `LoginPage`, `RegisterPage`, `ForgotPasswordPage`, `HomePage`, `ImportMeetingPage`, `MeetingsPage`, `MeetingDetailsPage`, `TasksPage`, `SettingsPage`

**Widgets:** `MeetingCard`, `TaskCard`, `UploadFileCard`, `PasteLinkCard`, `DashboardStats`, `HomeQuickActions`, `RecentMeetingsList`, `TaskOverviewCard`

---

## State Management Rules (Riverpod)

- Do **not** use `setState` for complex business state.
- Use `AsyncValue<T>` for loading / error / data states.
- Keep all providers inside `presentation/providers/`.
- Keep business logic **outside** of widgets.
- Use `ConsumerWidget` or `ConsumerStatefulWidget` for reactive widgets.
- Use `ref.watch()` for reactive data, `ref.read()` for one-time actions.

---

## Error Handling

Create and use:
- `AppException` — application-level errors
- `Failure` — repository-level failures (sealed or abstract class)

Rules:
- Show user-friendly error messages — not raw stack traces.
- Never expose raw Firebase or Gemini API errors directly to users.
- Map exceptions to `Failure` types in the repository layer.
- Surface errors via `AsyncValue.error` in providers.

---

## Widget Rules

Widgets **must:**
- Be small and single-responsibility
- Receive data through constructors
- Use `AppColors`, `AppTextStyles` — never hardcoded values

Widgets **must not:**
- Call Firebase or Gemini directly
- Contain business logic
- Use hardcoded colors or text styles inline
- Trigger data fetching inside `build()`

---

## Import Order

```dart
// 1. Dart SDK
import 'dart:io';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. Third-party
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 4. Internal
import 'package:meetflow_ai/core/theme/app_colors.dart';
```

---

## Comments Policy

- Comment only when logic is non-obvious.
- Use `///` doc comments for public classes/methods.
- Avoid commented-out code in committed files.

---

## File Length

- Keep files under ~300 lines where possible.
- Split large widgets into sub-widgets.
- Split large use cases into focused ones.

---

## Linting

Use `flutter_lints`. Consider enabling:
- `prefer_final_locals`
- `avoid_print`
- `use_super_parameters`
