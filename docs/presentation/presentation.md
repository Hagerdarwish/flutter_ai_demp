---
marp: true
theme: gaia
_class: lead
paginate: true
backgroundColor: #0f172a
color: #f8fafc
style: |
  section {
    font-family: 'Inter', sans-serif;
    padding: 40px;
  }
  h1 {
    color: #38bdf8;
  }
  h2 {
    color: #38bdf8;
  }
  footer {
    color: #64748b;
  }
  .accent {
    color: #f43f5e;
  }
  .highlight {
    color: #fbbf24;
  }
  .grid-2 {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
  }
  .small-text {
    font-size: 0.8em;
  }
---

# MeetFlow AI
### An AI-Powered Mobile Application for Automated Meeting Documentation and Task Tracking

**Student Name:** Hager Elsayed Darwish (ID: 202401385)
**Program:** Master of Software Engineering
**Track:** Software engineer
**Supervisor:** Dr Mager mamdouh
**Academic Year:** 2025 / 2026

*Cairo University — Faculty of Graduate Studies for Statistical Research (FGSSR)*

---

# Agenda

1. **Introduction & Problem Definition**
2. **Project Objectives**
3. **Proposed Solution & Architecture**
4. **System Design & UML Models**
5. **User Interface & Screenshots**
6. **Implementation Details**
7. **Testing & Evaluation**
8. **Conclusion & Future Work**

---

# 1. Introduction & Background

- **Collaboration in Modern Workspaces:**
  - Meetings are critical for decision-making in academic, professional, and corporate settings.
  - Large volumes of decisions, agreements, and tasks are generated dynamically.
- **The Core Challenge:**
  - Traditional note-taking is inconsistent and dependent on individuals.
  - Manual review of full meeting recordings is tedious and time-consuming.
  - Essential outcomes are frequently lost, forgotten, or untracked post-meeting.

---

# 2. Problem Statement

* "How can we capture, structure, and track meeting outcomes automatically and reliably?"

* **Key Gaps in Current Workflows:**
  - Lack of integration between recording tools and task managers.
  - Manual overhead in translating raw spoken language into actionable items.
  - No clean, cross-platform dashboard designed specifically for meeting-focused task lifecycles.

---

# 3. Project Objectives

- **Automate Documentation:** Transform raw audio/video or public link imports into structured minutes, summaries, and decisions.
- **Generate Actionable Tasks:** Extract specific tasks, assignees, and deadlines automatically using Generative AI.
- **Cross-Platform Availability:** Deliver a clean mobile interface (iOS/Android) for immediate post-meeting tracking.
- **Secure & Cost-Effective Routing:** Protect API keys using a serverless middleware gateway (Firebase AI Logic).

---

# 4. Proposed Solution — MeetFlow AI

<div class="grid-2">
<div>

### Core Technologies
- **Frontend:** Flutter & Dart (Clean Architecture).
- **Backend:** Firebase (Authentication & Cloud Firestore).
- **State Management:** Riverpod.
- **AI Backend:** Gemini 2.5 Flash via Firebase AI Logic.

</div>
<div>

### Key Advantages
- Multimodal imports (audio, video, public URLs).
- Automatic language preservation (e.g. Arabic to Arabic).
- Namespace-isolated security (data locks).
- Dedicated tasks tracking tab.

</div>
</div>

---

# 5. System Architecture

* **Layered Clean Architecture (Feature-First):**
  - **Presentation Layer:** Flutter UI + Riverpod Providers (handles UI rendering and user interactions).
  - **Domain Layer:** Models, Entities, and Use Case contracts (enforces strict typing).
  - **Data Layer:** Repository implementations communicating with Firebase and Device services.
* **Serverless Gateway:**
  - Clients communicate with **Cloud Firestore** and **Firebase AI Logic**.
  - **Gemini API keys** are stored securely in Firebase, protecting the application from reverse engineering.

---

# 6. UML Use Case Model

- **Actors:** Primary User & Firebase Backend.
- **Key Actions:**
  - Register & Authenticate.
  - Import Recording (File Picker / URL paste).
  - Trigger AI Processing.
  - View Meeting Details (Summary, Decisions, Minutes).
  - **Delete Meeting** (Primary action that cleans up all associated Firestore tasks and subcollections).
  - Manage Tasks (Toggle status, change assignees).

---

# 7. Entity-Relationship Diagram (ERD)

