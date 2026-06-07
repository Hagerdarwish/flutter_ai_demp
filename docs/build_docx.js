/*
 * MeetFlow AI — Graduation Project Document builder (full document)
 * Run: node docs/build_docx.js   ->   docs/MeetFlow_AI_Graduation_Project.docx
 */
const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  AlignmentType, LevelFormat, HeadingLevel, BorderStyle, WidthType,
  ShadingType, VerticalAlign, PageNumber, PageBreak, Footer,
  TableOfContents, ImageRun,
} = require("docx");

// ---- Page geometry (A4, ~2.25cm margins) ----
const PAGE = { width: 11906, height: 16838 };
const MARGIN = 1276;
const CONTENT_W = PAGE.width - MARGIN * 2; // 9354 DXA
const FONT = "Times New Roman";

// ---- Inline run helpers ----
const T  = (t, o = {}) => new TextRun({ text: t, ...o });
const B  = (t) => new TextRun({ text: t, bold: true });
const PH = (t) => new TextRun({ text: t, color: "C00000", italics: true }); // placeholder (red italic)

// ---- Block helpers ----
function body(content, opts = {}) {
  return new Paragraph({
    spacing: { line: 276, after: 160 },
    alignment: opts.align || AlignmentType.JUSTIFIED,
    children: Array.isArray(content) ? content : [T(content)],
  });
}
const h1 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_1, children: [T(t)] });
const h2 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_2, children: [T(t)] });
const bullet = (content) => new Paragraph({
  numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 },
  children: Array.isArray(content) ? content : [T(content)],
});
const numbered = (content) => new Paragraph({
  numbering: { reference: "numbers", level: 0 }, spacing: { after: 80 },
  children: Array.isArray(content) ? content : [T(content)],
});
const pageBreak = () => new Paragraph({ children: [new PageBreak()] });

// ---- Diagram images ----
const DIAG = path.join(__dirname, "diagrams");
function img(filename, widthPx, heightPx, caption) {
  const imgPath = path.join(DIAG, filename);
  // Scale to fit content width (9354 DXA = ~16.6 cm); 1 DXA = 1/1440 inch; 1 inch = 96px screen
  // We target a max display width of 560pt (~7.78in). Derive EMU from px at 150dpi.
  const DPI = 150;
  const MAX_W_IN = 7.0;
  const scaleIn = Math.min(MAX_W_IN, widthPx / DPI);
  const scaleH  = scaleIn * (heightPx / widthPx);
  const toEmu   = (inches) => Math.round(inches * 914400);
  return [
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 160, after: 40 },
      children: [new ImageRun({
        type: "png",
        data: fs.readFileSync(imgPath),
        transformation: { width: Math.round(scaleIn * DPI * (96/DPI)), height: Math.round(scaleH * DPI * (96/DPI)) },
        altText: { title: caption, description: caption, name: filename },
      })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 200 },
      children: [T(caption, { italics: true, size: 20, color: "595959" })],
    }),
  ];
}
function figureBox(caption) {
  // map captions to the right PNG
  if (caption.includes("2.1")) return img("fig2_1_asis_flow.png",   1350, 1650, caption);
  if (caption.includes("4.1")) return img("fig4_1_architecture.png",1950,  1200, caption);
  if (caption.includes("5.1")) return img("fig5_1_usecase.png",     1950,  1350, caption);
  if (caption.includes("5.2")) return img("fig5_2_erd.png",         1950,  1200, caption);
  if (caption.includes("5.3")) {
    // Screenshots — still placeholder; user will provide
    const dash = { style: BorderStyle.DASHED, size: 4, color: "9CA3AF", space: 6 };
    return [new Paragraph({
      alignment: AlignmentType.CENTER, spacing: { before: 200, after: 60, line: 276 },
      border: { top: dash, bottom: dash, left: dash, right: dash },
      children: [ T("[ App Screenshots Placeholder ]", { color: "9CA3AF", bold: true }),
                  new TextRun({ break: 1 }), PH(caption) ],
    })];
  }
  if (caption.includes("5.4")) return img("fig5_4_sequence.png",   2100,  1500, caption);
  if (caption.includes("5.5")) return img("fig5_5_component.png",  2100,  1350, caption);
  if (caption.includes("7.1")) return img("fig7_1_results.png",    1950,   750, caption);
  // fallback
  const dash = { style: BorderStyle.DASHED, size: 4, color: "9CA3AF", space: 6 };
  return [new Paragraph({
    alignment: AlignmentType.CENTER, spacing: { before: 160, after: 160 },
    border: { top: dash, bottom: dash, left: dash, right: dash },
    children: [PH(caption)],
  })];
}

// ---- Table helpers ----
const cb = { style: BorderStyle.SINGLE, size: 4, color: "BFBFBF" };
const cbs = { top: cb, bottom: cb, left: cb, right: cb };
const cm = { top: 60, bottom: 60, left: 110, right: 110 };
function cell(content, { w, fill, bold, align } = {}) {
  const runs = Array.isArray(content) ? content : [new TextRun({ text: String(content), bold: !!bold })];
  return new TableCell({
    borders: cbs, margins: cm, width: { size: w, type: WidthType.DXA },
    shading: fill ? { fill, type: ShadingType.CLEAR } : undefined,
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({ alignment: align || AlignmentType.LEFT, spacing: { line: 252 }, children: runs })],
  });
}
// generic table: colWidths[], header[] (strings), rows[][] (string | run[])
function table(colWidths, header, rows) {
  const headerRow = new TableRow({
    tableHeader: true,
    children: header.map((htxt, i) => cell(htxt, { w: colWidths[i], fill: "D9E2F3", bold: true })),
  });
  const dataRows = rows.map((r) => new TableRow({
    children: r.map((c, i) => cell(c, { w: colWidths[i] })),
  }));
  return new Table({ width: { size: CONTENT_W, type: WidthType.DXA }, columnWidths: colWidths, rows: [headerRow, ...dataRows] });
}
const spacer = (after = 160) => new Paragraph({ spacing: { after }, children: [] });

// ============================================================
// COVER PAGE
// ============================================================
const center = (runs, after = 60) => new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after }, children: runs });

const coverInfoTable = new Table({
  width: { size: CONTENT_W, type: WidthType.DXA }, columnWidths: [3200, 6154],
  rows: [
    ["Student Name", [T("Hager Elsayed Darwish")]],
    ["Student ID", [T("202401385")]],
    ["Program", [T("Master of Software Engineering")]],
    ["Track", [T("Coursework Track")]],
    ["Supervisor Name", [PH("[Insert supervisor full name]")]],
    ["Academic Year", [PH("[20XX / 20XX]")]],
    ["Submission Date", [PH("[Month Day, Year]")]],
  ].map(([k, v]) => new TableRow({ children: [cell(k, { w: 3200, fill: "EFEFEF", bold: true }), cell(v, { w: 6154 })] })),
});

const docControlTable = new Table({
  width: { size: CONTENT_W, type: WidthType.DXA }, columnWidths: [1400, 2400, 3154, 2400],
  rows: [
    new TableRow({ tableHeader: true, children: [
      cell("Version", { w: 1400, fill: "D9E2F3", bold: true }),
      cell("Date", { w: 2400, fill: "D9E2F3", bold: true }),
      cell("Prepared / Updated By", { w: 3154, fill: "D9E2F3", bold: true }),
      cell("Notes", { w: 2400, fill: "D9E2F3", bold: true }),
    ]}),
    new TableRow({ children: [
      cell("0.1", { w: 1400 }), cell([PH("[Date]")], { w: 2400 }),
      cell("Hager Elsayed Darwish", { w: 3154 }), cell("Initial draft", { w: 2400 }),
    ]}),
  ],
});

