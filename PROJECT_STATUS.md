# Project Status: FinTracker-Offline

## 1. Project Overview
**FinTracker-Offline** is a privacy-first, offline-only personal finance application built with Flutter. It automatically tracks expenses and income by reading and parsing transaction SMS messages directly on the device. The core value proposition is providing automated financial insights without ever sending sensitive data to the cloud, ensuring complete user privacy. It is targeted primarily at Android users who rely on SMS transaction alerts.

## 2. Current Development Status
**Summary:** The project has a solid foundation with a working database, state management, and a regex-based SMS parser. The core UI structure is in place.

*   **Implemented:**
    *   **Project Structure:** Clean architecture with feature-based folders.
    *   **Database:** Isar database set up with `Transaction`, `Category`, and `Account` models.
    *   **SMS Reading:** Integration with `flutter_sms_inbox` to read messages.
    *   **Basic Parsing:** A Regex-based service (`SmsParserService`) that extracts amounts, detects transaction type (debit/credit), and attempts to identify merchants.
    *   **State Management:** Riverpod v3 setup with `ProviderScope`.
    *   **Navigation:** GoRouter configuration.
*   **Partially Implemented:**
    *   **Categorization:** Currently defaults to "Uncategorized" or basic logic; no intelligent categorization yet.
    *   **Dashboard:** Basic screen structure exists.
*   **Not Touched:**
    *   **LLM Integration:** No on-device LLM runtime or model integration is currently present.
    *   **Advanced Insights/Charts:** `fl_chart` is in dependencies but complex charts are not yet implemented.
    *   **Budgets:** No budget modeling or UI.

## 3. Tech Stack
*   **Flutter Version:** `^3.5.0`
*   **State Management:** `flutter_riverpod` (v3.0.0-dev), `riverpod_annotation`
*   **Local Database:** `isar_community` (v3.3.0)
*   **SMS Reading:** `flutter_sms_inbox`
*   **LLM Runtime:** **Undecided** (Not yet implemented)
*   **Target Platforms:** Android (Primary due to SMS features)
*   **Minimum Supported Android Version:** Default Flutter Min SDK (likely API 21)
*   **Key 3rd Party Packages:** `go_router`, `fl_chart`, `google_fonts`, `intl`, `permission_handler`, `shared_preferences`.

## 4. App Constraints / Requirements
*   **Offline-Only:** The app must function 100% without an internet connection.
*   **Privacy:** No financial data should leave the device.
*   **Permissions:** Requires `READ_SMS` and storage permissions.
*   **Performance:** Must run efficiently on mobile devices; LLM inference must not drain battery excessively or freeze the UI.
*   **APK Size:** Should be optimized, though bundling an LLM will increase size significantly.

## 5. Current Folder Structure
```
lib/
  core/
    database/
    router/
    services/
    utils/
    widgets/
  features/
    accounts/
    add_transaction/
    dashboard/
    settings/
    sms_parser/
      providers/
      services/
    stats/
  models/
    account.dart
    category.dart
    transaction.dart
  theme/
  main.dart
```

## 6. Database Models
*   **Transaction**:
    *   `id` (AutoIncrement)
    *   `amount` (double)
    *   `note` (String)
    *   `date` (DateTime)
    *   `isExpense` (bool)
    *   `isTransfer` (bool)
    *   `smsRawText` (String?)
    *   `smsId` (String?)
    *   `receiptPath` (String?)
    *   Links: `category`, `account`, `transferAccount`
*   **Category**:
    *   `name`, `iconCode`, `colorHex`, `isExpense`, `isDefault`
*   **Account**:
    *   Used for linking transactions to specific bank accounts (via SMS digits).

## 7. Current LLM Usage
*   **Status:** **None**.
*   **Current Logic:** The app currently uses `SmsParserService` which relies on `RegExp` to find keywords like "debited", "credited", and extract amounts.
*   **Planned Role:** The LLM is intended to replace or augment the Regex parser to:
    *   Handle complex SMS formats.
    *   Intelligently categorize transactions based on merchant names.
    *   Provide natural language insights (e.g., "How much did I spend on food?").

## 8. Planned Features (Your Vision)
*   [x] SMS parsing (Basic Regex implemented)
*   [ ] Categorization (Intelligent/LLM based)
*   [ ] Monthly summary
*   [ ] Insights
*   [ ] Charts
*   [ ] Budgets
*   [ ] Natural language search
*   [ ] On-device LLM integration
*   [ ] Scam SMS detection
*   [ ] Subscription detection
*   [ ] Chat with your finances
*   [ ] Export/Import

## 9. Pain Points / Open Questions
*   **LLM Integration Strategy:** How to bundle and run a model (e.g., Gemma 2B or Phi-3) on Android via Flutter without making the APK huge or the app slow.
*   **Model Selection:** Choosing a model that is small enough for mobile but smart enough for JSON extraction/classification.
*   **Regex Fragility:** The current regex parser fails on non-standard SMS formats; moving to LLM is critical for robustness.

## 10. Your Preferred LLM Model (for on-device use)
**Recommendation: Gemma 2 (2B) or Phi-3 Mini (3.8B)**

*   **Gemma 2 (2B):**
    *   *Pros:* Extremely lightweight, Google-optimized, likely sufficient for extraction tasks.
    *   *Cons:* Less reasoning capability than larger models.
*   **Phi-3 Mini (3.8B):**
    *   *Pros:* Excellent performance-to-size ratio, very capable of instruction following.
    *   *Cons:* Slightly heavier on RAM/Storage than Gemma 2B.
*   **Runtime Choice:** `mediapipe_genai` (Google) or `llama_cpp_dart` are strong candidates.

## 11. App Goals for the Next 30 Days (High-Level)
*   **Select and Integrate LLM Runtime:** Choose between MediaPipe or Llama.cpp and get a "Hello World" inference running.
*   **Replace/Augment Regex Parser:** Feed raw SMS text to the LLM and get structured JSON output (Amount, Merchant, Category).
*   **Build Dashboard UI:** Visualize the parsed data with `fl_chart`.
*   **Implement Categories:** Create a default set of categories and allow the LLM to map transactions to them.

## 12. Anything Else I Should Know
The project is using the "Verified Community Fork" of Isar (`isar_community`), which is excellent for long-term maintenance. The state management is cutting-edge (Riverpod v3), so the codebase is modern. The immediate next big step is the technical hurdle of on-device AI.
