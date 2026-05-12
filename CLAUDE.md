# MeetFlow AI - Claude Project Rules

You are working on a Flutter mobile application called MeetFlow AI.

The app converts meeting audio, video, or public transcript/recording links into structured AI-generated documentation.

---

## Main Goal

Build a clean, scalable Flutter app that helps users:
- Sign in securely
- Upload audio/video meeting files
- Paste meeting recording or transcript links
- Generate AI meeting summaries
- Generate Minutes of Meeting
- Extract decisions
- Extract action items and tasks
- Track tasks after the meeting
- View meeting history

---

## Tech Stack

**Use:**
- Flutter stable
- Dart
- Firebase Authentication
- Cloud Firestore
- Gemini API
- Riverpod
- GoRouter
- Material 3
- Free packages only where possible

**Do not use:**
- Paid APIs unless explicitly requested
- Paid UI kits
- Complex backend in MVP
- Firebase Storage in MVP
- Hardcoded secrets
- Random folder structures

---

## Google AI Ultra Note

The developer has Google AI Ultra.

This can help with:
- AI Studio prototyping
- Gemini prompt testing
- Development and testing
- Possible Google Cloud/Gemini credits

**But:**
- Do not assume unlimited API usage.
- Do not expose the Gemini API key inside production Flutter code.
- For MVP/testing, use `--dart-define=GEMINI_API_KEY=your_key`.
- For production, recommend a small backend/proxy.
- Keep the AI service abstract so it can later move from direct Flutter calls to a backend.

---

## Architecture

Use **feature-first clean architecture**.

Each feature should contain:
- `data/`
- `domain/`
- `presentation/`

Use reusable core layers for:
- `constants/`
- `theme/`
- `routing/`
- `errors/`
- `widgets/`
- `services/`
- `utils/`

---

## Important AI Rule

The AI output should be structured JSON whenever possible.

**Expected AI output format:**

```json
{
  "title": "",
  "shortSummary": "",
  "detailedSummary": "",
  "minutesOfMeeting": [],
  "decisions": [],
  "tasks": [
    {
      "title": "",
      "description": "",
      "assignee": "",
      "dueDate": "",
      "priority": "low | medium | high",
      "status": "pending"
    }
  ],
  "participants": [],
  "followUps": []
}
```

---

## Security Rules

- Do not hardcode API keys.
- Use environment variables or dart-define for development.
- Add `.env` files to `.gitignore`.
- For production, recommend a backend proxy for the Gemini API key.
- Never store raw meeting files in Firestore.
- Store only metadata and generated results.

---

## Output Rule

When asked to generate code:
- Provide complete files.
- Mention file paths.
- Do not skip important imports.
- Keep code clean and readable.
- Avoid overengineering.