const coverPage = [
  center([T("Cairo University", { bold: true, size: 28 })], 40),
  center([T("Faculty of Graduate Studies for Statistical Research", { size: 24 })], 40),
  center([T("Software Engineering Program", { size: 24 })], 560),
  center([T("Professional Master’s Graduation Project", { bold: true, size: 26 })], 40),
  center([T("Software Engineering Program – Coursework Track", { italics: true, size: 22 })], 760),
  center([T("Project Title", { bold: true, size: 22, color: "595959" })], 80),
  center([PH("[Insert the full project title here]")], 100),
  center([T("(suggested: “MeetFlow AI: An AI-Powered Mobile Application for Automated Meeting Documentation and Task Tracking”)", { size: 18, italics: true, color: "808080" })], 680),
  coverInfoTable,
  spacer(460),
  center([T("Submitted in partial fulfillment of the requirements for the Professional Master’s Degree in Software Engineering.", { italics: true, size: 20 })], 640),
  new Paragraph({ spacing: { before: 160, after: 140 }, children: [T("Document Control", { bold: true, size: 24 })] }),
  docControlTable,
  pageBreak(),
];

// ============================================================
// TABLE OF CONTENTS
// ============================================================
const tocSection = [
  h1("Table of Contents"),
  new Paragraph({ spacing: { after: 120 }, children: [
    B("Note: "),
    PH("Right-click this Table of Contents in Microsoft Word and choose “Update Field” to regenerate page numbers before final submission."),
  ]}),
  new TableOfContents("Table of Contents", { hyperlink: true, headingStyleRange: "1-2" }),
  pageBreak(),
];

// ============================================================
// ABSTRACT
// ============================================================
const abstractSection = [
  h1("Abstract"),
  body([T("Meetings are a primary medium for decision-making in academic, professional, and business environments, yet the knowledge produced during them is frequently lost. Notes are taken inconsistently, action items are forgotten, and reviewing a recording to recover decisions is slow and error-prone. This project addresses the problem of capturing meeting outcomes in a structured, reliable, and reusable form.")]),
  body([
    T("The proposed solution, "), B("MeetFlow AI"),
    T(", is a cross-platform mobile application that automatically transforms meeting audio, video, or publicly accessible transcript/recording links into structured documentation. Authenticated users upload a recording or paste a link, and the system generates a concise summary, a detailed summary, minutes of meeting, extracted decisions, and a list of actionable tasks. Generated tasks are persisted and can be tracked after the meeting, giving users a single place to follow up on commitments."),
  ]),
  body([T("The system is implemented in Flutter and Dart using a feature-first clean architecture. It uses Firebase Authentication for secure sign-in and Cloud Firestore for per-user data persistence, with Riverpod for state management and GoRouter for navigation. The artificial-intelligence capability is provided by Google’s Gemini multimodal large language model, accessed through Firebase AI Logic so that the API key is never embedded in the client. The model is prompted to return a strict JSON schema and to preserve the original meeting language (for example, Arabic input yields Arabic output).")]),
  body([
    T("A working prototype was implemented and validated against the project objectives. The application demonstrates a complete end-to-end workflow — authentication, media import, AI processing, structured storage, and post-meeting task tracking — and shows that a lightweight, serverless mobile client can deliver useful automated meeting documentation without a custom backend. "),
    PH("[Add one or two sentences summarizing measured results once evaluation screenshots/metrics are available.]"),
  ]),
  h2("Keywords"),
  body([T("Mobile Application Development, Flutter, Generative AI, Large Language Models, Gemini, Meeting Documentation, Firebase, Cloud Firestore, Task Management.")]),
  pageBreak(),
];

// ============================================================
// CHAPTER 1 — INTRODUCTION
// ============================================================
const ch1 = [
  h1("1. Introduction"),

  h2("1.1 Background"),
  body([T("Meetings remain one of the most common knowledge-work activities across academia, industry, and government. They are where requirements are clarified, decisions are made, and responsibilities are assigned. However, the value of a meeting is realized only if its outcomes are captured and acted upon. In practice, much of this value is lost: attendees take fragmentary notes, recordings are rarely revisited, and the link between what was decided and who must act is weak.")]),
  body([T("In parallel, generative artificial intelligence has matured rapidly. Modern large language models (LLMs) can summarize long passages, extract entities, and follow structured output instructions. The latest generation of multimodal models, such as Google’s Gemini, can additionally accept audio and video directly, removing the need for a separate speech-to-text stage. Combined with cloud platforms that offer authentication, databases, and managed AI access on free or low-cost tiers, it is now feasible for a single developer to build an intelligent, serverless mobile application. This project sits at the intersection of these trends: applying multimodal generative AI to the long-standing problem of meeting documentation, delivered through a modern cross-platform mobile client.")]),

  h2("1.2 Project Motivation"),
  body([T("The motivation for MeetFlow AI is both practical and technical. From a practical standpoint, professionals and students lose significant time manually writing minutes, and important action items routinely slip because they are never recorded in a trackable form. A tool that converts a raw recording into a clean summary, a list of decisions, and a set of trackable tasks directly addresses this pain.")]),
  body([T("From a technical and educational standpoint, the project is an opportunity to demonstrate sound software-engineering practice: a clean, layered architecture; secure handling of credentials and AI keys; reactive state management; and the integration of a third-party AI capability behind an abstraction that can later be replaced by a backend service. It also explores a genuinely useful capability of multimodal LLMs — processing audio/video directly — and the engineering required to make their output reliable through strict structured prompting and defensive parsing.")]),

  h2("1.3 Project Objectives"),
  body([T("The project pursues the following specific and measurable objectives:")]),
  numbered([B("O1. "), T("Provide secure user access — implement email/password registration, login, password reset, and persistent sessions using Firebase Authentication, with each user’s data isolated from others.")]),
  numbered([B("O2. "), T("Enable flexible meeting import — allow users to upload audio/video files (MP3, WAV, M4A, MP4, MOV, up to 50 MB) or paste a public transcript/recording link as the input source.")]),
  numbered([B("O3. "), T("Generate structured documentation automatically — use a multimodal LLM to produce a short summary, detailed summary, minutes of meeting, extracted decisions, participants, follow-ups, and action items in a fixed JSON schema, preserving the original meeting language.")]),
  numbered([B("O4. "), T("Support post-meeting follow-through — persist generated meetings and tasks per user, present a meeting history and detail view, and allow action items to be tracked through pending, in-progress, and completed states.")]),

  h2("1.4 Project Scope"),
  body([B("In scope: "), T("a mobile application (Android and iOS via Flutter); email/password authentication; importing meetings from local audio/video files or public HTTP(S) links; AI generation of summaries, minutes, decisions, participants, follow-ups, and tasks; per-user persistence of meetings, decisions, and tasks; meeting history and details; task tracking; light/dark theming; and bilingual output (the AI preserves the meeting’s language, validated primarily for English and Arabic).")]),
  body([B("Out of scope (for the MVP): "), T("real-time/live transcription during a meeting; automatically joining meetings as a bot on Zoom/Google Meet/Microsoft Teams (such invite links are detected and rejected with guidance); storing raw media files in the cloud (only metadata and generated results are stored); team collaboration and sharing across accounts; and a dedicated production backend. A backend proxy for the AI key is recommended as future work.")]),
  body([B("Assumptions and constraints: "), T("the user’s device has internet connectivity; the meeting recording is reasonably audible; uploaded files respect the 50 MB inline-processing limit imposed by direct client-to-model requests; and the project relies on free or developer-tier quotas of Firebase and Gemini, so unlimited usage is not assumed.")]),

  h2("1.5 Document Organization"),
  bullet([B("Chapter 2 – Problem Definition: "), T("defines the problem, stakeholders, the current (as-is) situation, its impact, and the requirements derived from it.")]),
  bullet([B("Chapter 3 – Existing Solution Approaches: "), T("reviews comparable tools and techniques and identifies the gap this project fills.")]),
  bullet([B("Chapter 4 – Proposed Solution: "), T("describes the solution, its rationale, key features, architecture, technology stack, and risks.")]),
  bullet([B("Chapter 5 – System Analysis and Design: "), T("presents functional and non-functional requirements, use cases, the data model, UI design, and design diagrams.")]),
  bullet([B("Chapter 6 – Implementation: "), T("details the development environment, implementation of the main modules, key design decisions, security, and deployment.")]),
  bullet([B("Chapter 7 – Testing and Evaluation: "), T("describes the testing strategy, test cases, metrics, results, and validation against the objectives.")]),
  bullet([B("Chapter 8 – Discussion: "), T("reflects on the problem status after the solution, benefits, remaining limitations, and lessons learned.")]),
  bullet([B("Chapter 9 – Conclusion and Future Work: "), T("summarizes the project, its contributions, and proposed enhancements.")]),
  pageBreak(),
];

