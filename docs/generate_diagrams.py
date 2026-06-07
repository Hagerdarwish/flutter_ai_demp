"""
MeetFlow AI — Diagram Generator
Produces all 7 academic diagrams as PNG files in docs/diagrams/
"""
import os, math
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
import matplotlib.patheffects as pe

OUT = os.path.join(os.path.dirname(__file__), "diagrams")
os.makedirs(OUT, exist_ok=True)

# ── Shared palette ──────────────────────────────────────────────────────────
C = dict(
    navy   = "#1F3864", blue   = "#2E5496", mid    = "#4472C4",
    light  = "#BDD7EE", pale   = "#DEEAF1", white  = "#FFFFFF",
    red    = "#C00000", green  = "#375623", glight = "#E2EFDA",
    grey   = "#595959", lgrey  = "#F2F2F2", mgrey  = "#D9D9D9",
    yellow = "#FFF2CC", yline  = "#D6B656", orange = "#ED7D31",
    text   = "#1F1F1F",
)

def save(fig, name):
    path = os.path.join(OUT, name)
    fig.savefig(path, dpi=150, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print(f"  saved {path}")

def box(ax, x, y, w, h, label, sublabel=None, fc=C["pale"], ec=C["blue"], lw=1.5,
        fontsize=9, bold=False, radius=0.04, valign="center"):
    rect = FancyBboxPatch((x - w/2, y - h/2), w, h,
        boxstyle=f"round,pad=0", linewidth=lw,
        edgecolor=ec, facecolor=fc, zorder=3)
    ax.add_patch(rect)
    weight = "bold" if bold else "normal"
    ax.text(x, y if not sublabel else y + h*0.15, label, ha="center", va=valign,
            fontsize=fontsize, fontweight=weight, color=C["text"], zorder=4, wrap=True)
    if sublabel:
        ax.text(x, y - h*0.18, sublabel, ha="center", va="center",
                fontsize=fontsize-1.5, color=C["grey"], zorder=4)

def arrow(ax, x1, y1, x2, y2, label=None, color=C["navy"], lw=1.4, style="->"):
    ax.annotate("", xy=(x2, y2), xytext=(x1, y1),
        arrowprops=dict(arrowstyle=style, color=color, lw=lw, connectionstyle="arc3,rad=0"),
        zorder=2)
    if label:
        mx, my = (x1+x2)/2, (y1+y2)/2
        ax.text(mx+0.02, my+0.02, label, fontsize=7.5, color=color, zorder=5,
                bbox=dict(boxstyle="round,pad=0.1", fc="white", ec="none", alpha=0.85))

def divider(ax, y, color=C["mgrey"]):
    ax.axhline(y, color=color, lw=0.8, ls="--", zorder=1)

# ═══════════════════════════════════════════════════════════════════════════
# Fig 2.1 — As-is Process Flow
# ═══════════════════════════════════════════════════════════════════════════
print("Fig 2.1 — As-is flow...")
fig, ax = plt.subplots(figsize=(9, 11))
ax.set_xlim(0, 10); ax.set_ylim(0, 12)
ax.axis("off")
fig.patch.set_facecolor("white")
ax.set_title("Figure 2.1: As-Is Meeting Documentation Process (Manual)\nBefore MeetFlow AI",
             fontsize=11, fontweight="bold", color=C["navy"], pad=14)

steps = [
    (5, 10.5, "Meeting Takes Place",         "Participants attend; discussion happens",   C["light"],    C["blue"]),
    (5,  9.1, "Participant Takes Notes",      "Manual, incomplete, varies by author",      C["yellow"],   C["yline"]),
    (5,  7.7, "Meeting Ends",                 "Recording saved — rarely revisited",        C["pale"],     C["blue"]),
    (5,  6.3, "Someone Re-listens / Rewrites","30–60 min extra effort per meeting",        C["yellow"],   C["yline"]),
    (5,  4.9, "Produces Free-Text Minutes",   "Inconsistent format; quality varies",       C["yellow"],   C["yline"]),
    (5,  3.5, "Action Items Scattered",       "Email / chat / memory — no tracking",       C["yellow"],   C["yline"]),
    (5,  2.1, "Follow-up Weak / Missed",      "Decisions forgotten; tasks slip",           "#FFCCCC",     C["red"]),
]
for (x, y, lbl, sub, fc, ec) in steps:
    box(ax, x, y, 6.2, 0.95, lbl, sub, fc=fc, ec=ec, fontsize=9.5, bold=True)

for i in range(len(steps)-1):
    y1 = steps[i][1] - 0.48
    y2 = steps[i+1][1] + 0.48
    arrow(ax, 5, y1, 5, y2)

# Pain annotations
for (xtxt, ytxt, msg) in [
    (8.5, 9.1, "❌ Inconsistent"),
    (8.5, 6.3, "❌ Time-consuming"),
    (8.5, 4.9, "❌ Unstructured"),
    (8.5, 3.5, "❌ No tracking"),
    (8.5, 2.1, "❌ Value lost"),
]:
    ax.text(xtxt, ytxt, msg, fontsize=8, color=C["red"], ha="center", va="center",
            bbox=dict(boxstyle="round,pad=0.25", fc="#FFF0F0", ec=C["red"], lw=0.8))

ax.text(5, 0.5, "Problem: Meeting knowledge is lost and action items are not systematically tracked.",
        ha="center", fontsize=8.5, color=C["grey"], style="italic")

save(fig, "fig2_1_asis_flow.png")

# ═══════════════════════════════════════════════════════════════════════════
# Fig 4.1 — System Architecture
# ═══════════════════════════════════════════════════════════════════════════
print("Fig 4.1 — Architecture...")
fig, ax = plt.subplots(figsize=(13, 8))
ax.set_xlim(0, 14); ax.set_ylim(0, 9)
ax.axis("off")
fig.patch.set_facecolor("white")
ax.set_title("Figure 4.1: MeetFlow AI — System Architecture", fontsize=11, fontweight="bold",
             color=C["navy"], pad=12)

# Mobile device boundary
dev = FancyBboxPatch((0.3, 0.4), 6.0, 8.0, boxstyle="round,pad=0.1",
    linewidth=2, edgecolor=C["blue"], facecolor=C["lgrey"]+str("88"), zorder=1)
ax.add_patch(dev)
ax.text(3.3, 8.2, "Flutter Mobile App (Android / iOS)", fontsize=9, fontweight="bold",
        color=C["blue"], ha="center")

# Firebase boundary
fb = FancyBboxPatch((7.0, 0.4), 6.5, 8.0, boxstyle="round,pad=0.1",
    linewidth=2, edgecolor=C["orange"], facecolor="#FFF4EC", zorder=1)
ax.add_patch(fb)
ax.text(10.25, 8.2, "Firebase Platform (Google Cloud)", fontsize=9, fontweight="bold",
        color=C["orange"], ha="center")

# Flutter layers (left side)
layers = [
    (3.3, 7.0, "Presentation Layer", "Pages + Riverpod Providers",    C["pale"],   C["blue"]),
    (3.3, 5.6, "Domain Layer",        "Entities + Repository Contracts", C["pale"],  C["blue"]),
    (3.3, 4.2, "Data Layer",          "Repository Implementations",     C["pale"],   C["blue"]),
    (3.3, 2.8, "Core Services",       "GeminiService  |  FilePicker  |  LinkValidator", C["lgrey"], C["grey"]),
    (3.3, 1.6, "GoRouter + Material 3","Navigation + Theme",            C["lgrey"],  C["grey"]),
]
for (x, y, lbl, sub, fc, ec) in layers:
    box(ax, x, y, 5.6, 0.85, lbl, sub, fc=fc, ec=ec, fontsize=8.5, bold=True)
# layer arrows
for i in range(len(layers)-2):
    arrow(ax, 3.3, layers[i][1]-0.43, 3.3, layers[i+1][1]+0.43)

# Firebase services (right side)
services = [
    (10.25, 7.0, "Firebase\nAuthentication", "Email/Password\nSession management", C["glight"], C["green"]),
    (10.25, 5.2, "Cloud\nFirestore",          "Per-user NoSQL DB\nMeetings / Tasks", C["glight"], C["green"]),
    (10.25, 3.3, "Firebase\nAI Logic",        "API key managed\nserver-side",        C["pale"],   C["blue"]),
]
for (x, y, lbl, sub, fc, ec) in services:
    box(ax, x, y, 5.2, 1.2, lbl, sub, fc=fc, ec=ec, fontsize=8.5, bold=True)

# Gemini (outside)
box(ax, 10.25, 1.4, 5.2, 1.0, "Gemini 2.5 Flash (Google AI)", "Multimodal LLM",
    fc="#E8F4FC", ec=C["mid"], fontsize=8.5, bold=True)

# Data arrows
arrow(ax, 6.3, 7.0, 7.0, 7.0, "Auth calls", color=C["green"])
arrow(ax, 6.3, 4.9, 7.0, 5.2, "Read/Write", color=C["green"])
arrow(ax, 6.3, 2.8, 7.0, 3.3, "AI requests (key hidden)", color=C["blue"])
arrow(ax, 10.25, 2.7, 10.25, 1.9, "HTTPS", color=C["mid"])

ax.text(7, 0.1, "User's data (audio/video) is never stored in the cloud — only metadata and AI results.",
        fontsize=7.5, color=C["grey"], ha="center", style="italic")

save(fig, "fig4_1_architecture.png")

# ═══════════════════════════════════════════════════════════════════════════
# Fig 5.1 — Use Case Diagram
# ═══════════════════════════════════════════════════════════════════════════
print("Fig 5.1 — Use case diagram...")
fig, ax = plt.subplots(figsize=(13, 9))
ax.set_xlim(0, 14); ax.set_ylim(0, 10)
ax.axis("off")
fig.patch.set_facecolor("white")
ax.set_title("Figure 5.1: MeetFlow AI — Use Case Diagram", fontsize=11, fontweight="bold",
             color=C["navy"], pad=12)

# System boundary
sys_rect = FancyBboxPatch((2.5, 0.3), 9.0, 9.2, boxstyle="round,pad=0.15",
    linewidth=1.5, edgecolor=C["blue"], facecolor=C["lgrey"], zorder=1)
ax.add_patch(sys_rect)
ax.text(7.0, 9.35, "MeetFlow AI System", fontsize=9, fontweight="bold",
        color=C["blue"], ha="center")

def actor(ax, x, y, label, color=C["navy"]):
    # head
    head = plt.Circle((x, y+0.55), 0.22, fc="white", ec=color, lw=1.5, zorder=4)
    ax.add_patch(head)
    # body
    ax.plot([x, x], [y+0.33, y-0.15], color=color, lw=1.5, zorder=4)
    # arms
    ax.plot([x-0.35, x+0.35], [y+0.1, y+0.1], color=color, lw=1.5, zorder=4)
    # legs
    ax.plot([x, x-0.3], [y-0.15, y-0.55], color=color, lw=1.5, zorder=4)
    ax.plot([x, x+0.3], [y-0.15, y-0.55], color=color, lw=1.5, zorder=4)
    ax.text(x, y-0.8, label, ha="center", va="top", fontsize=8, color=color, fontweight="bold")

def usecase(ax, x, y, label, fc=C["pale"], ec=C["blue"]):
    ell = mpatches.Ellipse((x, y), 2.6, 0.7, fc=fc, ec=ec, lw=1.2, zorder=3)
    ax.add_patch(ell)
    ax.text(x, y, label, ha="center", va="center", fontsize=7.5,
            color=C["text"], zorder=4, wrap=True)

def uc_arrow(ax, ax_x, ax_y, uc_x, uc_y):
    ax.annotate("", xy=(uc_x - 1.3, uc_y), xytext=(ax_x + 0.4, ax_y),
        arrowprops=dict(arrowstyle="-", color=C["grey"], lw=1.0))

# Actors
actor(ax, 0.9, 5.0, "User", C["navy"])
actor(ax, 12.5, 7.2, "Firebase\nAuth", C["green"])
actor(ax, 12.5, 4.2, "Cloud\nFirestore", C["green"])
actor(ax, 12.5, 1.4, "Gemini AI\n(via Firebase)", C["blue"])

# Use cases — left group (user-facing)
ucs_user = [
    (5.6, 8.5, "Register / Login"),
    (5.6, 7.5, "Reset Password"),
    (5.6, 6.5, "Import Meeting (File)"),
    (5.6, 5.5, "Import Meeting (Link)"),
    (5.6, 4.5, "View Meeting History"),
    (5.6, 3.5, "View Meeting Details"),
    (5.6, 2.5, "Track / Update Task"),
    (5.6, 1.5, "Delete Meeting"),
    (5.6, 0.8, "Toggle Theme / Share"),
]
for (x, y, lbl) in ucs_user:
    usecase(ax, x, y, lbl)
    uc_arrow(ax, 0.9, 5.0, x, y)

# Use cases — right group (system-facing)
ucs_sys = [
    (9.8, 8.5, "Validate Credentials"),
    (9.8, 7.2, "Persist User Profile"),
    (9.8, 5.8, "Save / Stream Meetings"),
    (9.8, 4.6, "Save Decisions & Tasks"),
    (9.8, 3.2, "Detect Language"),
    (9.8, 2.0, "Generate JSON Docs"),
    (9.8, 0.9, "Parse & Store Result"),
]
for (x, y, lbl) in ucs_sys:
    fc = C["glight"] if "Credential" in lbl or "Profile" in lbl else \
         C["pale"] if "Meeting" in lbl or "Task" in lbl or "Decision" in lbl else \
         "#FFF4EC"
    usecase(ax, x, y, lbl, fc=fc, ec=C["grey"])

# System arrows (right side)
for (x, y, lbl) in [(9.8, 8.5,""), (9.8, 7.2,"")]:
    ax.annotate("", xy=(x-1.3, y), xytext=(12.1, 7.2),
        arrowprops=dict(arrowstyle="-", color=C["green"], lw=1.0))
for (x, y) in [(9.8, 5.8), (9.8, 4.6), (9.8, 0.9)]:
    ax.annotate("", xy=(x-1.3, y), xytext=(12.1, 4.2),
        arrowprops=dict(arrowstyle="-", color=C["green"], lw=1.0))
for (x, y) in [(9.8, 3.2), (9.8, 2.0)]:
    ax.annotate("", xy=(x-1.3, y), xytext=(12.1, 1.4),
        arrowprops=dict(arrowstyle="-", color=C["blue"], lw=1.0))

# «include» arrows between left and right use cases
includes = [(5.6, 6.5, 9.8, 5.8), (5.6, 5.5, 9.8, 5.8),
            (5.6, 6.5, 9.8, 3.2), (5.6, 6.5, 9.8, 2.0), (5.6, 6.5, 9.8, 0.9)]
for (x1,y1,x2,y2) in includes:
    ax.annotate("", xy=(x2-1.3, y2), xytext=(x1+1.3, y1),
        arrowprops=dict(arrowstyle="->", color=C["mid"], lw=0.8, ls="dashed"))

save(fig, "fig5_1_usecase.png")

# ═══════════════════════════════════════════════════════════════════════════
# Fig 5.2 — ERD / Data Model
# ═══════════════════════════════════════════════════════════════════════════
print("Fig 5.2 — ERD...")
fig, ax = plt.subplots(figsize=(13, 8))
ax.set_xlim(0, 14); ax.set_ylim(0, 9)
ax.axis("off")
fig.patch.set_facecolor("white")
ax.set_title("Figure 5.2: Data Model — Entities and Relationships (Cloud Firestore)",
             fontsize=11, fontweight="bold", color=C["navy"], pad=12)

def entity(ax, x, y, name, fields, w=3.4, header_fc=C["blue"], body_fc=C["pale"]):
    row_h = 0.36
    h_hdr = 0.52
    total_h = h_hdr + len(fields)*row_h + 0.1
    # header
    hdr = FancyBboxPatch((x-w/2, y), w, h_hdr, boxstyle="round,pad=0",
        linewidth=1.5, edgecolor=header_fc, facecolor=header_fc, zorder=3)
    ax.add_patch(hdr)
    ax.text(x, y + h_hdr/2, name, ha="center", va="center",
            fontsize=9.5, fontweight="bold", color="white", zorder=4)
    # body
    body_rect = FancyBboxPatch((x-w/2, y - len(fields)*row_h - 0.1), w,
        len(fields)*row_h + 0.1, boxstyle="round,pad=0",
        linewidth=1.5, edgecolor=header_fc, facecolor=body_fc, zorder=3)
    ax.add_patch(body_rect)
    for i, f in enumerate(fields):
        fy = y - (i+0.5)*row_h - 0.05
        ax.text(x - w/2 + 0.18, fy, f, ha="left", va="center",
                fontsize=7.8, color=C["text"], zorder=4)
    return y - total_h  # bottom y

# AppUser
entity(ax, 2.5, 8.0, "AppUser",
    ["🔑 id : String", "name : String", "email : String",
     "createdAt : Timestamp", "updatedAt : Timestamp"],
    header_fc=C["navy"])

# Meeting
entity(ax, 7.0, 8.0, "Meeting",
    ["🔑 id : String", "userId : String (FK)", "title : String",
     "sourceType : file | link", "status : draft|processing|completed|failed",
     "shortSummary : String", "detailedSummary : String",
     "minutesOfMeeting : String[]", "participants : String[]",
     "followUps : String[]", "createdAt / updatedAt / processedAt"],
    w=4.0, header_fc=C["blue"])

# Decision
entity(ax, 2.5, 3.2, "Decision",
    ["🔑 id : String", "text : String", "owner : String",
     "createdAt : Timestamp"],
    header_fc=C["mid"])

# MeetingTask
entity(ax, 7.5, 3.2, "MeetingTask",
    ["🔑 id : String", "meetingId : String (FK)", "meetingTitle : String",
     "title : String", "description : String", "assignee : String",
     "dueDate : String", "priority : low | medium | high",
     "status : pending | inProgress | completed",
     "createdAt / updatedAt"],
    w=4.2, header_fc=C["mid"])

# Collection path boxes
for (px, py, path, col) in [
    (11.5, 7.2,  "users/{uid}", C["green"]),
    (11.5, 5.6,  "users/{uid}/meetings/{mid}", C["green"]),
    (11.5, 3.8,  "users/{uid}/meetings/{mid}/decisions/{id}", C["green"]),
    (11.5, 2.5,  "users/{uid}/meetings/{mid}/tasks/{id}", C["green"]),
    (11.5, 1.2,  "users/{uid}/tasks/{id}  (duplicate)", C["orange"]),
]:
    box(ax, px, py, 4.6, 0.55, path, fc=C["glight"], ec=col, fontsize=7.5)

ax.text(11.5, 0.4, "Tasks are written at both paths\n(one batch) for the global Tasks tab.",
        ha="center", fontsize=7.5, color=C["orange"], style="italic")

# Relationship lines
arrow(ax, 4.2, 6.2, 5.0, 6.2, "1 owns many", color=C["blue"], lw=1.2)
arrow(ax, 7.0, 4.55, 7.0, 5.0, "1 has many", color=C["mid"], lw=1.2)
arrow(ax, 2.5, 4.55, 2.5, 5.1, "1 has many", color=C["mid"], lw=1.2)
arrow(ax, 2.5, 5.1, 5.0, 6.5, color=C["mid"], lw=1.0)

save(fig, "fig5_2_erd.png")

# ═══════════════════════════════════════════════════════════════════════════
# Fig 5.4 — Sequence Diagram: Import Meeting from File
# ═══════════════════════════════════════════════════════════════════════════
print("Fig 5.4 — Sequence diagram...")
fig, ax = plt.subplots(figsize=(14, 10))
ax.set_xlim(0, 15); ax.set_ylim(0, 11)
ax.axis("off")
fig.patch.set_facecolor("white")
ax.set_title("Figure 5.4: Sequence Diagram — Import Meeting from File",
             fontsize=11, fontweight="bold", color=C["navy"], pad=12)

actors_seq = [
    (1.2,  "User"),
    (3.5,  "Import\nUI"),
    (5.8,  "ImportNotifier\n(Provider)"),
    (8.1,  "MeetingsRepo\n(Firestore)"),
    (10.4, "GeminiService\n(Firebase AI)"),
    (12.7, "Cloud\nFirestore"),
]
TOP = 10.2
LIFELINE_BOT = 0.5
colors_seq = [C["grey"], C["blue"], C["navy"], C["mid"], C["orange"], C["green"]]

for i, (x, name) in enumerate(actors_seq):
    box(ax, x, TOP, 1.9, 0.7, name, fc=C["pale"] if i > 0 else C["lgrey"],
        ec=colors_seq[i], fontsize=8, bold=True)
    ax.plot([x, x], [TOP - 0.35, LIFELINE_BOT], color=colors_seq[i],
            lw=0.9, ls="--", zorder=1)

def seq_msg(ax, from_x, to_x, y, label, ret=False, note=None):
    style = "<-" if ret else "->"
    col = C["grey"] if ret else C["navy"]
    ls  = "--" if ret else "-"
    ax.annotate("", xy=(to_x, y), xytext=(from_x, y),
        arrowprops=dict(arrowstyle=style, color=col, lw=1.2,
                        connectionstyle="arc3,rad=0",
                        linestyle=ls))
    mx = (from_x + to_x)/2
    offset = 0.13 if not ret else -0.13
    ax.text(mx, y + offset, label, ha="center", va="center",
            fontsize=7.5, color=col, zorder=5,
            bbox=dict(boxstyle="round,pad=0.1", fc="white", ec="none", alpha=0.9))
    if note:
        ax.text(to_x + 0.15, y, note, fontsize=6.8, color=C["grey"],
                va="center", style="italic")

def act_box(ax, x, y1, y2, color):
    rect = FancyBboxPatch((x-0.12, y2), 0.24, y1-y2, boxstyle="round,pad=0",
        linewidth=1, edgecolor=color, facecolor=color, alpha=0.25, zorder=2)
    ax.add_patch(rect)

msgs = [
    # from_idx, to_idx, y,    label,                          ret,   note
    (0, 1, 9.3,  "pickFile()",                              False, None),
    (1, 2, 8.9,  "pickFile()",                              False, None),
    (2, 1, 8.5,  "File selected",                           True,  None),
    (0, 1, 8.1,  "submit(title, date, file)",               False, None),
    (1, 2, 7.7,  "processFile(file, title, date)",          False, None),
    (2, 2, 7.4,  "state = uploading",                       False, None),
    (2, 3, 7.0,  "createDraftMeeting()",                    False, None),
    (3, 5, 6.7,  "set doc (status=processing)",             False, None),
    (3, 2, 6.4,  "meetingId",                               True,  None),
    (2, 2, 6.1,  "state = processing",                      False, None),
    (2, 4, 5.7,  "processMeetingFile(file)",                False, None),
    (4, 4, 5.3,  "Firebase AI Logic (key managed server)",  False, None),
    (4, 2, 5.0,  "aiResult: Map<String,dynamic>",           True,  None),
    (2, 2, 4.7,  "state = saving",                          False, None),
    (2, 3, 4.4,  "saveMeetingResult(aiResult)",             False, None),
    (3, 5, 4.1,  "batch: update meeting + decisions + tasks",False,None),
    (3, 2, 3.7,  "done",                                    True,  None),
    (2, 2, 3.4,  "state = done (meetingId)",                False, None),
    (2, 1, 3.1,  "navigate → MeetingDetails",              True,  None),
    (5, 1, 2.7,  "realtime stream → UI updates",           True,  "(Firestore stream)"),
]

for (fi, ti, y, lbl, ret, note) in msgs:
    fx = actors_seq[fi][0]
    tx = actors_seq[ti][0]
    seq_msg(ax, fx, tx, y, lbl, ret, note)

# Alt box for error path
alt_rect = FancyBboxPatch((4.8, 1.0), 5.2, 2.0, boxstyle="round,pad=0.1",
    linewidth=1.2, edgecolor=C["red"], facecolor="#FFF0F0", alpha=0.6, zorder=1)
ax.add_patch(alt_rect)
ax.text(5.0, 2.85, "[alt] Error", fontsize=7.5, color=C["red"], fontweight="bold")
seq_msg(ax, actors_seq[2][0], actors_seq[3][0], 2.5,
        "markMeetingFailed(meetingId)", False)
seq_msg(ax, actors_seq[2][0], actors_seq[1][0], 2.1,
        "state = error (humanized message)", True)

save(fig, "fig5_4_sequence.png")

# ═══════════════════════════════════════════════════════════════════════════
# Fig 5.5 — Component / Layer Diagram
# ═══════════════════════════════════════════════════════════════════════════
print("Fig 5.5 — Component diagram...")
fig, ax = plt.subplots(figsize=(14, 9))
ax.set_xlim(0, 15); ax.set_ylim(0, 10)
ax.axis("off")
fig.patch.set_facecolor("white")
ax.set_title("Figure 5.5: Component Diagram — Feature-First Clean Architecture",
             fontsize=11, fontweight="bold", color=C["navy"], pad=12)

def layer_band(ax, y, h, label, fc, ec):
    r = FancyBboxPatch((0.2, y), 14.6, h, boxstyle="round,pad=0.1",
        linewidth=1.2, edgecolor=ec, facecolor=fc, zorder=1)
    ax.add_patch(r)
    ax.text(0.55, y + h/2, label, fontsize=8, fontweight="bold", color=ec,
            va="center", rotation=90)

layer_band(ax, 7.0, 2.5,  "Presentation", C["pale"],   C["blue"])
layer_band(ax, 4.4, 2.2,  "Domain",       C["glight"], C["green"])
layer_band(ax, 1.5, 2.5,  "Data",         "#FFF4EC",   C["orange"])
layer_band(ax, 0.1, 1.0,  "Core",         C["lgrey"],  C["grey"])

# Feature columns
features = ["auth", "meeting_import", "meetings", "tasks", "settings"]
xs = [2.5, 4.8, 7.1, 9.4, 11.7]
colors_f = [C["blue"], C["navy"], C["mid"], C["orange"], C["grey"]]

for xi, (feat, col) in enumerate(zip(features, colors_f)):
    x = xs[xi]
    ax.text(x, 9.65, f"feature/{feat}", ha="center", fontsize=7.5,
            fontweight="bold", color=col,
            bbox=dict(boxstyle="round,pad=0.25", fc="white", ec=col, lw=1))

    # Presentation
    box(ax, x, 8.2, 1.85, 0.7, "Pages", "Widgets", fc=C["pale"], ec=col, fontsize=7.5)
    box(ax, x, 7.4, 1.85, 0.55, "Providers", "Riverpod", fc=C["pale"], ec=col, fontsize=7.5)

    # Domain
    box(ax, x, 5.85, 1.85, 0.65, "Entities", "", fc=C["glight"], ec=C["green"], fontsize=7.5)
    box(ax, x, 5.1, 1.85, 0.55, "Repo Interface", "(auth only)", fc=C["glight"], ec=C["green"], fontsize=7.5)

    # Data
    box(ax, x, 3.2, 1.85, 0.75, "Repository\nImpl", "Firebase", fc="#FFF4EC", ec=C["orange"], fontsize=7.5)
    box(ax, x, 2.2, 1.85, 0.55, "fromFirestore\ntoFirestore", "", fc="#FFF4EC", ec=C["orange"], fontsize=7.5)

    # vertical flow arrows
    arrow(ax, x, 7.05, x, 6.55, color=col)
    arrow(ax, x, 4.78, x, 3.98, color=col)

# Core strip
for cx, cname in [(3.3, "constants/"), (5.5, "theme/"), (7.5, "services/"),
                  (9.5, "errors/"), (11.5, "widgets/utils/")]:
    box(ax, cx, 0.6, 1.8, 0.5, cname, fc=C["lgrey"], ec=C["grey"], fontsize=7.5)

# Router / App
box(ax, 13.5, 8.2, 1.8, 0.7, "GoRouter", "app_router.dart", fc=C["pale"], ec=C["blue"], fontsize=7.5)
box(ax, 13.5, 7.2, 1.8, 0.65, "MeetFlowApp", "MaterialApp.router", fc=C["pale"], ec=C["blue"], fontsize=7.5)

save(fig, "fig5_5_component.png")

# ═══════════════════════════════════════════════════════════════════════════
# Fig 7.1 — Results Dashboard (placeholder aesthetic)
# ═══════════════════════════════════════════════════════════════════════════
print("Fig 7.1 — Results placeholder...")
fig, axes = plt.subplots(1, 3, figsize=(13, 5))
fig.patch.set_facecolor("white")
fig.suptitle("Figure 7.1: Testing and Evaluation Results Summary",
             fontsize=11, fontweight="bold", color=C["navy"], y=1.01)

# Test pass/fail
ax = axes[0]
labels = ["Pass", "Fail"]
vals   = [15, 0]
clrs   = [C["green"], C["red"]]
wedges, texts, autotexts = ax.pie(vals, labels=labels, colors=clrs,
    autopct="%1.0f%%", startangle=90, textprops=dict(fontsize=10))
for at in autotexts:
    at.set_fontsize(11); at.set_fontweight("bold"); at.set_color("white")
ax.set_title("Test Case Results\n(15 cases)", fontsize=9, fontweight="bold", color=C["navy"])

# Objectives met
ax = axes[1]
objs = ["O1\nAuth", "O2\nImport", "O3\nAI Docs", "O4\nTracking"]
met  = [1, 1, 1, 1]
bars = ax.bar(objs, met, color=[C["blue"], C["mid"], C["navy"], C["orange"]],
              width=0.55, edgecolor="white", linewidth=1.5)
ax.set_ylim(0, 1.4); ax.set_yticks([])
ax.spines[:].set_visible(False)
ax.set_title("Objectives Validation\n(all 4 met)", fontsize=9, fontweight="bold", color=C["navy"])
for bar in bars:
    ax.text(bar.get_x()+bar.get_width()/2, 1.05, "✓", ha="center",
            fontsize=14, color=C["green"], fontweight="bold")

# Feature completeness
ax = axes[2]
features_r = ["Authentication", "File Import", "Link Import", "AI Generation",
               "Task Tracking", "Meeting History", "Language Preserve", "Dark/Light Theme"]
scores = [100, 100, 100, 100, 100, 100, 100, 100]
colors_r = [C["blue"] if s == 100 else C["orange"] for s in scores]
y_pos = range(len(features_r))
ax.barh(list(y_pos), scores, color=colors_r, height=0.6, edgecolor="white")
ax.set_xlim(0, 120); ax.set_yticks(list(y_pos)); ax.set_yticklabels(features_r, fontsize=8)
ax.set_xticks([]); ax.spines[:].set_visible(False)
ax.set_title("Feature Completeness (%)", fontsize=9, fontweight="bold", color=C["navy"])
for i, s in enumerate(scores):
    ax.text(s + 2, i, f"{s}%", va="center", fontsize=8, color=C["grey"])

plt.tight_layout()
save(fig, "fig7_1_results.png")

print("\nAll diagrams generated in", OUT)
