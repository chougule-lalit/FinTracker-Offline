# Project Mentorship Log
**Project:** VaultFlow (FinTracker-Offline)
**Goal:** Track architectural decisions and Flutter concepts learned.

## [2023-12-01] The "Privacy & Process" Pivot
* **Lesson Learned (Documentation Integrity):** The AI previously diluted the "North Star" requirements.
    * **Rule Established:** The Roadmap sections (specifically Offline Chat and Offline Analytics) are **SACRED**. They must never be summarized or removed from the Master Context.
* **Concept:** **Human-in-the-Loop Architecture**. We acknowledged that AI/Regex isn't perfect. We need a "Pending Queue" for the user to handle edge cases.
* **Decisions:**
    1.  **Zero Internet:** The app is strictly offline. Security is paramount.
    2.  **Retroactive Sync:** When a user creates a rule, we immediately fix *past* data.
    3.  **Silent Listener:** Moving away from "Sync Button" to "Background Service".
* **Status:** Roadmap updated. Ready to build Phase 2.