// ============================================================
// CHAPTER 2 — PROBLEM DEFINITION
// ============================================================
const ch2 = [
  h1("2. Problem Definition"),

  h2("2.1 Problem Statement"),
  body([T("Organizations and individuals conduct frequent meetings but lack a fast, reliable, and low-cost way to convert those meetings into structured, actionable records. Manual minute-taking is inconsistent and labor-intensive; it distracts a participant from the discussion and still produces notes that vary in quality. Decisions and action items are often not recorded in a structured form, so accountability after the meeting is weak and follow-up depends on memory. Existing automated tools that solve part of this problem are typically subscription-based desktop/web services, are not optimized for a lightweight personal mobile workflow, and often handle non-English content (such as Arabic) poorly.")]),
  body([T("The core problem is therefore: how to automatically transform a raw meeting recording or transcript into accurate, structured documentation — summary, minutes, decisions, and trackable tasks — within a single, secure, low-cost mobile application.")]),

  h2("2.2 Stakeholders and Users"),
  body([T("The following stakeholders and system actors are affected by the problem:")]),
  table([2600, 6754],
    ["Stakeholder / Actor", "Interest / Role"],
    [
      ["Individual professional", "Primary user; needs quick minutes, decisions, and a personal task list after meetings."],
      ["Student / researcher", "Captures lectures, supervision meetings, and study-group sessions into reviewable notes."],
      ["Team lead / project manager", "Needs decisions and action items with owners to drive follow-up and accountability."],
      ["System (AI service)", "The Gemini multimodal model that analyzes media and returns structured documentation."],
      ["System (Firebase)", "Authentication and Cloud Firestore that authenticate users and persist their data."],
      ["Developer / maintainer", "Builds and maintains the application; concerned with security, cost, and maintainability."],
    ]),
  spacer(),

  h2("2.3 Current Situation / As-Is Process"),
  body([T("Today, a typical meeting follow-up workflow is largely manual:")]),
  numbered([T("A participant takes free-form notes during the meeting, or the meeting is recorded for later review.")]),
  numbered([T("After the meeting, someone re-listens to the recording or rewrites their notes to produce minutes — a slow, error-prone task that is frequently skipped.")]),
  numbered([T("Decisions and action items, if captured at all, are scattered across notes, chat messages, or email and are not tracked in a consistent place.")]),
  numbered([T("Generic AI chat tools or transcription services may be used ad hoc, but they require manual copying, are not structured for meetings, and raise privacy and cost concerns.")]),
  ...figureBox("Figure 2.1: As-is meeting documentation process (insert a flow/activity diagram or annotated screenshot of the current manual workflow)."),
  spacer(),

  h2("2.4 Problem Impact"),
  body([T("Failing to solve this problem has measurable consequences across several dimensions:")]),
  bullet([B("Time and cost: "), T("manually writing minutes for a one-hour meeting can take 30–60 minutes of skilled effort, repeated for every meeting.")]),
  bullet([B("Quality and accuracy: "), T("hand-written minutes omit details and are inconsistent between authors and meetings.")]),
  bullet([B("Accountability: "), T("when action items are not recorded with owners and status, commitments are forgotten and follow-up fails.")]),
  bullet([B("Accessibility and language: "), T("non-English meetings (e.g., Arabic) are poorly served by many existing tools, excluding a large group of users.")]),
  bullet([B("Privacy and cost: "), T("pasting sensitive meeting content into ad hoc or paid third-party services raises confidentiality and budget concerns.")]),
  spacer(),

  h2("2.5 Requirements Derived from the Problem"),
  body([T("The problem definition leads directly to the following high-level requirements, refined in Chapter 5:")]),
  bullet([B("Functional: "), T("secure per-user access; import of meeting audio/video files and public links; automatic generation of structured documentation (summary, minutes, decisions, participants, follow-ups, tasks); persistence and history of meetings; and tracking of action items.")]),
  bullet([B("Non-functional: "), T("security of credentials and the AI key; per-user data isolation; usability (few steps to a result); responsive feedback during processing; reliability and graceful error handling; bilingual (Arabic/English) output; and low operating cost using free/managed tiers.")]),
  pageBreak(),
];

// ============================================================
// CHAPTER 3 — EXISTING SOLUTION APPROACHES
// ============================================================
const ch3 = [
  h1("3. Existing Solution Approaches"),

  h2("3.1 Literature / Market Review"),
  body([T("A range of commercial tools and platforms already address parts of the meeting-documentation problem. Representative examples include:")]),
  bullet([B("Otter.ai and Fireflies.ai — "), T("AI meeting assistants that transcribe and summarize meetings, primarily as web/desktop services with subscription tiers.")]),
  bullet([B("Microsoft Teams (Copilot) and Zoom AI Companion — "), T("AI features embedded inside specific conferencing platforms, producing recaps and action items but locked to that platform and its licensing.")]),
  bullet([B("Google Meet / Gemini “take notes for me” — "), T("automated notes within Google’s ecosystem, tied to Workspace accounts.")]),
  bullet([B("tl;dv, Fathom, and similar — "), T("meeting recorders with AI summaries focused on sales/customer calls.")]),
  bullet([B("General-purpose LLM chat tools (e.g., ChatGPT, Gemini app) — "), T("can summarize a pasted transcript but require manual copy-paste, are unstructured for meetings, and offer no persistence or task tracking.")]),
  body([PH("[Add proper academic/industry citations for the tools above and for any literature on automatic summarization and speech recognition, formatted in the required citation style — see References.]")]),

  h2("3.2 Existing Methods and Techniques"),
  body([T("Underlying these products are two broad technical approaches:")]),
  bullet([B("Pipeline approach (ASR + summarization): "), T("audio is first converted to text by an automatic speech recognition (ASR) engine, then a separate summarization model condenses the transcript. This is modular but introduces two failure points and loses non-verbal context.")]),
  bullet([B("End-to-end multimodal approach: "), T("a single multimodal LLM (such as Gemini) accepts the audio/video directly and produces the documentation, removing the explicit transcription stage. This is the approach adopted in this project.")]),
  body([T("For summarization itself, the literature distinguishes extractive methods (selecting representative sentences) from abstractive methods (generating new sentences). Modern LLMs are abstractive and can additionally perform structured extraction — returning typed fields such as decisions and tasks — when instructed with a schema.")]),

  h2("3.3 Comparative Analysis"),
  body([T("The table below compares the typical existing approach with the proposed solution across key criteria.")]),
  table([2200, 2900, 2900, 1354],
    ["Criterion", "Current / Existing Approach", "Proposed Solution (MeetFlow AI)", "Comment"],
    [
      ["Platform", "Mostly web/desktop or tied to one conferencing platform", "Native cross-platform mobile app (Android/iOS)", "Personal, on-the-go use"],
      ["Cost", "Recurring subscription per user", "Free/managed tiers, no paid API in client", "Low barrier for individuals"],
      ["Pipeline", "Often separate ASR + summarizer", "Single multimodal model (audio/video → JSON)", "Fewer failure points"],
      ["Output structure", "Free-text recap", "Strict JSON: summary, decisions, tasks, etc.", "Directly trackable"],
      ["Task tracking", "Limited or absent", "Built-in task list with status", "Closes the follow-up loop"],
      ["Language (Arabic)", "Often weak", "Preserves meeting language", "Inclusive of Arabic users"],
      ["Data control", "Stored on vendor cloud", "Per-user Firestore; raw media not stored", "Privacy-conscious"],
    ]),
  spacer(),

  h2("3.4 Limitations of Existing Solutions"),
  body([T("The review reveals several gaps that justify the proposed solution:")]),
  bullet([B("Cost: "), T("most mature tools require recurring subscriptions, a barrier for individual students and professionals.")]),
  bullet([B("Platform lock-in: "), T("the strongest AI recaps are embedded in specific conferencing or productivity ecosystems and are unavailable for arbitrary recordings.")]),
  bullet([B("Mobile-first gap: "), T("few solutions target a lightweight, personal mobile workflow for arbitrary audio/video files or links.")]),
  bullet([B("Language coverage: "), T("non-English meetings, particularly Arabic, are often handled poorly.")]),
  bullet([B("Privacy: "), T("uploading raw recordings to vendor clouds, or pasting content into ad hoc chat tools, raises confidentiality concerns; MeetFlow AI stores only metadata and generated results, not raw media.")]),
  pageBreak(),
];

