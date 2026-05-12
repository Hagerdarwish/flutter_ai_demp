# API and Data Rules

---

## Firebase

Use Firebase for:
- **Authentication** (Firebase Auth)
- **Database** (Cloud Firestore)

**Do not use Firebase Storage in MVP.**

> Reason: The MVP avoids billing-dependent storage services and must not store raw media files. Files are sent directly to Gemini during processing and then discarded.

---

## Firestore Collections

```
users/{userId}
  - id           : String
  - name         : String
  - email        : String
  - createdAt    : Timestamp
  - updatedAt    : Timestamp

users/{userId}/meetings/{meetingId}
  - id               : String
  - title            : String
  - sourceType       : "file" | "link"
  - sourceName       : String
  - sourceUrl        : String
  - fileType         : String (mp3 | wav | m4a | mp4 | mov)
  - status           : "draft" | "processing" | "completed" | "failed"
  - shortSummary     : String
  - detailedSummary  : String
  - minutesOfMeeting : List<String>
  - participants     : List<String>
  - followUps        : List<String>
  - createdAt        : Timestamp
  - updatedAt        : Timestamp
  - processedAt      : Timestamp?

users/{userId}/meetings/{meetingId}/decisions/{decisionId}
  - id        : String
  - text      : String
  - owner     : String
  - createdAt : Timestamp

users/{userId}/meetings/{meetingId}/tasks/{taskId}
  - id          : String
  - title       : String
  - description : String
  - assignee    : String
  - dueDate     : String (YYYY-MM-DD or empty)
  - priority    : "low" | "medium" | "high"
  - status      : "pending" | "inProgress" | "completed"
  - createdAt   : Timestamp
  - updatedAt   : Timestamp

users/{userId}/tasks/{taskId}
  - id           : String
  - meetingId    : String
  - meetingTitle : String
  - title        : String
  - description  : String
  - assignee     : String
  - dueDate      : String
  - priority     : "low" | "medium" | "high"
  - status       : "pending" | "inProgress" | "completed"
  - createdAt    : Timestamp
  - updatedAt    : Timestamp
```

> **Note:** Tasks are stored both under the meeting (for detail view) and in a user-level tasks collection (for dashboard queries and the tasks page).

---

## Gemini API

Use Gemini API for:
- Audio/video understanding and transcription
- Transcript/text analysis
- Meeting summary generation
- Minutes of Meeting generation
- Task extraction
- Decision extraction

The app must send a **strict prompt** instructing Gemini to return **only valid JSON**.

---

## AI Prompt Template

Use this exact prompt when processing a meeting:

```
You are an AI meeting documentation assistant.

Analyze the provided meeting audio, video, transcript, or meeting text and return ONLY valid JSON.

Do not include markdown.
Do not include explanations outside JSON.

Return this exact structure:

{
  "title": "short meeting title",
  "shortSummary": "brief summary in 3-5 lines",
  "detailedSummary": "detailed meeting summary",
  "minutesOfMeeting": [
    "point 1",
    "point 2"
  ],
  "decisions": [
    {
      "text": "decision text",
      "owner": "person or team if mentioned"
    }
  ],
  "tasks": [
    {
      "title": "task title",
      "description": "task details",
      "assignee": "person or team if mentioned",
      "dueDate": "YYYY-MM-DD or empty string",
      "priority": "low | medium | high",
      "status": "pending"
    }
  ],
  "participants": [
    "participant name if detected"
  ],
  "followUps": [
    "follow up point"
  ]
}

If any value is unknown, use an empty string or empty array.
```

---

## Link Handling Rules

### Accepted link types:
- Direct downloadable audio/video URL
- Public recording URL
- Public transcript URL

### Not supported in MVP:
- Private Google Meet invite links
- Private Zoom invite links
- Private Microsoft Teams invite links

### Detection rule:
If the pasted URL matches known invite link patterns (e.g., `meet.google.com`, `zoom.us/j/`, `teams.microsoft.com`), show this message:

> "This looks like a meeting invite link. Please upload the meeting recording or paste a public recording/transcript link."

Implement this in `LinkValidationService`.

---

## API Key Rules

### Development
Use `--dart-define` to pass the key at build time:
```
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

### In Dart code
Read using:
```dart
const apiKey = String.fromEnvironment('GEMINI_API_KEY');
```

### Never:
- Hardcode API keys in any Dart file
- Commit API keys to version control
- Print API keys in logs
- Display API keys in the app UI

### Production recommendation
Use a secure backend proxy (e.g., a small Cloud Function or Dart Frog server) that calls the Gemini API server-side, so the key is never exposed in the Flutter app binary.

> Keep `GeminiService` abstract and injectable so the underlying implementation can be swapped from direct API calls to a backend proxy without changing any feature code.

---

## Data Privacy Rules

Do **not** store raw audio/video files in Firestore or any Firebase service in MVP.

Store **only**:
- File name and file type (metadata)
- Source type (file or link)
- AI-generated summary
- Minutes of Meeting
- Tasks
- Decisions
- Participants
- Follow-ups
- Processing status
- Timestamps
