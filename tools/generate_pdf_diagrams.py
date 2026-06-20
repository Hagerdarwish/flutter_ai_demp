import base64
import json
import zlib
import urllib.request
import os
import subprocess
from pathlib import Path

# Diagrams definitions
diag1 = """sequenceDiagram
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
    Router->>User: Navigate to HomePage"""

diag2 = """sequenceDiagram
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
    Page->>User: Navigate to MeetingDetailsPage(meetingId)"""

diag3 = """sequenceDiagram
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
    MailApp-->>User: Show Draft Email composition screen"""

def get_mermaid_ink_url(mermaid_code):
    j_graph = {
        "code": mermaid_code,
        "mermaid": {"theme": "default"}
    }
    byte_str = json.dumps(j_graph).encode('utf-8')
    compress = zlib.compressobj(9, zlib.DEFLATED, 15, 8, zlib.Z_DEFAULT_STRATEGY)
    deflated = compress.compress(byte_str) + compress.flush()
    b64_encoded = base64.urlsafe_b64encode(deflated).decode('ascii')
    return f"https://mermaid.ink/svg/pako:{b64_encoded}"

def main():
    # Setup directories
    out_dir = Path("/tmp/meetflow_diagrams")
    out_dir.mkdir(parents=True, exist_ok=True)
    
    print("Encoding and downloading diagrams from mermaid.ink...")
    for idx, code in enumerate([diag1, diag2, diag3], start=1):
        url = get_mermaid_ink_url(code)
        path = out_dir / f"diag{idx}.svg"
        print(f"Downloading Diagram {idx} as SVG...")
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            path.write_bytes(response.read())

    # Build HTML document
    html_content = """<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>MeetFlow AI — Sequence Diagrams Documentation</title>
    <style>
        @page {
            size: A4 portrait;
            margin: 20mm 15mm 20mm 15mm;
        }
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            margin: 0;
            color: #1e293b;
            background-color: white;
            line-height: 1.6;
        }
        .header {
            text-align: center;
            border-bottom: 3px double #3b82f6;
            padding-bottom: 15px;
            margin-bottom: 35px;
        }
        h1 {
            color: #1e3a8a;
            font-size: 26px;
            margin: 0 0 8px 0;
            letter-spacing: -0.5px;
        }
        .subtitle {
            color: #64748b;
            font-size: 14px;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            margin: 0;
        }
        .diagram-section {
            page-break-after: always;
        }
        .diagram-section:last-child {
            page-break-after: avoid;
        }
        h2 {
            color: #1e3a8a;
            font-size: 18px;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 6px;
            margin-top: 0;
            margin-bottom: 12px;
        }
        .description {
            font-size: 12.5px;
            color: #475569;
            margin-bottom: 20px;
            text-align: justify;
        }
        .diagram-container {
            text-align: center;
            margin-top: 15px;
        }
        .diagram-container img {
            max-width: 100%;
            height: auto;
            max-height: 200mm; /* Ensure it fits nicely on a standard page */
            border: 1px solid #f1f5f9;
            padding: 10px;
            background: #fafbfd;
            border-radius: 8px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>MeetFlow AI — Graduation Project Documentation</h1>
        <div class="subtitle">System Sequence Diagrams</div>
    </div>

    <div class="diagram-section">
        <h2>1. User Authentication & Session Routing Flow</h2>
        <div class="description">
            This diagram illustrates how user authentication actions (registering and logging in) flow from the presentation layer (using Riverpod StateNotifier) through the repositories to Firebase Authentication and Cloud Firestore, and how GoRouter's refresh listener automatically guards and redirects routes.
        </div>
        <div class="diagram-container">
            <img src="diag1.svg">
        </div>
    </div>

    <div class="diagram-section">
        <h2>2. Audio/Video File Import & AI Meeting Analysis Flow</h2>
        <div class="description">
            This diagram shows the end-to-end flow of importing a meeting from a local audio/video file. It describes how a draft meeting is created, uploaded, analyzed by the Google Gemini model using the Firebase AI SDK, parsed from JSON, and saved into Firestore using batch operations to preserve transactional integrity.
        </div>
        <div class="diagram-container">
            <img src="diag2.svg">
        </div>
    </div>

    <div class="diagram-section">
        <h2>3. Task Management, Assignee Reassignment & Email Distribution Flow</h2>
        <div class="description">
            This diagram covers the flow of updating task assignments and launching email dispatch. Composing emails builds a mailto URL using a designated translation (Arabic/English) and invokes url_launcher to redirect to the system email composer.
        </div>
        <div class="diagram-container">
            <img src="diag3.svg">
        </div>
    </div>
</body>
</html>
"""
    html_path = out_dir / "index.html"
    html_path.write_text(html_content, encoding='utf-8')
    
    pdf_output_path = Path("/Users/ahmednabil/StudioProjects/flutter_ai_demp/docs/MeetFlow_AI_Graduation_Project_Final.pdf")
    pdf_output_path.parent.mkdir(parents=True, exist_ok=True)
    
    chrome_paths = [
        "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    ]
    
    success = False
    for chrome_bin in chrome_paths:
        if os.path.exists(chrome_bin):
            print(f"Using browser: {chrome_bin}")
            cmd = [
                chrome_bin,
                "--headless",
                "--disable-gpu",
                "--no-pdf-header-footer",
                "--print-to-pdf-no-header",
                f"--print-to-pdf={pdf_output_path}",
                str(html_path)
            ]
            try:
                subprocess.run(cmd, check=True)
                print(f"Successfully generated PDF: {pdf_output_path}")
                success = True
                break
            except Exception as e:
                print(f"Failed with {chrome_bin}: {e}")
                
    if not success:
        print("Error: Could not render PDF using available browsers.")
        exit(1)

if __name__ == "__main__":
    main()