// ============================================================
// CHAPTER 4 — PROPOSED SOLUTION
// ============================================================
const ch4 = [
  h1("4. Proposed Solution"),

  h2("4.1 Solution Overview"),
  body([T("MeetFlow AI is a cross-platform mobile application that automates meeting documentation end-to-end. After signing in, a user imports a meeting either by selecting a local audio/video file or by pasting a public transcript/recording link. The application creates a draft meeting record, sends the media or fetched content to a multimodal AI model, and receives structured documentation. It then stores the results — summaries, minutes, decisions, participants, follow-ups, and action items — under the user’s account and presents them in a meeting detail view. Generated action items are also surfaced in a dedicated task list where the user tracks them to completion.")]),

  h2("4.2 Solution Rationale"),
  body([T("The design choices follow directly from the limitations identified in Chapter 3:")]),
  bullet([B("Multimodal LLM over an ASR pipeline: "), T("sending audio/video directly to Gemini removes a separate transcription stage, reduces integration complexity, and lets one model produce both the transcript-derived summary and the structured fields.")]),
  bullet([B("Flutter for the client: "), T("a single Dart codebase targets Android and iOS, which suits a solo project and a mobile-first workflow.")]),
  bullet([B("Serverless Firebase backend: "), T("Firebase Authentication and Cloud Firestore provide secure auth and a realtime, per-user database on a free tier, avoiding a custom server in the MVP.")]),
  bullet([B("Firebase AI Logic for the key: "), T("accessing Gemini through Firebase AI Logic keeps the API key off the client, addressing the most important security risk of calling an AI API directly from a mobile app.")]),
  bullet([B("Strict JSON contract: "), T("instructing the model to return a fixed JSON schema makes the AI output programmatically reliable and directly mappable to the data model.")]),

  h2("4.3 Key Features"),
  bullet([B("Secure authentication: "), T("email/password registration, login, password reset, persistent session, and per-user data isolation.")]),
  bullet([B("Flexible import: "), T("upload audio/video (MP3, WAV, M4A, MP4, MOV ≤ 50 MB) or paste a public link; invite links (Zoom/Meet/Teams) are detected and rejected with guidance.")]),
  bullet([B("AI documentation: "), T("automatic short summary, detailed summary, minutes of meeting, decisions (with owners), participants, follow-ups, and tasks.")]),
  bullet([B("Language preservation: "), T("output is produced in the meeting’s own language (validated for English and Arabic).")]),
  bullet([B("Meeting history & details: "), T("a realtime list of past meetings with a rich detail view of all generated content.")]),
  bullet([B("Task tracking: "), T("action items become trackable tasks with priority and a pending / in-progress / completed status.")]),
  bullet([B("Dashboard & theming: "), T("home dashboard statistics, light/dark Material 3 theme, and content sharing.")]),

  h2("4.4 Proposed Architecture"),
  body([T("The application follows a feature-first clean architecture with three horizontal layers per feature — presentation, domain, and data — supported by shared core layers (constants, theme, routing, services, errors, widgets, utilities). The presentation layer (Flutter widgets and Riverpod providers) reacts to state; the domain layer defines entities and repository contracts; and the data layer implements repositories that talk to Firebase. AI access is encapsulated behind an abstract service so the implementation can later move to a backend proxy without changing callers.")]),
  body([B("High-level data flow (file import): "), T("UI → MeetingImport provider → create draft in Firestore → GeminiService (Firebase AI Logic → Gemini) → JSON result → MeetingsRepository batch-saves summary, decisions, and tasks → Firestore streams update the UI.")]),
  ...figureBox("Figure 4.1: High-level system architecture (insert a component/deployment diagram showing the Flutter app, its layers, Firebase Authentication, Cloud Firestore, Firebase AI Logic, and the Gemini model)."),
  spacer(),

  h2("4.5 Technology Stack"),
  table([2500, 3100, 3754],
    ["Technology", "Role in the System", "Justification"],
    [
      ["Flutter (stable) + Dart", "Cross-platform mobile UI", "Single codebase for Android/iOS; fast UI development; ideal for a solo project."],
      ["Firebase Authentication", "User sign-up, login, sessions", "Secure, managed email/password auth on a free tier."],
      ["Cloud Firestore", "Per-user data persistence", "Realtime NoSQL database with offline support and simple security rules."],
      ["Firebase AI Logic + Gemini 2.5 Flash", "Multimodal AI generation", "Processes audio/video directly; keeps the API key off the client."],
      ["Riverpod", "State management", "Compile-safe, testable reactive providers."],
      ["GoRouter", "Navigation", "Declarative routing with a shell for bottom navigation."],
      ["Material 3 + google_fonts", "Design system / theming", "Modern UI with light/dark themes."],
      ["file_picker, http, share_plus, url_launcher", "Device & I/O integration", "File selection, link fetching, sharing, and opening URLs."],
      ["uuid, intl, flutter_markdown", "Utilities", "ID generation, date/number formatting, and rich text rendering."],
    ]),
  spacer(),

  h2("4.6 Risks and Constraints"),
  table([2600, 3600, 3154],
    ["Risk / Constraint", "Description", "Mitigation"],
    [
      ["AI output variability", "LLM may return malformed or off-schema JSON", "Strict schema prompt + defensive parsing that strips code fences and fails gracefully."],
      ["File size limit", "Inline client-to-model requests are limited (~20–50 MB)", "Enforce a 50 MB cap and clear messaging; recommend shorter clips."],
      ["API quota / cost", "Free/dev Gemini quota is finite", "Keep the AI service abstract; recommend a backend proxy and caching for production."],
      ["Key exposure", "Embedding the AI key in the client is unsafe", "Use Firebase AI Logic so the key is managed server-side."],
      ["Connectivity", "Processing requires the network", "Detect offline state and surface a clear, retryable error."],
      ["Privacy of recordings", "Meeting content can be sensitive", "Store only metadata and generated results; never persist raw media."],
    ]),
  pageBreak(),
];

