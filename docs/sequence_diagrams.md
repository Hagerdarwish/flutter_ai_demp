# MeetFlow AI — Sequence Diagrams Documentation

This document contains the sequence diagrams for **MeetFlow AI**, mapping out the interaction flow between the presentation, domain, data, and service layers, as well as the external integrations (Firebase Auth, Cloud Firestore, and the Google Gemini API via Firebase AI).

The diagrams are written using **Mermaid.js** syntax and can be rendered natively in GitHub, VS Code (with Markdown Preview extensions), or any Mermaid-compatible Markdown reader.

---

## 1. User Authentication & Session Routing Flow

This diagram illustrates how user authentication actions (registering and logging in) flow from the presentation layer (using Riverpod `StateNotifier`) through the repositories to Firebase Authentication and Cloud Firestore, and how `GoRouter`'s refresh listener automatically guards and redirects routes.

```mermaid
sequenceDiagram
    autonumber
    actor User as User
    participant SplashPage as SplashPage
    participant Router as GoRouter (appRouterProvider)
    participant notifier as _AuthChangeNotifier
    participant AuthNotifier as AuthNotifier (StateNotifier)
    participant AuthRepo as AuthRepositoryImpl
    participant FirebaseAuth as Firebase Auth SDK
    participant Firestore as Cloud Firestore

    User->>Router: Launch App
    Router->>FirebaseAuth: Check current auth state
    FirebaseAuth-->>Router: Loading / Resolving Auth State
    Router->>SplashPage: Show SplashPage (Loading Spinner)
    
    Note over User, FirebaseAuth: Case A: User signs up (Registration)
    User->>Router: Navigate to RegisterPage
    User->>AuthNotifier: register(name, email, password)
    AuthNotifier->>AuthNotifier: Set State to AsyncLoading
    AuthNotifier->>AuthRepo: register(name, email, password)
    AuthRepo->>FirebaseAuth: createUserWithEmailAndPassword()
    FirebaseAuth-->>AuthRepo: UserCredential (uid)
    AuthRepo->>Firestore: Create user doc in 'users' collection
    Firestore-->>AuthRepo: Success
    AuthRepo-->>AuthNotifier: AppUser
    AuthNotifier-->>notifier: Stream notification (user logged in)
    notifier-->>Router: Trigger refreshListenable
    Router->>Router: Run redirect logic (IsLoggedIn = true)
    Router->>User: Navigate to HomePage

    Note over User, FirebaseAuth: Case B: User logs in
    User->>AuthNotifier: login(email, password)
    AuthNotifier->>AuthNotifier: Set State to AsyncLoading
    AuthNotifier->>AuthRepo: login(email, password)
    AuthRepo->>FirebaseAuth: signInWithEmailAndPassword()
    FirebaseAuth-->>AuthRepo: UserCredential
    AuthRepo->>Firestore: Fetch user doc from 'users' collection
    Firestore-->>AuthRepo: Map data
    AuthRepo-->>AuthNotifier: AppUser
    AuthNotifier-->>notifier: Stream notification (user logged in)
    notifier-->>Router: Trigger refreshListenable
    Router->>Router: Run redirect logic
    Router->>User: Navigate to HomePage
```

---

## 2. Audio/Video File Import & AI Meeting Analysis Flow

This diagram shows the end-to-end flow of importing a meeting from a local audio/video file. It describes how a draft meeting is created, uploaded, analyzed by the Google Gemini model using the Firebase AI SDK, parsed from JSON, and saved into Firestore using batch operations to preserve transactional integrity.

```mermaid
sequenceDiagram
    autonumber
    actor User as User
    participant Page as ImportMeetingPage
    participant Notifier as MeetingImportNotifier
    participant Picker as FilePickerService
    participant Repo as MeetingsRepository
    participant Gemini as GeminiServiceImpl
    participant FirebaseAI as Firebase AI SDK (generativeModel)
    participant GeminiAPI as Google Gemini API
    participant Firestore as Cloud Firestore

    User->>Page: Tap "Select Audio/Video File"
    Page->>Notifier: pickFile()
    Notifier->>Notifier: Set step = pickingFile
    Notifier->>Picker: pickMeetingFile()
    Picker->>User: Open Native File Picker
    User->>Picker: Select File (e.g. mp3/mp4/m4a)
    Picker-->>Notifier: File object
    Notifier->>Notifier: Set step = idle, store file in state
    Page-->>User: Show selected file name and options

    User->>Page: Enter Title (optional) & Tap "Process"
    Page->>Notifier: processFile(file, title, date)
    Notifier->>Notifier: Set step = uploading
    
    Note over Notifier, Repo: Step 1: Create draft meeting in Firestore
    Notifier->>Repo: createDraftMeeting(Meeting draft)
    Repo->>Repo: Generate UUID (meetingId)
    Repo->>Firestore: Write meeting doc (status = processing)
    Firestore-->>Repo: Success
    Repo-->>Notifier: meetingId
    
    Note over Notifier, Gemini: Step 2: Send file to Gemini for processing
    Notifier->>Notifier: Set step = processing
    Notifier->>Gemini: processMeetingFile(File)
    Gemini->>Gemini: Read file bytes & determine MIME type
    Gemini->>FirebaseAI: _model.generateContent([Prompt, FileBytes])
    FirebaseAI->>GeminiAPI: API call (No client-side key needed)
    GeminiAPI-->>FirebaseAI: Generated response text (JSON string)
    FirebaseAI-->>Gemini: Response text
    Gemini->>Gemini: Parse JSON using JsonParser
    Gemini-->>Notifier: Map<String, dynamic> (Meeting result details)

    Note over Notifier, Repo: Step 3: Save results in a Firestore transaction
    Notifier->>Notifier: Set step = saving
    Notifier->>Repo: saveMeetingResult(userId, meetingId, aiResult, title, defaultAssignee)
    Repo->>Firestore: Fetch user's participant directory
    Firestore-->>Repo: directory (name-to-email mapping)
    Repo->>Repo: Match detected names with emails
    Repo->>Repo: Initialize WriteBatch
    Repo->>Firestore: Batch.update(meeting doc: status = completed, summaries, minutes, participants, etc.)
    Repo->>Firestore: Batch.set(Decisions subcollection)
    Repo->>Firestore: Batch.set(Meeting Tasks subcollection)
    Repo->>Firestore: Batch.set(User-wide Tasks collection)
    Repo->>Firestore: Commit Batch
    Firestore-->>Repo: Success
    Repo-->>Notifier: Success
    Notifier->>Notifier: Set step = done, store createdMeetingId
    Page->>Page: Detect done state
    Page->>User: Navigate to MeetingDetailsPage(meetingId)
```

