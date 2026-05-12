# Feature Rules

---

## 1. Auth Feature

Auth should include:
- Splash / Auth gate
- Login
- Register
- Forgot Password
- Logout

Use **Firebase Auth**.

**Supported auth methods for MVP:**
- Email and password

**Optional later:**
- Google Sign-In
- Apple Sign-In

**Navigation rules:**
- After login → navigate to Home.
- If user is not logged in → navigate to Login.
- Auth gate runs on app start to decide the initial route.

---

## 2. Home Feature

The Home screen is a **dashboard**.

### Header
- Welcome message
- User name or email
- Small profile/settings button

### Quick Actions
Four action cards:
1. Upload audio/video
2. Paste meeting link
3. View all meetings
4. View tasks

### Dashboard Stats
Show summary cards for:
- Total meetings
- Completed summaries
- Pending tasks
- Decisions captured

### Recent Meetings
Show the latest 3 to 5 meetings with:
- Meeting title
- Date
- Processing status chip
- "Open Details" button

### Task Overview
Show:
- Pending tasks count
- High-priority tasks count
- Completed tasks count

### Empty State
If no meetings exist, display:

> "Upload your first meeting recording to generate AI-powered meeting documentation."

---

## 3. Meeting Import Feature

The user has **two import options**:

### Case 1: Upload from Mobile Files

Allowed formats:
- Audio: `mp3`, `wav`, `m4a`
- Video: `mp4`, `mov`

**Flow:**
1. User selects a file using the file picker.
2. User optionally enters a meeting title.
3. User optionally enters a meeting date.
4. User taps "Generate".
5. App sends the file to the Gemini API.
6. Gemini returns structured JSON.
7. App saves the result in Firestore.
8. App navigates to the meeting details page.

### Case 2: Paste Meeting Link

Accepted link types:
- Direct downloadable audio/video URL
- Public recording URL
- Public transcript URL

**Important — Unsupported link detection:**

If the user pastes a Google Meet, Zoom, or Microsoft Teams **invite link**, detect it and show:

> "This looks like a meeting invite link. Please upload the meeting recording or paste a public recording/transcript link."

For MVP, **do not** implement private meeting platform integrations (Google Meet, Zoom, Teams).

---

## 4. Meetings Feature

### Meetings List Page
- Shows all processed meetings.
- Supports status filtering.

**Meeting status values:**
| Status | Description |
|--------|-------------|
| `draft` | Created, not yet processed |
| `processing` | Currently being analyzed |
| `completed` | Successfully processed |
| `failed` | Processing error occurred |

### Meeting Details Page

Displays all AI-generated content in sections:
1. Short Summary
2. Detailed Summary
3. Minutes of Meeting
4. Decisions
5. Tasks
6. Participants
7. Follow-ups
8. Source metadata (file name, type, link)

**User actions:**
- View meeting details
- Delete meeting
- Regenerate summary (future)
- Copy summary text
- Export as plain text or Markdown

> PDF export can be added in a later release.

---

## 5. Tasks Feature

Tasks are extracted from meetings by the AI.

### Task Fields

| Field | Type | Values |
|-------|------|--------|
| `id` | String | UUID |
| `title` | String | Task title |
| `description` | String | Task details |
| `assignee` | String | Person or team name |
| `dueDate` | String | YYYY-MM-DD or empty |
| `priority` | Enum | `low`, `medium`, `high` |
| `status` | Enum | `pending`, `inProgress`, `completed` |
| `meetingId` | String | Parent meeting ID |
| `createdAt` | Timestamp | Creation time |
| `updatedAt` | Timestamp | Last update time |

### Tasks Page

- Show all tasks across all meetings.
- Filter chips for status: All / Pending / In Progress / Completed.
- Filter chips for priority: All / Low / Medium / High.
- Each task card shows: title, assignee, due date, priority chip, status.

**User actions:**
- Mark task as Completed
- Mark task as In Progress
- Open the related meeting from the task

---

## 6. Settings Feature

Settings page should include:

- **Profile section:** Display user name and email.
- **Logout button**
- **Theme switcher:** Light / Dark / System.
- **About section:** App version, description.
- **API info note:** Inform users that AI processing is powered by Gemini API. Do not expose any API keys.

> Do not display or expose secret API keys anywhere in the UI.