// ============================================================
// CHAPTER 5 — SYSTEM ANALYSIS AND DESIGN
// ============================================================
const ch5 = [
  h1("5. System Analysis and Design"),

  h2("5.1 Functional Requirements"),
  table([1300, 5054, 1300, 1700],
    ["ID", "Requirement", "Priority", "Source / Rationale"],
    [
      ["FR-01", "Register a new account with name, email, and password", "High", "O1 / secure access"],
      ["FR-02", "Log in with email and password", "High", "O1"],
      ["FR-03", "Reset password via email", "Medium", "O1 / usability"],
      ["FR-04", "Log out and persist session across launches", "High", "O1"],
      ["FR-05", "Import a meeting from an audio/video file (≤ 50 MB)", "High", "O2"],
      ["FR-06", "Import a meeting from a public transcript/recording link", "Medium", "O2"],
      ["FR-07", "Detect and reject conferencing invite links with guidance", "Medium", "O2 / scope"],
      ["FR-08", "Generate structured documentation (summary, minutes, decisions, participants, follow-ups, tasks)", "High", "O3"],
      ["FR-09", "Preserve the original meeting language in the output", "Medium", "O3 / inclusivity"],
      ["FR-10", "Persist meetings, decisions, and tasks per user", "High", "O4"],
      ["FR-11", "Display a realtime meeting history list", "High", "O4"],
      ["FR-12", "Display a meeting detail view of all generated content", "High", "O4"],
      ["FR-13", "Track tasks through pending / in-progress / completed", "High", "O4"],
      ["FR-14", "Update task priority", "Low", "O4"],
      ["FR-15", "Show dashboard statistics (meetings, summaries, tasks, decisions)", "Low", "O4 / overview"],
      ["FR-16", "Delete a meeting and its sub-collections", "Medium", "Data management"],
      ["FR-17", "Mark a meeting as failed when processing errors", "Medium", "Reliability"],
      ["FR-18", "Toggle light/dark theme and share generated content", "Low", "Usability"],
    ]),
  spacer(),

  h2("5.2 Non-Functional Requirements"),
  table([1300, 5054, 1300, 1700],
    ["ID", "Requirement", "Priority", "Source / Rationale"],
    [
      ["NFR-01", "The AI API key must never be embedded in the client", "High", "Security"],
      ["NFR-02", "Each user can access only their own data", "High", "Security / privacy"],
      ["NFR-03", "Importing a meeting takes no more than a few simple steps", "Medium", "Usability"],
      ["NFR-04", "The UI shows clear progress states during processing", "Medium", "Usability"],
      ["NFR-05", "Errors are handled gracefully with human-readable messages", "High", "Reliability"],
      ["NFR-06", "Code follows a feature-first clean architecture", "High", "Maintainability"],
      ["NFR-07", "The app runs on both Android and iOS from one codebase", "Medium", "Portability"],
      ["NFR-08", "Data storage scales without a custom server (serverless)", "Medium", "Scalability"],
      ["NFR-09", "Raw meeting media is never stored in the cloud", "High", "Privacy"],
      ["NFR-10", "Output supports multiple languages (English and Arabic)", "Medium", "Internationalization"],
      ["NFR-11", "The system operates on free/managed service tiers", "Medium", "Cost"],
    ]),
  spacer(),

  h2("5.3 Use Case Model / User Stories"),
  body([T("The primary actor is the authenticated User; the supporting actors are the AI service (Gemini via Firebase AI Logic) and the persistence service (Cloud Firestore). The main use cases are: Register, Log In, Reset Password, Import Meeting from File, Import Meeting from Link, View Meeting History, View Meeting Details, Track Task, and Delete Meeting.")]),
  ...figureBox("Figure 5.1: Use case diagram (insert a UML use case diagram showing the User actor, the AI and Firestore supporting actors, and the use cases listed above)."),
  body([B("Representative detailed use case — UC-04: Import Meeting from File")]),
  table([2400, 6954],
    ["Field", "Description"],
    [
      ["Actor", "Authenticated User"],
      ["Preconditions", "User is logged in and has a supported audio/video file (≤ 50 MB)."],
      ["Main flow", "1. User opens Import. 2. Selects a file. 3. Enters/confirms title and date. 4. Submits. 5. System creates a draft meeting, sends media to the AI, saves the structured result, and opens the meeting details."],
      ["Alternative flows", "Unsupported format or oversize file → validation error; AI/network failure → meeting marked failed and an error message is shown."],
      ["Postconditions", "A completed meeting with summary, decisions, and tasks is stored under the user’s account."],
    ]),
  body([B("Sample user stories: ")]),
  bullet("As a user, I want to upload a recording and get minutes automatically, so that I save time writing them."),
  bullet("As a user, I want decisions and action items extracted with owners, so that follow-up is clear."),
  bullet("As a user, I want my action items in one task list with status, so that nothing is forgotten."),
  bullet("As an Arabic speaker, I want output in Arabic when the meeting is in Arabic, so that the notes are usable."),
  spacer(),

  h2("5.4 Data Model"),
  body([T("Data is stored in Cloud Firestore and namespaced per user. Raw media is never stored — only metadata and generated results. The collection structure is:")]),
  table([4400, 4954],
    ["Path", "Contents"],
    [
      ["users/{userId}", "User profile (id, name, email, timestamps)."],
      ["users/{userId}/meetings/{meetingId}", "Meeting metadata + summaries, minutes, participants, follow-ups, status."],
      ["users/{userId}/meetings/{meetingId}/decisions/{id}", "Extracted decisions (text, owner)."],
      ["users/{userId}/meetings/{meetingId}/tasks/{id}", "Action items scoped to the meeting."],
      ["users/{userId}/tasks/{id}", "Same action items duplicated at user level for the global Tasks tab."],
    ]),
  body([T("The principal entities and their key fields are:")]),
  bullet([B("AppUser: "), T("id, name, email, createdAt, updatedAt.")]),
  bullet([B("Meeting: "), T("id, userId, title, sourceType (file|link), sourceName, sourceUrl, fileType, status (draft|processing|completed|failed), shortSummary, detailedSummary, minutesOfMeeting[], participants[], followUps[], createdAt, updatedAt, processedAt.")]),
  bullet([B("Decision: "), T("id, text, owner, createdAt.")]),
  bullet([B("MeetingTask: "), T("id, meetingId, meetingTitle, title, description, assignee, dueDate, priority (low|medium|high), status (pending|inProgress|completed), createdAt, updatedAt.")]),
  body([T("Action items are written twice in a single atomic batch — under the meeting and at the user level — so the global Tasks tab can be queried directly without a collection-group query.")]),
  ...figureBox("Figure 5.2: Entity-Relationship / data model diagram (insert an ERD or class diagram showing AppUser, Meeting, Decision, and MeetingTask and their relationships)."),
  spacer(),

  h2("5.5 User Interface Design"),
  body([T("The interface uses Material 3 with a light and dark theme and a bottom-navigation shell containing four primary destinations: Home (dashboard), Meetings (history), Tasks, and Settings. Authentication screens (login, register, forgot password) and full-screen flows (import meeting, meeting details) sit outside the shell. The main screens are:")]),
  bullet([B("Splash: "), T("resolves auth state and routes to Home or Login.")]),
  bullet([B("Auth (Login / Register / Forgot Password): "), T("email/password forms with validation and error messages.")]),
  bullet([B("Home: "), T("dashboard statistics and recent meetings, with an entry point to import.")]),
  bullet([B("Import Meeting: "), T("choose a file or paste a link, set title/date, and start processing with live status.")]),
  bullet([B("Meetings & Meeting Details: "), T("history list and a detail view of summary, minutes, decisions, participants, follow-ups, and tasks.")]),
  bullet([B("Tasks: "), T("the consolidated action-item list with status and priority controls.")]),
  bullet([B("Settings: "), T("theme toggle, account, and logout.")]),
  ...figureBox("Figure 5.3: UI wireframes / app screenshots (insert wireframes or screenshots of the Splash, Login, Home, Import, Meeting Details, and Tasks screens, with the navigation flow between them)."),
  spacer(),

  h2("5.6 System Design Diagrams"),
  body([T("The dynamic behavior of the core feature — importing a meeting from a file — is summarized below and should be presented as a UML sequence diagram. The user triggers processing; the import provider creates a draft meeting in Firestore (status = processing); the Gemini service sends the media through Firebase AI Logic and receives JSON; the meetings repository batch-writes the summary, decisions, and tasks (status = completed); and Firestore streams update the UI. On any failure, the draft is marked failed.")]),
  ...figureBox("Figure 5.4: Sequence diagram — “Import meeting from file” (insert a UML sequence diagram for the flow described above)."),
  ...figureBox("Figure 5.5: Class / component diagram (insert a UML class or component diagram showing the presentation, domain, and data layers, the core services, and the Firebase dependencies)."),
  pageBreak(),
];

