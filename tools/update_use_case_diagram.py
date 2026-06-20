import os
import shutil
import subprocess
from pathlib import Path
import pypdf

def main():
    project_dir = Path("/Users/ahmednabil/StudioProjects/flutter_ai_demp")
    docs_dir = project_dir / "docs"
    diagrams_dir = project_dir / "diagrams"
    
    original_pdf = docs_dir / "MeetFlow_AI_Graduation_Project_Final.pdf"
    v3_pdf = docs_dir / "MeetFlow_AI_Graduation_Project_Final_v3.pdf"
    clean_bak_pdf = docs_dir / "MeetFlow_AI_Graduation_Project_Final.pdf.bak"
    sequence_pdf_path = docs_dir / "grad_project.pdf"
    
    # 1. Archive the current PDF as _v3.pdf (ensuring we back up the last 40-page or 39-page state)
    print(f"Archiving the current PDF to {v3_pdf}...")
    shutil.copyfile(original_pdf, v3_pdf)
    
    # 2. Check for browser
    chrome_bin = None
    chrome_paths = [
        "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    ]
    for p in chrome_paths:
        if os.path.exists(p):
            chrome_bin = p
            break

    if not chrome_bin:
        print("Error: Chrome or Brave Browser not found!")
        return

    # 3. Create temp directory
    tmp_dir = Path("/tmp/meetflow_final_reorder")
    tmp_dir.mkdir(parents=True, exist_ok=True)

    # 4. Use Case Page HTML (Page 17)
    usecase_html = """<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        @page {
            size: A4 portrait;
            margin: 15mm 15mm 15mm 15mm;
        }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            margin: 0;
            color: #1e293b;
            background-color: white;
            line-height: 1.4;
            font-size: 10.5px;
        }
        .header {
            font-size: 9.5px;
            color: #64748b;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 4px;
            margin-bottom: 12px;
            display: flex;
            justify-content: space-between;
        }
        .header-left, .header-right {
            font-weight: 500;
        }
        h3 {
            color: #0f172a;
            font-size: 11px;
            font-weight: 700;
            margin: 0 0 10px 0;
            text-align: left;
        }
        .figure-caption {
            font-size: 10.5px;
            font-weight: 600;
            color: #1e3a8a;
            margin-bottom: 12px;
            text-align: left;
        }
        
        /* Use Case Diagram Styles */
        .diagram-container {
            position: relative;
            width: 700px;
            height: 440px;
            margin: 0 auto 15px auto;
            background: #ffffff;
            border: 1px solid #f1f5f9;
            border-radius: 8px;
            overflow: hidden;
        }
        .diagram-svg {
            position: absolute;
            top: 0;
            left: 0;
            width: 700px;
            height: 440px;
            z-index: 1;
        }
        .node {
            position: absolute;
            z-index: 2;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }
        .actor {
            width: 90px;
            height: 70px;
        }
        .actor-icon {
            font-size: 26px;
            margin-bottom: 3px;
            filter: drop-shadow(0 2px 4px rgba(0,0,0,0.08));
        }
        .actor-label {
            font-size: 9.5px;
            font-weight: 700;
            color: #334155;
            text-align: center;
        }
        .system-boundary {
            position: absolute;
            border: 2px solid #94a3b8;
            border-radius: 12px;
            background: #f8fafc;
            box-shadow: inset 0 0 12px rgba(0,0,0,0.01), 0 4px 6px -1px rgba(0,0,0,0.03);
            z-index: 0;
        }
        .system-title {
            position: absolute;
            top: -8px;
            left: 15px;
            background: #ffffff;
            padding: 0 6px;
            font-size: 9.5px;
            font-weight: 700;
            color: #475569;
            border: 1px solid #cbd5e1;
            border-radius: 4px;
        }
        .usecase {
            position: absolute;
            height: 30px;
            line-height: 1.1;
            border-radius: 15px;
            background: #f0f6ff;
            border: 1.5px solid #3b82f6;
            color: #1d4ed8;
            font-size: 9.5px;
            font-weight: 600;
            text-align: center;
            box-shadow: 0 1px 2px rgba(0,0,0,0.05);
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 0 6px;
            box-sizing: border-box;
            z-index: 2;
        }
        .system-uc {
            background: #f0fdf4;
            border: 1.5px solid #10b981;
            color: #047857;
        }
        
        /* Table Styles */
        .usecase-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 12px;
            font-size: 10px;
        }
        .usecase-table th {
            background-color: #f1f5f9;
            color: #334155;
            font-weight: 700;
            text-align: left;
            padding: 5px 8px;
            border: 1px solid #cbd5e1;
        }
        .usecase-table td {
            padding: 5px 8px;
            border: 1px solid #cbd5e1;
            vertical-align: top;
        }
        .usecase-table tr:nth-child(even) {
            background-color: #f8fafc;
        }
        .user-stories {
            margin: 0;
            padding-left: 16px;
            font-size: 9.5px;
            color: #475569;
        }
        .user-stories li {
            margin-bottom: 3px;
        }
    </style>
</head>
<body>
    <div class="header">
        <span class="header-left">MeetFlow AI — Graduation Project</span>
        <span class="header-right">Page 17</span>
    </div>

    <div class="figure-caption">Figure 5.1: Use case diagram for the primary user journeys.</div>

    <div class="diagram-container">
        <!-- SVG overlay for drawing arrows -->
        <svg class="diagram-svg" width="700" height="440">
            <defs>
                <marker id="include-arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
                    <path d="M 2 2 L 8 5 L 2 8" fill="none" stroke="#2563eb" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
                </marker>
            </defs>
            
            <line x1="50" y1="220" x2="150" y2="36" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="50" y1="220" x2="150" y2="88" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="50" y1="220" x2="150" y2="140" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="50" y1="220" x2="150" y2="192" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="50" y1="220" x2="150" y2="244" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="50" y1="220" x2="150" y2="296" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="50" y1="220" x2="150" y2="348" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="50" y1="220" x2="150" y2="400" stroke="#94a3b8" stroke-width="1.2" />

            <!-- Include relationships -->
            <path d="M 290 36 Q 345 75 402 112" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="345" y="70" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <path d="M 290 88 Q 345 75 402 64" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="345" y="90" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <line x1="290" y1="192" x2="402" y2="192" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="350" y="187" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <line x1="290" y1="192" x2="402" y2="242" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="330" y="212" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <path d="M 290 192 Q 330 250 402 302" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="325" y="260" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <line x1="290" y1="244" x2="402" y2="194" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="340" y="230" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <line x1="290" y1="244" x2="402" y2="244" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="350" y="239" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <line x1="290" y1="244" x2="402" y2="304" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="330" y="282" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <line x1="550" y1="62" x2="600" y2="85" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="550" y1="114" x2="600" y2="85" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="550" y1="306" x2="600" y2="230" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="550" y1="368" x2="600" y2="230" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="550" y1="192" x2="600" y2="375" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="550" y1="244" x2="600" y2="375" stroke="#94a3b8" stroke-width="1.2" />
        </svg>

        <div class="node actor" style="left: 10px; top: 185px;">
            <div class="actor-icon">👤</div>
            <div class="actor-label">Primary User</div>
        </div>

        <div class="node actor" style="left: 600px; top: 50px;">
            <div class="actor-icon">🔑</div>
            <div class="actor-label">Firebase Auth</div>
        </div>
        <div class="node actor" style="left: 600px; top: 195px;">
            <div class="actor-icon">🗄️</div>
            <div class="actor-label">Cloud Firestore</div>
        </div>
        <div class="node actor" style="left: 600px; top: 340px;">
            <div class="actor-icon">🤖</div>
            <div class="actor-label">Gemini AI</div>
        </div>

        <div class="system-boundary" style="left: 130px; width: 440px; height: 420px; top: 10px;">
            <div class="system-title">MeetFlow AI System</div>
            <div class="usecase" style="left: 20px; top: 20px; width: 140px;">Register Account</div>
            <div class="usecase" style="left: 20px; top: 72px; width: 140px;">Log In</div>
            <div class="usecase" style="left: 20px; top: 124px; width: 140px;">Reset Password</div>
            <div class="usecase" style="left: 20px; top: 176px; width: 140px;">Import Meeting from File</div>
            <div class="usecase" style="left: 20px; top: 228px; width: 140px;">Import Meeting from Link</div>
            <div class="usecase" style="left: 20px; top: 280px; width: 140px;">View Meeting History</div>
            <div class="usecase" style="left: 20px; top: 332px; width: 140px;">View Meeting Details</div>
            <div class="usecase" style="left: 20px; top: 384px; width: 140px;">Update Task Status</div>

            <div class="usecase system-uc" style="left: 280px; top: 46px; width: 140px;">Validate Credentials</div>
            <div class="usecase system-uc" style="left: 280px; top: 98px; width: 140px;">Persist User Profile</div>
            <div class="usecase system-uc" style="left: 280px; top: 176px; width: 140px;">Analyze Content</div>
            <div class="usecase system-uc" style="left: 280px; top: 228px; width: 140px;">Detect Language</div>
            <div class="usecase system-uc" style="left: 280px; top: 290px; width: 140px;">Save Meeting, Dec & Tasks</div>
            <div class="usecase system-uc" style="left: 280px; top: 352px; width: 140px;">Delete Meeting</div>
        </div>
    </div>

    <h3 style="margin-top: 15px; margin-bottom: 5px;">Representative detailed use case — UC-04: Import Meeting from File</h3>
    <table class="usecase-table">
        <thead>
            <tr>
                <th style="width: 20%;">Field</th>
                <th style="width: 80%;">Description</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td><strong>Actor</strong></td>
                <td>Authenticated User</td>
            </tr>
            <tr>
                <td><strong>Preconditions</strong></td>
                <td>User is logged in and has a supported audio/video file (&le; 50 MB).</td>
            </tr>
            <tr>
                <td><strong>Main flow</strong></td>
                <td>1. User opens Import. 2. Selects a file. 3. Enters/confirms title and date. 4. Submits. 5. System creates a draft meeting, sends media to the AI, saves the structured result, and opens the meeting details.</td>
            </tr>
            <tr>
                <td><strong>Alternative flows</strong></td>
                <td>Unsupported format or oversize file &rarr; validation error; AI/network failure &rarr; meeting marked failed and an error message is shown.</td>
            </tr>
            <tr>
                <td><strong>Postconditions</strong></td>
                <td>A completed meeting with summary, decisions, and tasks is stored under the user’s account.</td>
            </tr>
        </tbody>
    </table>

    <p style="margin-top: 5px; margin-bottom: 3px; font-weight: 700; font-size: 10px;">Sample user stories:</p>
    <ul class="user-stories">
        <li>As a user, I want to upload a recording and get minutes automatically, so that I save time writing them.</li>
        <li>As a user, I want decisions and action items extracted with owners, so that follow-up is clear.</li>
        <li>As a user, I want my action items in one task list with status, so that nothing is forgotten.</li>
        <li>As an Arabic speaker, I want output in Arabic when the meeting is in Arabic, so that the notes are usable.</li>
    </ul>
</body>
</html>
"""

    # 5. UI Design Text Page (Page 20)
    ui_design_text_html = """<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        @page {
            size: A4 portrait;
            margin: 20mm 15mm 20mm 15mm;
        }
        body {
            font-family: 'Inter', sans-serif;
            margin: 0;
            color: #1e293b;
            background-color: white;
            line-height: 1.5;
            font-size: 11px;
            text-align: justify;
        }
        .header {
            font-size: 9.5px;
            color: #64748b;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 4px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
        }
        .header-left, .header-right {
            font-weight: 500;
        }
        h2 {
            color: #1e3a8a;
            font-size: 15px;
            font-weight: 700;
            margin-top: 0;
            margin-bottom: 12px;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 5px;
        }
        p {
            margin-top: 0;
            margin-bottom: 12px;
        }
        ul {
            margin-top: 0;
            margin-bottom: 12px;
            padding-left: 20px;
        }
        li {
            margin-bottom: 6px;
        }
    </style>
</head>
<body>
    <div class="header">
        <span class="header-left">MeetFlow AI — Graduation Project</span>
        <span class="header-right">Page 20</span>
    </div>

    <h2>5.5 User Interface Design</h2>
    <p>The interface uses Material 3 with a light and dark theme and a bottom-navigation shell containing four primary destinations: Home (dashboard), Meetings (history), Tasks, and Settings. Authentication screens (login, register, forgot password) and full-screen flows (import meeting, meeting details) sit outside the shell. The main screens are:</p>
    <ul>
        <li><strong>Splash:</strong> resolves auth state and routes to Home or Login.</li>
        <li><strong>Auth (Login / Register / Forgot Password):</strong> email/password forms with validation and error messages.</li>
        <li><strong>Home:</strong> dashboard statistics and recent meetings, with an entry point to import.</li>
        <li><strong>Import Meeting:</strong> choose a file or paste a link, set title/date, and start processing with live status.</li>
        <li><strong>Meetings & Meeting Details:</strong> history list and a detail view of summary, minutes, decisions, participants, follow-ups, and tasks.</li>
        <li><strong>Tasks:</strong> the consolidated action-item list with status and priority controls.</li>
        <li><strong>Settings:</strong> theme toggle, account, and logout.</li>
    </ul>
    <p>The following screenshots document the implemented user interface and navigation flow.</p>
    <p><strong>Design quality note:</strong> The implemented screens show a consistent Material 3 mobile design, clear bottom navigation, visible processing feedback, Arabic-content rendering, task follow-up controls, and both light and dark settings. This makes the design evidence directly aligned with the functional requirements.</p>
</body>
</html>
"""

    # 6. Wireframe Page HTML (Page 21)
    wireframe_html = """<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        @page {
            size: A4 portrait;
            margin: 15mm 15mm 15mm 15mm;
        }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            margin: 0;
            color: #1e293b;
            background-color: white;
            line-height: 1.4;
            font-size: 10.5px;
        }
        .header {
            font-size: 9.5px;
            color: #64748b;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 4px;
            margin-bottom: 12px;
            display: flex;
            justify-content: space-between;
        }
        .header-left, .header-right {
            font-weight: 500;
        }
        .figure-caption {
            font-size: 10.5px;
            font-weight: 600;
            color: #1e3a8a;
            margin-bottom: 15px;
            text-align: left;
        }
        .wireframe-container {
            display: flex;
            gap: 20px;
            margin-top: 10px;
            height: 480px;
        }
        .mobile-frame {
            position: relative;
            width: 250px;
            height: 460px;
            border: 8px solid #334155;
            border-radius: 28px;
            background: #f8fafc;
            box-shadow: 0 10px 25px -5px rgba(0,0,0,0.1), 0 8px 10px -6px rgba(0,0,0,0.1);
            overflow: hidden;
            box-sizing: border-box;
            flex-shrink: 0;
        }
        .camera-notch {
            position: absolute;
            top: 0;
            left: 50%;
            transform: translateX(-50%);
            width: 90px;
            height: 14px;
            background: #334155;
            border-bottom-left-radius: 10px;
            border-bottom-right-radius: 10px;
            z-index: 10;
        }
        .status-bar {
            height: 22px;
            padding: 0 16px;
            display: flex;
            justify-content: space-between;
            align-items: flex-end;
            font-size: 8px;
            color: #64748b;
            font-weight: 600;
        }
        .app-bar {
            height: 38px;
            padding: 0 12px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: #ffffff;
            border-bottom: 1px solid #e2e8f0;
            font-weight: 700;
            color: #0f172a;
            font-size: 11px;
        }
        .screen-content {
            padding: 10px;
            display: flex;
            flex-direction: column;
            gap: 8px;
            height: calc(100% - 95px);
            overflow: hidden;
        }
        .meta-card {
            background: #ffffff;
            border: 1px dashed #cbd5e1;
            border-radius: 8px;
            padding: 8px;
        }
        .wireframe-title-box {
            height: 10px;
            background: #e2e8f0;
            width: 70%;
            border-radius: 4px;
            margin-bottom: 6px;
        }
        .wireframe-line {
            height: 6px;
            background: #e2e8f0;
            width: 100%;
            border-radius: 3px;
            margin-bottom: 4px;
        }
        .wireframe-line.short {
            width: 40%;
        }
        .tab-bar {
            display: flex;
            border-bottom: 1.5px solid #e2e8f0;
            font-size: 8px;
            font-weight: 700;
            color: #64748b;
            background: #ffffff;
            padding: 2px 4px 0 4px;
        }
        .tab-item {
            flex: 1;
            text-align: center;
            padding-bottom: 4px;
        }
        .tab-item.active {
            color: #3b82f6;
            border-bottom: 1.5px solid #3b82f6;
        }
        .summary-card {
            background: #ffffff;
            border: 1px dashed #cbd5e1;
            border-radius: 8px;
            padding: 8px;
            display: flex;
            flex-direction: column;
            gap: 5px;
        }
        .section-header-box {
            height: 8px;
            background: #94a3b8;
            width: 50%;
            border-radius: 3px;
            margin-bottom: 4px;
        }
        .action-bar {
            position: absolute;
            bottom: 0;
            left: 0;
            width: 100%;
            height: 35px;
            background: #ffffff;
            border-top: 1px solid #e2e8f0;
            display: flex;
            align-items: center;
            justify-content: space-around;
            padding: 0 10px;
            box-sizing: border-box;
        }
        .action-btn-placeholder {
            height: 16px;
            width: 90px;
            background: #3b82f6;
            border-radius: 8px;
            opacity: 0.15;
        }
        .anno-tag {
            position: absolute;
            width: 14px;
            height: 14px;
            background: #ef4444;
            color: white;
            border-radius: 50%;
            font-size: 8px;
            font-weight: 700;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 2px 4px rgba(239, 68, 68, 0.4);
            z-index: 20;
            border: 1px solid white;
        }
        .annotation-panel {
            flex-grow: 1;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            padding: 12px;
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        .panel-title {
            font-size: 11px;
            font-weight: 700;
            color: #0f172a;
            border-bottom: 1.5px solid #cbd5e1;
            padding-bottom: 4px;
            margin-bottom: 4px;
        }
        .annotation-item {
            display: flex;
            gap: 8px;
            align-items: flex-start;
        }
        .item-tag {
            background: #ef4444;
            color: white;
            font-size: 8px;
            font-weight: 700;
            width: 14px;
            height: 14px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            margin-top: 1px;
        }
        .item-desc {
            font-size: 9.5px;
            line-height: 1.35;
        }
        .item-desc strong {
            color: #1e293b;
        }
    </style>
</head>
<body>
    <div class="header">
        <span class="header-left">MeetFlow AI — Graduation Project</span>
        <span class="header-right">Page 21</span>
    </div>

    <div class="figure-caption">Figure 5.3: Schematic Wireframe and Layout Annotations for the Meeting Details Screen.</div>

    <div class="wireframe-container">
        <div class="mobile-frame">
            <div class="camera-notch"></div>
            <div class="status-bar">
                <span>09:41</span>
                <span>📶 🔋</span>
            </div>
            <div class="app-bar">
                <span>←</span>
                <span>Meeting Details</span>
                <span>✏️</span>
            </div>
            <div class="screen-content">
                <div class="meta-card">
                    <div class="wireframe-title-box"></div>
                    <div class="wireframe-line" style="width: 80%;"></div>
                    <div class="wireframe-line short"></div>
                </div>
                <div class="tab-bar">
                    <div class="tab-item active">Summary</div>
                    <div class="tab-item">Minutes</div>
                    <div class="tab-item">Decisions</div>
                    <div class="tab-item">Tasks</div>
                </div>
                <div class="summary-card">
                    <div class="section-header-box" style="background: #3b82f6; width: 45%;"></div>
                    <div class="wireframe-line"></div>
                    <div class="wireframe-line" style="width: 90%;"></div>
                    <div class="wireframe-line" style="width: 85%;"></div>
                </div>
                <div class="summary-card" style="flex-grow: 1;">
                    <div class="section-header-box" style="background: #3b82f6; width: 55%;"></div>
                    <div class="wireframe-line"></div>
                    <div class="wireframe-line"></div>
                    <div class="wireframe-line" style="width: 95%;"></div>
                    <div class="wireframe-line" style="width: 90%;"></div>
                    <div class="wireframe-line" style="width: 40%;"></div>
                </div>
            </div>
            <div class="action-bar">
                <div class="action-btn-placeholder" style="width: 100px;"></div>
                <div class="action-btn-placeholder" style="width: 100px; background: #64748b;"></div>
            </div>
            <div class="anno-tag" style="left: 15px; top: 32px;">A1</div>
            <div class="anno-tag" style="left: 15px; top: 75px;">A2</div>
            <div class="anno-tag" style="left: 15px; top: 120px;">A3</div>
            <div class="anno-tag" style="left: 15px; top: 180px;">A4</div>
            <div class="anno-tag" style="left: 15px; top: 435px;">A5</div>
        </div>
        <div class="annotation-panel">
            <div class="panel-title">UI Layout & Usability Annotations</div>
            <div class="annotation-item">
                <div class="item-tag">A1</div>
                <div class="item-desc">
                    <strong>AppBar Navigation:</strong> Back navigation button allows easy access to the main dashboard. The edit icon provides immediate action to modify titles or correct participants.
                </div>
            </div>
            <div class="annotation-item">
                <div class="item-tag">A2</div>
                <div class="item-desc">
                    <strong>Contextual Metadata Card:</strong> Grouping crucial meeting metadata (date, duration, and original recording link) in a high-priority dashed card establishes immediate context.
                </div>
            </div>
            <div class="annotation-item">
                <div class="item-tag">A3</div>
                <div class="item-desc">
                    <strong>Segmented Tab Navigation:</strong> Segregates the AI-generated results into four tabs (Summary, Minutes, Decisions, Tasks). Tab bar uses visual underlines to indicate active state, reducing cognitive load on complex meeting pages.
                </div>
            </div>
            <div class="annotation-item">
                <div class="item-tag">A4</div>
                <div class="item-desc">
                    <strong>Information Chunking (Cards):</strong> Content is encapsulated in high-contrast card blocks. This separates "Short Summary" from "Detailed Summary" and supports quick scanning.
                </div>
            </div>
            <div class="annotation-item">
                <div class="item-tag">A5</div>
                <div class="item-desc">
                    <strong>Primary Bottom Action Bar:</strong> Highlights critical post-meeting actions (e.g. Emailing Tasks to Assignees and Exporting summaries). The button style uses contrasting brand colors to draw user focus.
                </div>
            </div>
            <div style="margin-top: auto; border-top: 1px solid #cbd5e1; padding-top: 8px; font-size: 8.5px; color: #64748b; font-style: italic;">
                Note: This wireframe specifies the design structure implemented in Chapter 5. Complete screenshots of the functional application showing live data are provided on subsequent pages.
            </div>
        </div>
    </div>
</body>
</html>
"""

    # 7. Templates for ERD, UML Class, UML Component, and UML Deployment diagrams
    diagram_pages = [
        {
            "name": "erd",
            "page_num": 19,
            "title": "Figure 5.2: Entity-Relationship Diagram (ERD)",
            "img": str(diagrams_dir / "ERD.jpeg"),
            "desc": "This diagram describes the database entities (User, Meeting, Task, Decision, SavedRecipient) and their structural relationships stored in Cloud Firestore."
        },
        {
            "name": "class",
            "page_num": 24,
            "title": "UML Class Diagram — Data Model Classes",
            "img": str(diagrams_dir / "uml_class.jpeg"),
            "desc": "This diagram illustrates the Dart class structure representing the application data models, including fields, types, relationships, and enumerations."
        },
        {
            "name": "component",
            "page_num": 28,
            "title": "Figure 5.5: UML Component Diagram",
            "img": str(diagrams_dir / "uml_component.jpeg"),
            "desc": "This diagram details the logical components of the MeetFlow AI system, highlighting the layered architecture (Presentation, State Management, Domain, Core Services, Data Repositories) and their integrations with Firebase."
        },
        {
            "name": "deployment",
            "page_num": 29,
            "title": "UML Deployment Diagram",
            "img": str(diagrams_dir / "deployemnt.jpeg"),
            "desc": "This diagram maps the hardware and execution environment deployment view of MeetFlow AI, showing the mobile client device, Firebase cloud services, and external Gemini AI service."
        }
    ]

    pdf_files = {}

    # Compile Use Case
    html_usecase_file = tmp_dir / "usecase.html"
    html_usecase_file.write_text(usecase_html, encoding='utf-8')
    pdf_files["usecase"] = tmp_dir / "usecase.pdf"
    print("Compiling Use Case diagram...")
    subprocess.run([chrome_bin, "--headless", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf-no-header", f"--print-to-pdf={pdf_files['usecase']}", str(html_usecase_file)], check=True)

    # Compile UI Design Text Page
    html_uitext_file = tmp_dir / "ui_design_text.html"
    html_uitext_file.write_text(ui_design_text_html, encoding='utf-8')
    pdf_files["ui_design_text"] = tmp_dir / "ui_design_text.pdf"
    print("Compiling UI Design Text page...")
    subprocess.run([chrome_bin, "--headless", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf-no-header", f"--print-to-pdf={pdf_files['ui_design_text']}", str(html_uitext_file)], check=True)

    # Compile Wireframe
    html_wireframe_file = tmp_dir / "wireframe.html"
    html_wireframe_file.write_text(wireframe_html, encoding='utf-8')
    pdf_files["wireframe"] = tmp_dir / "wireframe.pdf"
    print("Compiling Wireframe diagram...")
    subprocess.run([chrome_bin, "--headless", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf-no-header", f"--print-to-pdf={pdf_files['wireframe']}", str(html_wireframe_file)], check=True)

    # Compile 4 Diagram pages
    for item in diagram_pages:
        diag_html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        @page {{
            size: A4 portrait;
            margin: 20mm 15mm 20mm 15mm;
        }}
        body {{
            font-family: 'Inter', sans-serif;
            margin: 0;
            color: #1e293b;
            background-color: white;
            line-height: 1.5;
            text-align: center;
        }}
        .header {{
            font-size: 9.5px;
            color: #64748b;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 4px;
            margin-bottom: 15px;
            display: flex;
            justify-content: space-between;
        }}
        .header-left, .header-right {{
            font-weight: 500;
        }}
        h2 {{
            color: #1e3a8a;
            font-size: 15px;
            font-weight: 700;
            border-bottom: 1px solid #cbd5e1;
            padding-bottom: 8px;
            margin-top: 0;
            margin-bottom: 12px;
            text-align: left;
        }}
        .description {{
            font-size: 11px;
            color: #475569;
            margin-bottom: 25px;
            text-align: justify;
        }}
        .diagram-container {{
            margin-top: 15px;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 180mm;
        }}
        .diagram-container img {{
            max-width: 100%;
            max-height: 100%;
            object-fit: contain;
            border: 1px solid #e2e8f0;
            padding: 8px;
            background: #fafbfd;
            border-radius: 6px;
        }}
    </style>
</head>
<body>
    <div class="header">
        <span class="header-left">MeetFlow AI — Graduation Project</span>
        <span class="header-right">Page {item["page_num"]}</span>
    </div>
    <h2>{item["title"]}</h2>
    <div class="description">{item["desc"]}</div>
    <div class="diagram-container">
        <img src="file://{item["img"]}">
    </div>
</body>
</html>
"""
        html_file = tmp_dir / f"{item['name']}.html"
        html_file.write_text(diag_html, encoding='utf-8')
        pdf_files[item['name']] = tmp_dir / f"{item['name']}.pdf"
        print(f"Compiling {item['name']} diagram page...")
        subprocess.run([chrome_bin, "--headless", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf-no-header", f"--print-to-pdf={pdf_files[item['name']]}", str(html_file)], check=True)

    # 8. Merge all PDF files using clean_bak_pdf (32 pages) as base reader
    print(f"Reading from clean backup PDF {clean_bak_pdf}...")
    reader = pypdf.PdfReader(clean_bak_pdf)
    writer = pypdf.PdfWriter()

    # Part 1: Pages 1-16 (indices 0 to 15)
    print("Writing original pages 1-16...")
    for i in range(16):
        writer.add_page(reader.pages[i])

    # Part 2: Page 17 (updated Use Case)
    print("Writing Page 17 (Use Case Diagram)...")
    writer.add_page(pypdf.PdfReader(pdf_files["usecase"]).pages[0])

    # Part 3: Page 18 (index 17 from original - Section 5.4 Data Model text)
    print("Writing Page 18 (Data Model Text)...")
    writer.add_page(reader.pages[17])

    # Part 4: Page 19 (ERD - in Section 5.4 Data Model)
    print("Writing Page 19 (ERD Diagram)...")
    writer.add_page(pypdf.PdfReader(pdf_files["erd"]).pages[0])

    # Part 5: Page 20 (Re-rendered UI design text)
    print("Writing Page 20 (UI Design Text)...")
    writer.add_page(pypdf.PdfReader(pdf_files["ui_design_text"]).pages[0])

    # Part 6: Page 21 (UI Wireframe)
    print("Writing Page 21 (UI Wireframe)...")
    writer.add_page(pypdf.PdfReader(pdf_files["wireframe"]).pages[0])

    # Part 7: Page 22-23 (indices 19-20 from original - screenshots)
    print("Writing Pages 22-23 (UI Screenshots)...")
    writer.add_page(reader.pages[19])
    writer.add_page(reader.pages[20])

    # Part 8: Page 24 (UML Class - in Section 5.6 System Design Diagrams)
    print("Writing Page 24 (UML Class Diagram)...")
    writer.add_page(pypdf.PdfReader(pdf_files["class"]).pages[0])

    # Part 9: Pages 25, 26, 27 (Sequence diagrams)
    print("Writing Pages 25-27 (Sequence Diagrams)...")
    seq_reader = pypdf.PdfReader(sequence_pdf_path)
    for i in range(len(seq_reader.pages)):
        writer.add_page(seq_reader.pages[i])

    # Part 10: Page 28 (UML Component)
    print("Writing Page 28 (UML Component Diagram)...")
    writer.add_page(pypdf.PdfReader(pdf_files["component"]).pages[0])

    # Part 11: Page 29 (UML Deployment)
    print("Writing Page 29 (UML Deployment Diagram)...")
    writer.add_page(pypdf.PdfReader(pdf_files["deployment"]).pages[0])

    # Part 12: Pages 30-39 (indices 22 to 31 from original - Chapter 6 and rest)
    # Skipping index 21 which is original Page 22 (old diagrams placeholder)
    print("Writing remaining pages (Pages 30-39)...")
    for i in range(22, len(reader.pages)):
        writer.add_page(reader.pages[i])

    # Write merged PDF to the original location
    print(f"Writing merged PDF to {original_pdf}...")
    with open(original_pdf, "wb") as f:
        writer.write(f)

    # 9. Verify final page count
    final_reader = pypdf.PdfReader(original_pdf)
    final_pages = len(final_reader.pages)
    print(f"Successfully generated new PDF. Total pages: {final_pages}")
    
    if final_pages == 39:
        print("Page count verified (39 pages). Success!")
    else:
        print(f"Warning: Expected 39 pages, but got {final_pages}.")

    # Clean up temp files
    shutil.rmtree(tmp_dir)
    print("Cleanup done. Completed successfully!")

if __name__ == "__main__":
    main()