* **Firestore Collections (Per-User Namespaced):**
  - `users/{userId}`: AppUser profile metadata.
  - `users/{userId}/meetings/{meetingId}`: Meeting records.
  - `users/{userId}/meetings/{meetingId}/decisions/{id}`: Extracted decisions.
  - `users/{userId}/meetings/{meetingId}/tasks/{id}`: Meeting-specific tasks.
  - `users/{userId}/tasks/{id}`: Duplicated user-level tasks supporting global, unified task queries.

---

# 8. Sequence Diagram: Authentication

```
[User] -> [LoginScreen] -> [AuthNotifier] -> [AuthRepository] -> [Firebase Auth]
  |            |               |                 |                   |
  |-- Email/Pw-|               |                 |                   |
  |            |-- signIn() -->|                 |                   |
  |            |               |-- loginEmail() >|                   |
  |            |               |                 |-- signInUser() -->|
  |            |               |<-- UserCredential ------------------|
  |            |<-- State: AuthState.authenticated ------------------|
```
- Authenticated state updates Riverpod listeners, redirecting the user to the Home Dashboard automatically.

---

# 9. Sequence Diagram: Meeting Import & AI Processing

```
[User] -> [ImportView] -> [MeetingRepository] -> [Firebase AI Logic] -> [Gemini API]
  |            |                 |                       |                 |
  |-- Submit ->|                 |                       |                 |
  |            |-- createDraft ->|                       |                 |
  |            |-- uploadMedia ->|                       |                 |
  |            |                 |-- triggerProcessing ->|                 |
  |            |                 |                       |-- analyze() --->|
  |            |                 |                       |<-- JSON Schema -|
  |            |                 |<-- Commit Firestore --|                 |
  |            |<-- Complete ----|                       |                 |
```
- The AI is prompted with a strict JSON format containing summaries, decisions, and tasks.

---

# 10. UML Component & Deployment Nodes

<div class="grid-2">
<div>

### Component Architecture
- **Presentation:** Widgets, State Notifiers.
- **Domain:** Data Models (AppUser, Meeting, Task).
- **Data Repositories:** AuthRepository, MeetingRepository.
- **Core Services:** FilePicker, FirebaseService.

</div>
<div>

### Deployment Node Mapping
- **Mobile Device:** Runs Flutter Runner, local secure storage.
- **Firebase Cloud:** Hosts Firebase Auth and Firestore.
- **Google Cloud:** Executes server-side AI Logic functions.
- **Gemini API:** Performs LLM inference.

</div>
</div>

---

# 11. User Interface & Screenshots

- **Login & Register:** Standard Material 3 text fields with email verification.
- **Dashboard:** Lists meetings with processing state badges (Pending, Processing, Completed).
- **Meeting Import:** Split tabs for "Upload File" and "Paste URL" (supports media links).
- **Meeting Details:** Interactive tabs separating:
  - **Summary:** Concise outline and detailed points.
  - **Minutes:** Timeline of discussions.
  - **Decisions:** Key takeaways.
- **Global Tasks Tab:** A unified checklist of all action items.

---

# 12. Implementation Highlights

* **Atomic Multi-write Operations:**
  - Tasks are written to both the meeting subcollection and the global user-level collection in a single batch transaction.
  - Ensures local data consistency and supports fast, indexed queries.
* **Firebase Security Rules:**
  ```javascript
  match /users/{userId}/{document=**} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
  ```
  - Guarantees complete data privacy; users can never read or write another user's data.

---

# 13. Testing & Evaluation

- **Unit Testing:**
  - Validated link detection regex rules (e.g. YouTube, Drive, and raw audio files).
  - Verified JSON parsing and serialization robustness.
- **Manual Verification:**
  - Full end-to-end user journeys executed on Android emulators and iOS devices.
  - Validated language preservation (Arabic meetings generated Arabic text outputs).
- **Edge Cases Tested:**
  - High-latency network transitions during media upload.
  - Malformed or corrupt media files (graceful error banner warnings).

---

# 14. Conclusion & Future Work

<div class="grid-2">
<div>

### Key Achievements
- Completed prototype of a generative AI workflow in a mobile context.
- Schema validation ensures 100% type-safe parser operations.
- Clean Architecture ensures high modularity.

</div>
<div>

### Future Roadmap
- **Live Recording:** In-app audio recording with streaming transcription.
- **Calendar Sync:** Export tasks to Google Calendar & Outlook.
- **Teams Support:** Collaborative workspaces for shared meeting actions.

</div>
</div>

---

# Thank You!
## Questions & Discussion

**MeetFlow AI:** Automated Meeting Documentation & Task Tracking

*Hager Elsayed Darwish (ID: 202401385)*
*Track: Software engineer*
*Supervisor: Dr Mager mamdouh*
*Cairo University — FGSSR*