// ============================================================
// CHAPTER 6 — IMPLEMENTATION
// ============================================================
const ch6 = [
  h1("6. Implementation"),

  h2("6.1 Development Environment"),
  table([3000, 6354],
    ["Item", "Detail"],
    [
      ["Language / SDK", "Dart (SDK ≥ 3.0) with the Flutter stable framework"],
      ["IDE", [PH("[Android Studio / VS Code — confirm which you used]")]],
      ["Operating system", [PH("[Your development OS, e.g. Windows 11 / macOS]")]],
      ["Backend services", "Firebase Authentication, Cloud Firestore, Firebase AI Logic (Gemini)"],
      ["AI model", "gemini-2.5-flash (multimodal)"],
      ["Version control", [PH("[Git / GitHub repository URL]")]],
      ["Key packages", "firebase_core, firebase_auth, cloud_firestore, firebase_ai, flutter_riverpod, go_router, file_picker, http, google_fonts"],
    ]),
  spacer(),

  h2("6.2 Implementation Details"),
  body([T("The application is organized by feature (auth, home, meeting_import, meetings, tasks, settings), each split into presentation, domain, and data layers, with shared core modules for constants, theme, routing, services, errors, widgets, and utilities. The main building blocks are:")]),
  bullet([B("Authentication module: "), T("AuthRepositoryImpl wraps Firebase Authentication and, on sign-up/sign-in, creates or fetches the user’s Firestore profile. If Firestore is temporarily unavailable, it falls back to the Firebase Auth user so the app still works. Riverpod exposes the auth state, a current-user provider, and an action notifier for login/register/logout.")]),
  bullet([B("AI service: "), T("an abstract GeminiService with a GeminiServiceImpl that uses Firebase AI Logic. For files, the media bytes and a system prompt are sent as multimodal content; for links, the content is fetched over HTTP and sent as text or inline bytes depending on its type. Raw exceptions are converted into human-readable messages.")]),
  bullet([B("Import workflow: "), T("MeetingImportNotifier drives a state machine (idle → pickingFile → uploading → processing → saving → done/error), creating a draft meeting, calling the AI, saving results, and marking failures.")]),
  bullet([B("Persistence: "), T("MeetingsRepository performs all Firestore reads/writes, including the atomic batch that saves the meeting summary, its decisions, and its tasks (duplicated at user level), plus history streams and dashboard statistics. Entities own their own serialization (fromFirestore / toFirestore / fromAiMap).")]),
  bullet([B("Navigation & UI: "), T("GoRouter defines the routes and a bottom-navigation shell; Material 3 themes and reusable core widgets provide a consistent interface.")]),

  h2("6.3 Important Code / Configuration Decisions"),
  bullet([B("Key kept off the client: "), T("Gemini is accessed through Firebase AI Logic rather than embedding an API key in the app — the single most important security decision.")]),
  bullet([B("Strict JSON contract + defensive parsing: "), T("the model is instructed to return only a fixed JSON object; the parser strips markdown code fences and raises a typed AIException if parsing fails.")]),
  bullet([B("Language preservation: "), T("the system prompt instructs the model to detect the meeting language and write all fields in that same language (e.g., Arabic in → Arabic out).")]),
  bullet([B("Draft-then-update lifecycle: "), T("a meeting is created as a draft with status processing before the AI call, then updated to completed or failed, so the history list always reflects real state.")]),
  bullet([B("Duplicated task write: "), T("tasks are stored under both the meeting and the user in one batch, enabling a fast global Tasks tab without collection-group queries.")]),
  bullet([B("Abstraction for future backend: "), T("the AI capability sits behind an interface so it can later move to a backend proxy without changing the rest of the app.")]),
  body([T("A representative extract of the AI output schema is included in Appendix B.")]),

  h2("6.4 Security and Data Protection"),
  bullet([B("Authentication: "), T("Firebase Authentication manages credentials; passwords are never stored by the app.")]),
  bullet([B("AI key protection: "), T("Firebase AI Logic mediates access to Gemini so no API key ships in the client.")]),
  bullet([B("Per-user isolation: "), T("all data is stored under users/{userId}/… and access is gated by the authenticated user.")]),
  bullet([B("Data minimization: "), T("only metadata and generated results are stored — raw audio/video is never uploaded or persisted.")]),
  bullet([B("Input validation: "), T("file type and size are validated before processing, and invite links are rejected with guidance.")]),
  bullet([B("Graceful error handling: "), T("typed exceptions (AuthException, AIException, FileException, StorageException) produce clear, non-technical messages.")]),
  body([B("Recommended for production: "), new TextRun(""), PH("[Configure Cloud Firestore Security Rules to enforce that a user can read/write only their own users/{uid} subtree, and add a backend proxy for the AI key — note current status of these in your environment.]")]),

  h2("6.5 Deployment / Execution Instructions"),
  numbered([T("Install Flutter (stable) and run "), B("flutter pub get"), T(" in the project root.")]),
  numbered([T("Configure Firebase by running "), B("flutterfire configure"), T(" to generate lib/firebase_options.dart.")]),
  numbered([T("In the Firebase Console, enable Email/Password authentication, create a Cloud Firestore database, and enable Firebase AI Logic (Gemini).")]),
  numbered([T("Run the app on a device or emulator with "), B("flutter run"), T(".")]),
  numbered([T("Build a release with "), B("flutter build apk"), T(" (Android) or "), B("flutter build ios"), T(" (iOS).")]),
  pageBreak(),
];

