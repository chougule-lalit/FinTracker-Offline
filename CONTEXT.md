# Project: PrivacyFirst Money Manager (Flutter)
# Role: Senior Flutter Developer & AI Specialist

## 1. Project Goal
Build a local-first, offline-only expense tracker that parses SMS messages.
Target: Mimic ~90% of functionality from "Money Manager by RealByte" ([https://www.realbyteapps.com/](https://www.realbyteapps.com/)).
PRIORITY: 100% Privacy. No internet permissions.

## 2. Tech Stack
- **Framework:** Flutter
- **Database:** Isar Community (v3.3.0) -> Use `package:isar_community/isar.dart`
- **State Management:** Riverpod 3.0 (Pre-release) -> Use `@Riverpod(keepAlive: true)`
- **Navigation:** GoRouter
- **UI:** Google Fonts, FL_Chart

## 3. Architecture (Feature-First)
lib/
  ├── main.dart
  ├── core/                # Shared logic (Theme, DB Helpers, Constants)
  ├── features/
  │   ├── dashboard/       # Home screen (Charts, Recent list)
  │   ├── add_transaction/ # Input screen
  │   ├── sms_parser/      # Logic to read and parse SMS
  │   └── settings/        # Backup, Theme toggle
  └── models/              # Isar Collections (Transaction, Category)

## 4. Coding Rules
1. **Always** use `flutter_riverpod` annotations.
2. **Never** use `package:isar/isar.dart`. Use `isar_community` instead.
3. **WriteAsync:** Use `isar.writeTxn(...)` for writing data.
4. **No Cloud:** Do not add Firebase/HTTP.

## 5. Current Progress Status
- [x] Project Created
- [x] Database Configured (Isar Community)
- [x] Models Created & Generated (.g.dart files exist)
- [ ] DbService Class (Next Task)