---

## 3. Task Management, Assignee Reassignment & Email Distribution Flow

This diagram covers the flow of updating task assignments and launching email dispatch. Because a task has double entries in Firestore (one under the specific meeting doc subcollection, and one under the main user's tasks collection), assigning a task commits a batch update. Composing emails builds a mailto URL using a designated translation (Arabic/English) and invokes `url_launcher` to redirect to the system email composer.

```mermaid
sequenceDiagram
    autonumber
    actor User as User
    participant DetailsPage as MeetingDetailsPage
    participant TasksNotifier as TasksNotifier (Riverpod)
    participant TasksRepo as TasksRepository
    participant MeetingActions as MeetingActionsNotifier
    participant MeetingsRepo as MeetingsRepository
    participant EmailService as TaskEmailService
    participant UrlLauncher as UrlLauncher (url_launcher)
    participant MailApp as Native Mail Client
    participant Firestore as Cloud Firestore

    Note over User, DetailsPage: Section A: Reassigning a Task
    User->>DetailsPage: Tap "Assign" or "Change" on TaskTile
    DetailsPage->>User: Show Dialog with Participant suggestions
    User->>DetailsPage: Input new Assignee & Tap Save
    DetailsPage->>TasksNotifier: updateAssignee(taskId, meetingId, assignee)
    TasksNotifier->>TasksNotifier: Set state = AsyncLoading
    TasksNotifier->>TasksRepo: updateTaskAssignee(userId, taskId, meetingId, assignee)
    TasksRepo->>TasksRepo: Initialize WriteBatch
    TasksRepo->>Firestore: Batch.update(User-wide task document)
    TasksRepo->>Firestore: Batch.update(Meeting-level task document)
    TasksRepo->>Firestore: Commit Batch
    Firestore-->>TasksRepo: Success
    TasksRepo-->>TasksNotifier: Success
    TasksNotifier-->>DetailsPage: Success (State updated)
    DetailsPage->>DetailsPage: Invalidate meetingTasksProvider
    DetailsPage->>Firestore: Reload meeting tasks stream
    Firestore-->>DetailsPage: Updated tasks (Show new assignee)

    Note over User, DetailsPage: Section B: Saving Participant Emails for future mapping
    User->>DetailsPage: Edit emails in "People, Tasks & Emails" section
    User->>DetailsPage: Tap "Save Emails"
    DetailsPage->>MeetingActions: saveParticipantEmails(meetingId, emails)
    MeetingActions->>MeetingsRepo: saveParticipantEmails(userId, meetingId, emails)
    MeetingsRepo->>MeetingsRepo: Initialize WriteBatch
    MeetingsRepo->>Firestore: Batch.update(Meeting doc: update participantEmails field)
    MeetingsRepo->>Firestore: Batch.set(User doc: merge participantEmailDirectory)
    MeetingsRepo->>Firestore: Commit Batch
    Firestore-->>MeetingsRepo: Success
    MeetingsRepo-->>MeetingActions: Success
    MeetingActions-->>DetailsPage: Success
    DetailsPage->>DetailsPage: Invalidate meetingDetailsProvider & Reload details

    Note over User, DetailsPage: Section C: Emailing Tasks to Assignee
    User->>DetailsPage: Tap "Email Tasks" for a Participant
    DetailsPage->>EmailService: composeTaskEmail(meeting, recipientName, recipientEmail, tasks, language)
    EmailService->>EmailService: _buildTaskEmailSubject(meeting, language)
    EmailService->>EmailService: _buildTaskEmailBody(meeting, recipientName, tasks, language)
    EmailService->>EmailService: Encode URI components and build mailto link (mailto:email?subject=...&body=...)
    EmailService->>UrlLauncher: launchUrlString(mailtoUrl)
    UrlLauncher->>MailApp: Open System Mail App with Pre-filled contents
    MailApp-->>User: Show Draft Email composition screen
```