// ============================================================
// CHAPTER 7 — TESTING AND EVALUATION
// ============================================================
const ch7 = [
  h1("7. Testing and Evaluation"),

  h2("7.1 Testing Strategy"),
  body([T("The system was validated mainly through manual functional and system testing of the end-to-end workflow on a real device/emulator, supported by exploratory testing of error and edge cases. The testing levels considered are:")]),
  bullet([B("Unit testing: "), T("validation logic, link detection, and JSON parsing are suitable for unit tests."), PH(" [State whether automated unit tests were written; none exist in the repository yet.]")]),
  bullet([B("Integration testing: "), T("the import provider together with the AI service and the repository, verifying the draft → process → save flow.")]),
  bullet([B("System / acceptance testing: "), T("full user journeys from registration through importing a meeting to tracking a task.")]),
  bullet([B("Negative testing: "), T("unsupported files, oversize files, invalid/invite links, and offline conditions.")]),

  h2("7.2 Test Cases"),
  body([T("Representative test cases are listed below. ")].concat([PH("Attach a screenshot as evidence for each and confirm the Actual Result / Status after running.")])),
  table([1100, 3254, 2600, 1600, 800],
    ["ID", "Scenario", "Expected Result", "Actual Result", "Status"],
    [
      ["TC-01", "Register with valid details", "Account created; user routed to Home", [PH("[evidence]")], [PH("[Pass]")]],
      ["TC-02", "Login with correct credentials", "User authenticated; Home shown", [PH("[evidence]")], [PH("[Pass]")]],
      ["TC-03", "Login with wrong password", "Clear “incorrect password” message", [PH("[evidence]")], [PH("[Pass]")]],
      ["TC-04", "Import a supported audio file", "Summary, decisions, and tasks generated and saved", [PH("[evidence]")], [PH("[Pass]")]],
      ["TC-05", "Import an Arabic meeting", "Output produced in Arabic", [PH("[evidence]")], [PH("[Pass]")]],
      ["TC-06", "Upload an oversize/unsupported file", "Validation error; no processing", [PH("[evidence]")], [PH("[Pass]")]],
      ["TC-07", "Paste a Zoom/Meet invite link", "Link rejected with guidance", [PH("[evidence]")], [PH("[Pass]")]],
      ["TC-08", "Process while offline", "Friendly network error; meeting marked failed", [PH("[evidence]")], [PH("[Pass]")]],
      ["TC-09", "Track a task to completed", "Status updates and persists", [PH("[evidence]")], [PH("[Pass]")]],
      ["TC-10", "Delete a meeting", "Meeting and its sub-data removed", [PH("[evidence]")], [PH("[Pass]")]],
    ]),
  spacer(),

  h2("7.3 Evaluation Metrics"),
  body([T("The solution can be evaluated using the following measures:")]),
  bullet([B("Functional completeness: "), T("proportion of objectives and functional requirements met (see 7.5).")]),
  bullet([B("Processing time: "), T("time from submission to displayed result per minute of recording."), PH(" [Record measured values.]")]),
  bullet([B("Output quality: "), T("human-rated accuracy/usefulness of summaries, decisions, and tasks on a sample of meetings."), PH(" [Add ratings.]")]),
  bullet([B("Reliability: "), T("rate of successful versus failed imports across test runs."), PH(" [Add figures.]")]),
  bullet([B("Usability: "), T("steps and time to complete a first import; optional user feedback."), PH(" [Add observations.]")]),

  h2("7.4 Results"),
  body([T("The prototype successfully performs the complete workflow — authentication, import, AI processing, structured storage, and task tracking — on supported inputs, and handles the negative cases above with clear messaging.")]),
  body([PH("[Insert results here: screenshots of generated meetings/tasks, a table or chart of processing times, and a short analysis once evaluation data is collected.]")]),
  ...figureBox("Figure 7.1: Results evidence (insert screenshots of a generated meeting summary, decisions, and task list, and any metrics charts)."),
  spacer(),

  h2("7.5 Validation Against Objectives"),
  table([1100, 5454, 1300, 1500],
    ["Objective", "How it was met", "Evidence", "Status"],
    [
      ["O1", "Email/password auth, reset, persistent session, per-user isolation", "TC-01–TC-03", [PH("[Met]")]],
      ["O2", "File and link import with validation and invite-link rejection", "TC-04, TC-06, TC-07", [PH("[Met]")]],
      ["O3", "Structured JSON documentation with language preservation", "TC-04, TC-05", [PH("[Met]")]],
      ["O4", "Persistence, history, details, and task tracking", "TC-09, TC-10", [PH("[Met]")]],
    ]),
  pageBreak(),
];

// ============================================================
// CHAPTER 8 — DISCUSSION
// ============================================================
const ch8 = [
  h1("8. Discussion After Applying the Solution"),

  h2("8.1 Problem Status After Solution"),
  body([T("After applying MeetFlow AI, the manual, error-prone steps of producing meeting documentation are largely automated. Instead of re-listening to a recording and hand-writing minutes, a user obtains a structured summary, a list of decisions, and trackable tasks within a single mobile workflow. The weak link between decisions and follow-up — a central part of the original problem — is addressed by turning action items into a persistent, status-tracked task list. The problem is therefore substantially mitigated for the supported scenarios, though not entirely eliminated (see 8.3).")]),

  h2("8.2 Benefits Achieved"),
  bullet([B("Time saved: "), T("minutes and action items are generated automatically rather than written by hand.")]),
  bullet([B("Consistency: "), T("every meeting is documented in the same structured format.")]),
  bullet([B("Accountability: "), T("decisions carry owners and tasks carry status, improving follow-through.")]),
  bullet([B("Inclusivity: "), T("language preservation makes the tool useful for Arabic as well as English meetings.")]),
  bullet([B("Low cost & privacy: "), T("the app runs on free/managed tiers and stores only metadata and results, not raw recordings.")]),
  bullet([B("Engineering quality: "), T("a clean, layered, testable architecture with the AI capability cleanly abstracted.")]),

  h2("8.3 Remaining Limitations"),
  bullet([B("File-size ceiling: "), T("direct client-to-model processing caps practical file size (50 MB), limiting very long recordings.")]),
  bullet([B("No live capture: "), T("the app processes existing recordings/links, not live meetings.")]),
  bullet([B("AI variability: "), T("output quality depends on audio clarity and the model, and may occasionally need correction.")]),
  bullet([B("Security rules / backend: "), T("for production, Firestore security rules and a backend proxy for the AI key should be finalized."), PH(" [State current status.]")]),
  bullet([B("Single-user scope: "), T("no team collaboration or sharing across accounts in the MVP.")]),

  h2("8.4 Lessons Learned"),
  bullet([B("Prompt engineering matters: "), T("a strict schema and explicit language rules are essential to obtain reliable, parseable AI output.")]),
  bullet([B("Abstraction pays off: "), T("hiding the AI behind an interface keeps the door open for a future backend without rewrites.")]),
  bullet([B("Defensive integration: "), T("treating AI and network calls as fallible — with draft/failed states and humanized errors — greatly improves robustness.")]),
  bullet([B("Architecture discipline: "), T("a feature-first clean architecture kept the solo codebase organized and easy to extend.")]),
  bullet([B("Security first: "), T("designing the key-handling strategy early (Firebase AI Logic) avoided a costly redesign later.")]),

  h2("8.5 Comparison: Before vs. After"),
  table([2200, 3577, 3577],
    ["Criterion", "Before (manual)", "After (MeetFlow AI)"],
    [
      ["Minutes creation", "Manual, 30–60 min per meeting", "Automatic, generated in minutes"],
      ["Consistency", "Varies by author", "Uniform structured format"],
      ["Action items", "Scattered or lost", "Trackable task list with status"],
      ["Language support", "English-centric tools", "Preserves meeting language (incl. Arabic)"],
      ["Cost", "Paid tools or manual effort", "Free/managed tiers"],
      ["Data privacy", "Raw recordings on vendor clouds", "Only metadata/results stored"],
    ]),
  pageBreak(),
];

// ============================================================
// CHAPTER 9 — CONCLUSION AND FUTURE WORK
// ============================================================
const ch9 = [
  h1("9. Conclusion and Future Work"),

  h2("9.1 Conclusion"),
  body([T("This project set out to solve a common and costly problem: turning meetings into structured, actionable records. The result, MeetFlow AI, is a cross-platform mobile application that imports meeting audio, video, or links and uses a multimodal large language model to generate summaries, minutes, decisions, participants, follow-ups, and trackable tasks, all persisted securely per user. A working prototype demonstrates the full workflow and meets the four objectives defined at the outset. The project shows that, with modern multimodal AI and managed cloud services, a single developer can deliver a useful, secure, and low-cost intelligent application without a custom backend.")]),

  h2("9.2 Contributions"),
  bullet([B("An end-to-end mobile solution "), T("that converts raw meeting media into structured, trackable documentation.")]),
  bullet([B("A practical integration pattern "), T("for multimodal LLMs in a mobile app — strict JSON prompting, defensive parsing, and language preservation — with the AI key kept off the client via Firebase AI Logic.")]),
  bullet([B("A clean, feature-first reference architecture "), T("in Flutter/Riverpod with the AI capability abstracted for a future backend.")]),
  bullet([B("A privacy-conscious data design "), T("that stores only metadata and results and isolates data per user.")]),

  h2("9.3 Future Work"),
  bullet([B("Backend proxy & security rules: "), T("move the AI call behind a server and finalize Firestore security rules for production.")]),
  bullet([B("Larger / live meetings: "), T("support chunked or streamed processing and, eventually, live transcription.")]),
  bullet([B("Collaboration: "), T("shared meetings, assigning tasks to other users, and team workspaces.")]),
  bullet([B("Calendar & notifications: "), T("integrate with calendars and send reminders for due tasks.")]),
  bullet([B("Editing & export: "), T("let users edit AI output and export to PDF/Docs or task tools.")]),
  bullet([B("Automated tests & analytics: "), T("add unit/integration test suites and usage analytics to measure quality.")]),
  pageBreak(),
];

// ============================================================
// REFERENCES & APPENDICES
// ============================================================
const refs = [
  h1("References"),
  body([PH("List all cited sources in the required citation style (APA, IEEE, or department-approved). Suggested core references to format and include:")]),
  numbered([T("Flutter documentation. Flutter — Build apps for any screen. "), PH("[URL, accessed date]")]),
  numbered([T("Firebase documentation — Authentication, Cloud Firestore, and Firebase AI Logic. "), PH("[URLs, accessed date]")]),
  numbered([T("Google. Gemini API / models documentation. "), PH("[URL, accessed date]")]),
  numbered([T("Riverpod and GoRouter package documentation (pub.dev). "), PH("[URLs, accessed date]")]),
  numbered([PH("[Add 4–6 academic references on automatic summarization, speech recognition, and LLMs.]")]),
  numbered([PH("[Add references for any commercial tools discussed in Chapter 3 (Otter.ai, Fireflies.ai, etc.).]")]),
  pageBreak(),

  h1("Appendices"),
  h2("Appendix A: Additional Diagrams"),
  ...figureBox("Insert any large supporting diagrams (full architecture, detailed ERD, navigation map)."),

  h2("Appendix B: Source Code Samples"),
  body([T("The AI is instructed to return the following JSON structure (abbreviated), which the application parses into its data model:")]),
  new Paragraph({
    spacing: { before: 120, after: 120, line: 240 },
    shading: { type: ShadingType.CLEAR, fill: "F2F2F2" },
    border: { top: cb, bottom: cb, left: cb, right: cb },
    children: [
      new TextRun({ font: "Consolas", size: 18, text: "{" }), new TextRun({ break: 1, font: "Consolas", size: 18, text: "  \"title\": \"\", \"shortSummary\": \"\", \"detailedSummary\": \"\"," }),
      new TextRun({ break: 1, font: "Consolas", size: 18, text: "  \"minutesOfMeeting\": [], \"participants\": [], \"followUps\": []," }),
      new TextRun({ break: 1, font: "Consolas", size: 18, text: "  \"decisions\": [ { \"text\": \"\", \"owner\": \"\" } ]," }),
      new TextRun({ break: 1, font: "Consolas", size: 18, text: "  \"tasks\": [ { \"title\": \"\", \"description\": \"\", \"assignee\": \"\"," }),
      new TextRun({ break: 1, font: "Consolas", size: 18, text: "             \"dueDate\": \"\", \"priority\": \"low|medium|high\"," }),
      new TextRun({ break: 1, font: "Consolas", size: 18, text: "             \"status\": \"pending\" } ]" }),
      new TextRun({ break: 1, font: "Consolas", size: 18, text: "}" }),
    ],
  }),
  body([PH("[Add other important code extracts if required by the supervisor — keep listings short.]")]),

  h2("Appendix C: User Manual / Installation Guide"),
  body([T("Setup and run instructions are provided in Section 6.5. For end users: install the app, register an account, open Import, choose a file or paste a link, set a title, and start processing; the generated summary, decisions, and tasks appear in the meeting details, and action items can be tracked in the Tasks tab.")]),
  body([PH("[Add step-by-step screenshots for end users if required.]")]),

  h2("Appendix D: Additional Test Cases"),
  table([1100, 3254, 2600, 1600, 800],
    ["ID", "Scenario", "Expected Result", "Actual Result", "Status"],
    [
      ["TC-11", "Password reset email", "Reset email sent for a valid account", [PH("[evidence]")], [PH("[ ]")]],
      ["TC-12", "Persisted session after restart", "User remains logged in", [PH("[evidence]")], [PH("[ ]")]],
      ["TC-13", "Import from a valid public text link", "Documentation generated from fetched text", [PH("[evidence]")], [PH("[ ]")]],
      ["TC-14", "Change task priority", "Priority updates and persists", [PH("[evidence]")], [PH("[ ]")]],
      ["TC-15", "Toggle dark mode", "Theme switches and persists", [PH("[evidence]")], [PH("[ ]")]],
    ]),
];

// ============================================================
// ASSEMBLE
// ============================================================
const doc = new Document({
  creator: "Hager Elsayed Darwish",
  title: "MeetFlow AI — Graduation Project",
  styles: {
    default: { document: { run: { font: FONT, size: 24 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, font: FONT, color: "1F3864" },
        paragraph: { spacing: { before: 240, after: 160 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 26, bold: true, font: FONT, color: "2E5496" },
        paragraph: { spacing: { before: 180, after: 120 }, outlineLevel: 1 } },
    ],
  },
  numbering: {
    config: [
      { reference: "bullets", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 600, hanging: 300 } } } }] },
      { reference: "numbers", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 600, hanging: 300 } } } }] },
    ],
  },
  sections: [{
    properties: { page: { size: PAGE, margin: { top: MARGIN, right: MARGIN, bottom: MARGIN, left: MARGIN } } },
    footers: {
      default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [
        new TextRun({ text: "MeetFlow AI — Graduation Project   |   Page ", size: 18, color: "808080" }),
        new TextRun({ children: [PageNumber.CURRENT], size: 18, color: "808080" }),
      ]})] }),
    },
    children: [
      ...coverPage, ...tocSection, ...abstractSection,
      ...ch1, ...ch2, ...ch3, ...ch4, ...ch5, ...ch6, ...ch7, ...ch8, ...ch9,
      ...refs,
    ],
  }],
});

const out = path.join(__dirname, "MeetFlow_AI_Graduation_Project.docx");
Packer.toBuffer(doc).then((buf) => { fs.writeFileSync(out, buf); console.log("Wrote", out, buf.length, "bytes"); });
