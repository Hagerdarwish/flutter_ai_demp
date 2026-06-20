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
    v7_pdf = docs_dir / "MeetFlow_AI_Graduation_Project_Final_v7.pdf"
    v4_pdf = docs_dir / "MeetFlow_AI_Graduation_Project_Final_v4.pdf"
    v5_pdf = docs_dir / "MeetFlow_AI_Graduation_Project_Final_v5.pdf"
    clean_bak_pdf = docs_dir / "MeetFlow_AI_Graduation_Project_Final.pdf.bak"
    
    # 1. Archive the current 41-page PDF to v7_pdf (backing up the previous state)
    print(f"Archiving the current 41-page PDF to {v7_pdf}...")
    shutil.copyfile(original_pdf, v7_pdf)
    
    # 2. Check for browser (Brave or Chrome) to compile HTML to PDF
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
    tmp_dir = Path("/tmp/meetflow_final_render")
    tmp_dir.mkdir(parents=True, exist_ok=True)


    # 4. Extract diagram images from the appropriate PDFs
    print("Extracting diagram images...")
    
    # Extract ERD image from v5_pdf (index 18 / Page 19 of the 43-page PDF) where the isolated clean diagram is stored
    reader_v5 = pypdf.PdfReader(v5_pdf)
    erd_page = reader_v5.pages[18]
    extracted_erd_img = tmp_dir / "extracted_erd.jpg"
    if len(erd_page.images) > 0:
        extracted_erd_img.write_bytes(erd_page.images[0].data)
        print(f"Extracted ERD image: {extracted_erd_img} ({len(erd_page.images[0].data)} bytes)")
    else:
        print("Error: ERD image not found in v5_pdf!")
        return

    # Extract UML Class, Component, and Deployment diagrams from the 42-page PDF (v4_pdf)
    reader_42 = pypdf.PdfReader(v4_pdf)
    
    # Page 24 (index 23) is UML Class
    class_page = reader_42.pages[23]
    extracted_class_img = tmp_dir / "extracted_class.jpg"
    if len(class_page.images) > 0:
        extracted_class_img.write_bytes(class_page.images[0].data)
        print(f"Extracted UML Class image: {extracted_class_img}")
    else:
        print("Error: UML Class image not found in v4_pdf!")
        return

    # Page 31 (index 30) is UML Component
    comp_page = reader_42.pages[30]
    extracted_comp_img = tmp_dir / "extracted_component.jpg"
    if len(comp_page.images) > 0:
        extracted_comp_img.write_bytes(comp_page.images[0].data)
        print(f"Extracted Component image: {extracted_comp_img}")
    else:
        print("Error: Component image not found in v4_pdf!")
        return
        
    # Page 32 (index 31) is UML Deployment
    deploy_page = reader_42.pages[31]
    extracted_deploy_img = tmp_dir / "extracted_deployment.jpg"
    if len(deploy_page.images) > 0:
        extracted_deploy_img.write_bytes(deploy_page.images[0].data)
        print(f"Extracted Deployment image: {extracted_deploy_img}")
    else:
        print("Error: Deployment image not found in v4_pdf!")
        return

    # HTML overlay for Cover Page (Page 1) to update Supervisor Name and Track without destroying the original table layout and logo graphics
    cover_overlay_html = """<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        @page {
            size: 595.275pt 841.861pt;
            margin: 0;
        }
        body {
            background: transparent !important;
            background-color: transparent !important;
            margin: 0;
            padding: 0;
            width: 595.275pt;
            height: 841.861pt;
            overflow: hidden;
            font-family: Arial, sans-serif;
            font-size: 10.5pt;
            color: black;
        }
        .mask {
            position: absolute;
            background-color: white;
            width: 300pt;
            height: 18pt;
        }
        .text {
            position: absolute;
            line-height: 1;
            font-size: 10.5pt;
        }
    </style>
</head>
<body style="background: transparent; background-color: transparent;">
    <!-- Masks to cover old text -->
    <div class="mask" style="left: 228.00pt; top: 396.89pt;"></div>
    <div class="mask" style="left: 228.00pt; top: 425.24pt;"></div>

    <!-- New texts -->
    <div class="text" style="left: 229.40pt; top: 398.73pt;">Software engineer</div>
    <div class="text" style="left: 229.40pt; top: 427.83pt;">Dr Mager mamdouh</div>
</body>
</html>
"""

    # HTML content for Use Case Diagram (Page 16)
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
        <span class="header-right">Page 16</span>
    </div>

    <div class="figure-caption">Figure 5.1: Use case diagram for the primary user journeys.</div>

    <div class="diagram-container">
        <svg class="diagram-svg" width="700" height="440">
            <defs>
                <marker id="include-arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
                    <path d="M 2 2 L 8 5 L 2 8" fill="none" stroke="#2563eb" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
                </marker>
            </defs>
            
            <!-- Actor lines (left) - Perfect symmetrical center alignment -->
            <line x1="55" y1="203" x2="150" y2="27" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="55" y1="203" x2="150" y2="71" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="55" y1="203" x2="150" y2="115" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="55" y1="203" x2="150" y2="159" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="55" y1="203" x2="150" y2="203" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="55" y1="203" x2="150" y2="247" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="55" y1="203" x2="150" y2="291" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="55" y1="203" x2="150" y2="335" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="55" y1="203" x2="150" y2="379" stroke="#94a3b8" stroke-width="1.2" />

            <!-- Clean straight dashed <<include>> arrows -->
            <!-- Register Account includes Persist User Profile -->
            <line x1="290" y1="27" x2="402" y2="95" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="346" y="55" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <!-- Log In includes Validate Credentials -->
            <line x1="290" y1="71" x2="402" y2="35" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="346" y="47" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <!-- Import Meeting from File includes Analyze Content, Detect Language, Save Meeting -->
            <line x1="290" y1="159" x2="402" y2="155" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="346" y="151" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <line x1="290" y1="159" x2="402" y2="215" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="335" y="181" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <line x1="290" y1="159" x2="402" y2="275" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="330" y="211" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <!-- Import Meeting from Link includes Analyze Content, Detect Language, Save Meeting -->
            <line x1="290" y1="203" x2="402" y2="155" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="335" y="173" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <line x1="290" y1="203" x2="402" y2="215" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="346" y="203" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <line x1="290" y1="203" x2="402" y2="275" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="335" y="233" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <!-- Delete Meeting includes Delete Meeting Data -->
            <line x1="290" y1="247" x2="402" y2="335" stroke="#3b82f6" stroke-width="1.2" stroke-dasharray="3,3" marker-end="url(#include-arrow)" />
            <text x="346" y="285" font-size="7.5" fill="#2563eb" font-weight="600" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>

            <!-- Actor lines (right) -->
            <!-- Firebase Auth -->
            <line x1="550" y1="35" x2="600" y2="85" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="550" y1="95" x2="600" y2="85" stroke="#94a3b8" stroke-width="1.2" />

            <!-- Cloud Firestore -->
            <line x1="550" y1="275" x2="600" y2="230" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="550" y1="335" x2="600" y2="230" stroke="#94a3b8" stroke-width="1.2" />

            <!-- Gemini AI -->
            <line x1="550" y1="155" x2="600" y2="375" stroke="#94a3b8" stroke-width="1.2" />
            <line x1="550" y1="215" x2="600" y2="375" stroke="#94a3b8" stroke-width="1.2" />
        </svg>

        <div class="node actor" style="left: 10px; top: 168px;">
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
            <div class="usecase" style="left: 20px; top: 12px; width: 140px;">Register Account</div>
            <div class="usecase" style="left: 20px; top: 56px; width: 140px;">Log In</div>
            <div class="usecase" style="left: 20px; top: 100px; width: 140px;">Reset Password</div>
            <div class="usecase" style="left: 20px; top: 144px; width: 140px;">Import Meeting from File</div>
            <div class="usecase" style="left: 20px; top: 188px; width: 140px;">Import Meeting from Link</div>
            <div class="usecase" style="left: 20px; top: 232px; width: 140px;">Delete Meeting</div>
            <div class="usecase" style="left: 20px; top: 276px; width: 140px;">View Meeting History</div>
            <div class="usecase" style="left: 20px; top: 320px; width: 140px;">View Meeting Details</div>
            <div class="usecase" style="left: 20px; top: 364px; width: 140px;">Update Task Status</div>

            <div class="usecase system-uc" style="left: 280px; top: 20px; width: 140px;">Validate Credentials</div>
            <div class="usecase system-uc" style="left: 280px; top: 80px; width: 140px;">Persist User Profile</div>
            <div class="usecase system-uc" style="left: 280px; top: 140px; width: 140px;">Analyze Content</div>
            <div class="usecase system-uc" style="left: 280px; top: 200px; width: 140px;">Detect Language</div>
            <div class="usecase system-uc" style="left: 280px; top: 260px; width: 140px;">Save Meeting, Dec & Tasks</div>
            <div class="usecase system-uc" style="left: 280px; top: 320px; width: 140px;">Delete Meeting Data</div>
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
        <li>As a user, I want upload a recording and get minutes automatically, so that I save time writing them.</li>
        <li>As a user, I want decisions and action items extracted with owners, so that follow-up is clear.</li>
        <li>As a user, I want my action items in one task list with status, so that nothing is forgotten.</li>
        <li>As a user, I want to delete a meeting, so that I can remove unwanted records and data from my account.</li>
    </ul>
</body>
</html>
"""

    # HTML content for UI Design Text Page (Page 18)
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
        <span class="header-right">Page 18</span>
    </div>

    <h2>5.5 User Interface Design</h2>
    <p>The interface uses Material 3 with a light and dark theme and a bottom-navigation shell containing four primary destinations: Home (dashboard), Meetings (history), Tasks, and Settings. Authentication screens (login, register, forgot password) and full-screen flows (import meeting, meeting details) sit outside the shell. The main screens are:</p>
    <ul>
        <li><strong>Splash:</strong> resolves auth state and routes to Home or Login.</li>
        <li><strong>Auth (Login / Register / Forgot Password):</strong> email/password forms with validation and error messages.</li>
        <li><strong>Home:</strong> dashboard statistics and recent meetings, with an entry point to import.</li>
        <li><strong>Import Meeting:</strong> choose a file or paste a link, set title/date, and start processing with live status.</li>
        <li><strong>Meetings & Meeting Details:</strong> history list and a detail view of summary, minutes, decisions, participants, follow-ups, and tasks. Offers option to delete meeting.</li>
        <li><strong>Tasks:</strong> the consolidated action-item list with status and priority controls.</li>
        <li><strong>Settings:</strong> theme toggle, account, and logout.</li>
    </ul>
    <p>The following screenshots and wireframes document the implemented user interface and navigation flow.</p>
    <p><strong>Design quality note:</strong> The implemented screens show a consistent Material 3 mobile design, clear bottom navigation, visible processing feedback, Arabic-content rendering, task follow-up controls, and both light and dark settings. This makes the design evidence directly aligned with the functional requirements.</p>
</body>
</html>
"""

    # HTML content for UI Wireframes Page 1 (Page 19)
    wireframe_1_html = """<!DOCTYPE html>
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
            font-family: 'Inter', sans-serif;
            margin: 0;
            color: #1e293b;
            background-color: white;
            line-height: 1.4;
            font-size: 10px;
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
        h2 {
            color: #1e3a8a;
            font-size: 15px;
            font-weight: 700;
            border-bottom: 1px solid #cbd5e1;
            padding-bottom: 6px;
            margin-top: 0;
            margin-bottom: 8px;
            text-align: left;
        }
        .description {
            font-size: 10.5px;
            color: #475569;
            margin-bottom: 15px;
            text-align: justify;
        }
        .wireframe-row {
            display: flex;
            justify-content: center;
            gap: 30px;
            margin-bottom: 15px;
        }
        .mobile-device {
            width: 215px;
            height: 380px;
            border: 5px solid #1e293b;
            border-radius: 24px;
            background: #f8fafc;
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
            position: relative;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            box-sizing: border-box;
            flex-shrink: 0;
        }
        .notch {
            position: absolute;
            top: 0;
            left: 50%;
            transform: translateX(-50%);
            width: 70px;
            height: 11px;
            background: #1e293b;
            border-bottom-left-radius: 8px;
            border-bottom-right-radius: 8px;
            z-index: 10;
        }
        .status-bar {
            height: 18px;
            padding: 2px 12px 0 12px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 7.5px;
            color: #64748b;
            font-weight: 600;
            box-sizing: border-box;
            background: #f8fafc;
        }
        .app-bar {
            height: 30px;
            padding: 0 10px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: #ffffff;
            border-bottom: 1px solid #e2e8f0;
            font-weight: 700;
            color: #0f172a;
            font-size: 9.5px;
        }
        .screen-content {
            flex-grow: 1;
            padding: 8px;
            display: flex;
            flex-direction: column;
            gap: 6px;
            overflow: hidden;
            background: #f1f5f9;
        }
        .section-title {
            font-size: 8px;
            font-weight: 700;
            color: #475569;
            margin-top: 2px;
        }
        .card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 6px;
            display: flex;
            flex-direction: column;
            gap: 3px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.02);
            text-align: left;
        }
        .card-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .card-title {
            font-size: 8.5px;
            font-weight: 600;
            color: #0f172a;
        }
        .card-meta {
            font-size: 7px;
            color: #94a3b8;
        }
        .badge {
            font-size: 6.5px;
            font-weight: 700;
            padding: 1px 4px;
            border-radius: 4px;
        }
        .badge-success {
            background: #dcfce7;
            color: #166534;
        }
        .badge-warning {
            background: #fef9c3;
            color: #854d0e;
        }
        .badge-primary {
            background: #dbeafe;
            color: #1e40af;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 6px;
        }
        .stat-card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 6px;
            text-align: center;
        }
        .stat-num {
            font-size: 13px;
            font-weight: 700;
            color: #1e3a8a;
        }
        .stat-label {
            font-size: 7px;
            color: #64748b;
            font-weight: 500;
        }
        .form-group {
            display: flex;
            flex-direction: column;
            gap: 2px;
            text-align: left;
        }
        .form-label {
            font-size: 7.5px;
            font-weight: 600;
            color: #475569;
        }
        .form-input {
            background: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            padding: 4px 6px;
            font-size: 8px;
            color: #334155;
            box-sizing: border-box;
            width: 100%;
        }
        .file-dropzone {
            border: 1.5px dashed #3b82f6;
            background: #eff6ff;
            border-radius: 8px;
            padding: 12px;
            text-align: center;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 4px;
        }
        .upload-icon {
            font-size: 14px;
        }
        .segmented-control {
            display: flex;
            background: #e2e8f0;
            border-radius: 6px;
            padding: 2px;
        }
        .segment-btn {
            flex: 1;
            text-align: center;
            font-size: 7.5px;
            font-weight: 600;
            padding: 3px 0;
            border-radius: 4px;
            color: #64748b;
        }
        .segment-btn.active {
            background: #ffffff;
            color: #0f172a;
            box-shadow: 0 1px 2px rgba(0,0,0,0.05);
        }
        .btn-primary {
            background: #2563eb;
            color: white;
            font-size: 8.5px;
            font-weight: 600;
            text-align: center;
            padding: 6px 0;
            border-radius: 6px;
            box-shadow: 0 2px 4px rgba(37,99,235,0.15);
            margin-top: auto;
        }
        .bottom-nav {
            height: 34px;
            background: #ffffff;
            border-top: 1px solid #e2e8f0;
            display: flex;
            align-items: center;
            justify-content: space-around;
            padding: 0 4px;
            box-sizing: border-box;
        }
        .nav-item {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            color: #94a3b8;
            font-size: 7px;
            font-weight: 500;
            gap: 1px;
            flex: 1;
        }
        .nav-item.active {
            color: #2563eb;
            font-weight: 700;
        }
        .nav-icon {
            font-size: 11px;
        }
        .annotations-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            background: #f8fafc;
            border: 1px solid #cbd5e1;
            border-radius: 12px;
            padding: 12px;
            margin-top: 5px;
        }
        .annotation-section-title {
            font-size: 9.5px;
            font-weight: 700;
            color: #1e3a8a;
            border-bottom: 1.5px solid #cbd5e1;
            padding-bottom: 3px;
            margin-bottom: 6px;
            text-align: left;
        }
        .annotation-list {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }
        .annotation-item {
            display: flex;
            gap: 6px;
            font-size: 8.5px;
            line-height: 1.35;
            text-align: left;
        }
        .anno-num {
            background: #ef4444;
            color: white;
            font-weight: 700;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 7px;
            flex-shrink: 0;
            margin-top: 1px;
        }
        .anno-num.blue {
            background: #2563eb;
        }
        .item-desc {
            color: #334155;
        }
        .item-desc strong {
            color: #0f172a;
        }
    </style>
</head>
<body>
    <div class="header">
        <span class="header-left">MeetFlow AI — Graduation Project</span>
        <span class="header-right">Page 19</span>
    </div>

    <h2>Figure 5.3a: UI Wireframes — Home Dashboard & Import Meeting Screens</h2>
    <div class="description">These high-fidelity wireframes illustrate the layout and user experience design for the main landing dashboard and the meeting ingestion flows. Both screens implement Material 3 guidelines for card hierarchies and navigation shell design.</div>

    <div class="wireframe-row">
        <!-- Dashboard Screen -->
        <div class="mobile-device">
            <div class="notch"></div>
            <div class="status-bar">
                <span>09:41</span>
                <span>📶 🛜 🔋</span>
            </div>
            <div class="app-bar">
                <span>≡</span>
                <span>MeetFlow AI</span>
                <span style="font-size:12px">👤</span>
            </div>
            <div class="screen-content">
                <span class="section-title" style="font-size:9px; color:#0f172a; font-weight:700; text-align:left">Hello, Ahmed! 👋</span>
                
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-num">12</div>
                        <div class="stat-label">Total Meetings</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-num" style="color:#f97316">5</div>
                        <div class="stat-label">Pending Tasks</div>
                    </div>
                </div>
                
                <div class="card" style="border-left: 3px solid #2563eb; background:#eff6ff">
                    <div class="card-row">
                        <span style="font-size:8px; font-weight:700; color:#1e40af">AI PROCESSING ALIVE</span>
                        <span class="badge badge-primary">Processing</span>
                    </div>
                    <span style="font-size:8.5px; font-weight:600; color:#1e3a8a">Weekly Sync Meeting.mp3</span>
                    <div class="card-row">
                        <div style="height:4px; width:70%; background:#dbeafe; border-radius:2px; overflow:hidden">
                            <div style="height:100%; width:60%; background:#2563eb"></div>
                        </div>
                        <span style="font-size:6.5px; color:#1e40af">60%</span>
                    </div>
                </div>
                
                <span class="section-title" style="text-align:left">RECENT MEETINGS</span>
                
                <div class="card">
                    <div class="card-row">
                        <span class="card-title">Graduation Project Alignment</span>
                        <span class="badge badge-success">Completed</span>
                    </div>
                    <div class="card-row">
                        <span class="card-meta">Yesterday, 14:30 • 42 mins</span>
                        <span style="font-size:7px; font-weight:600; color:#475569">3 tasks</span>
                    </div>
                </div>

                <div class="card">
                    <div class="card-row">
                        <span class="card-title">App Interface Feedback</span>
                        <span class="badge badge-success">Completed</span>
                    </div>
                    <div class="card-row">
                        <span class="card-meta">June 18, 11:00 • 28 mins</span>
                        <span style="font-size:7px; font-weight:600; color:#475569">5 tasks</span>
                    </div>
                </div>
            </div>
            
            <div style="position:absolute; bottom:40px; right:12px; width:32px; height:32px; background:#2563eb; border-radius:50%; display:flex; align-items:center; justify-content:center; color:white; font-size:16px; font-weight:700; box-shadow:0 3px 6px rgba(37,99,235,0.3)">+</div>
            
            <div class="bottom-nav">
                <div class="nav-item active">
                    <span class="nav-icon">🏠</span>
                    <span>Home</span>
                </div>
                <div class="nav-item">
                    <span class="nav-icon">📅</span>
                    <span>Meetings</span>
                </div>
                <div class="nav-item">
                    <span class="nav-icon">✅</span>
                    <span>Tasks</span>
                </div>
                <div class="nav-item">
                    <span class="nav-icon">⚙️</span>
                    <span>Settings</span>
                </div>
            </div>
            <div style="position:absolute; left:12px; top:85px;" class="anno-num">1</div>
            <div style="position:absolute; left:170px; top:168px;" class="anno-num">2</div>
            <div style="position:absolute; left:182px; top:330px;" class="anno-num">3</div>
        </div>

        <!-- Import Screen -->
        <div class="mobile-device">
            <div class="notch"></div>
            <div class="status-bar">
                <span>09:42</span>
                <span>📶 🛜 🔋</span>
            </div>
            <div class="app-bar">
                <span>←</span>
                <span>Import Meeting</span>
                <span style="opacity:0">👤</span>
            </div>
            <div class="screen-content">
                <div class="segmented-control">
                    <div class="segment-btn active">File Upload</div>
                    <div class="segment-btn">URL Link</div>
                </div>
                
                <div class="file-dropzone">
                    <span class="upload-icon">📤</span>
                    <span style="font-size:8.5px; font-weight:700; color:#1e3a8a">Choose recording file</span>
                    <span style="font-size:6.5px; color:#64748b">MP3, M4A, MP4 up to 50MB</span>
                    <div style="background:#2563eb; color:white; font-size:7.5px; font-weight:600; padding:3px 8px; border-radius:4px; margin-top:2px">Select File</div>
                </div>
                
                <div class="form-group">
                    <span class="form-label">Meeting Title</span>
                    <input class="form-input" type="text" value="Graduation Demo Planning" readonly>
                </div>

                <div class="form-group">
                    <span class="form-label">Default Task Assignee</span>
                    <input class="form-input" type="text" value="Ahmed Nabil" readonly>
                </div>
                
                <div class="btn-primary">Start AI Processing</div>
            </div>
            <div style="position:absolute; left:14px; top:120px;" class="anno-num blue">4</div>
            <div style="position:absolute; left:14px; top:190px;" class="anno-num blue">5</div>
            <div style="position:absolute; left:14px; top:332px;" class="anno-num blue">6</div>
        </div>
    </div>

    <div class="annotations-grid">
        <div>
            <div class="annotation-section-title">Home Dashboard Screen (Left)</div>
            <div class="annotation-list">
                <div class="annotation-item">
                    <div class="anno-num">1</div>
                    <div class="item-desc"><strong>Quick Statistics Cards:</strong> Summarizes total meetings and pending tasks, giving the user immediate actionable insights on startup.</div>
                </div>
                <div class="annotation-item">
                    <div class="anno-num">2</div>
                    <div class="item-desc"><strong>Live Processing Status:</strong> Displays a real-time progress bar for background uploads and Gemini analysis.</div>
                </div>
                <div class="annotation-item">
                    <div class="anno-num">3</div>
                    <div class="item-desc"><strong>Floating Action Button (FAB):</strong> Prominently positions a quick entry point to launch the meeting import workflow.</div>
                </div>
            </div>
        </div>
        <div>
            <div class="annotation-section-title">Import Meeting Screen (Right)</div>
            <div class="annotation-list">
                <div class="annotation-item">
                    <div class="anno-num blue">4</div>
                    <div class="item-desc"><strong>Ingestion Type Selector:</strong> Tabs allow users to switch between local file upload and cloud sharing links.</div>
                </div>
                <div class="annotation-item">
                    <div class="anno-num blue">5</div>
                    <div class="item-desc"><strong>Dashed Dropzone Card:</strong> Large interactive touch target supporting standard drag-and-drop or file pickers.</div>
                </div>
                <div class="annotation-item">
                    <div class="anno-num blue">6</div>
                    <div class="item-desc"><strong>Processing Trigger:</strong> Large, colored call-to-action button to validate inputs and initiate parsing.</div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
"""

    # HTML content for UI Wireframes Page 2 (Page 20)
    wireframe_2_html = """<!DOCTYPE html>
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
            font-family: 'Inter', sans-serif;
            margin: 0;
            color: #1e293b;
            background-color: white;
            line-height: 1.4;
            font-size: 10px;
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
        h2 {
            color: #1e3a8a;
            font-size: 15px;
            font-weight: 700;
            border-bottom: 1px solid #cbd5e1;
            padding-bottom: 6px;
            margin-top: 0;
            margin-bottom: 8px;
            text-align: left;
        }
        .description {
            font-size: 10.5px;
            color: #475569;
            margin-bottom: 15px;
            text-align: justify;
        }
        .wireframe-row {
            display: flex;
            justify-content: center;
            gap: 30px;
            margin-bottom: 15px;
        }
        .mobile-device {
            width: 215px;
            height: 380px;
            border: 5px solid #1e293b;
            border-radius: 24px;
            background: #f8fafc;
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
            position: relative;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            box-sizing: border-box;
            flex-shrink: 0;
        }
        .notch {
            position: absolute;
            top: 0;
            left: 50%;
            transform: translateX(-50%);
            width: 70px;
            height: 11px;
            background: #1e293b;
            border-bottom-left-radius: 8px;
            border-bottom-right-radius: 8px;
            z-index: 10;
        }
        .status-bar {
            height: 18px;
            padding: 2px 12px 0 12px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 7.5px;
            color: #64748b;
            font-weight: 600;
            box-sizing: border-box;
            background: #f8fafc;
        }
        .app-bar {
            height: 30px;
            padding: 0 10px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: #ffffff;
            border-bottom: 1px solid #e2e8f0;
            font-weight: 700;
            color: #0f172a;
            font-size: 9.5px;
        }
        .screen-content {
            flex-grow: 1;
            padding: 8px;
            display: flex;
            flex-direction: column;
            gap: 6px;
            overflow: hidden;
            background: #f1f5f9;
        }
        .section-title {
            font-size: 8px;
            font-weight: 700;
            color: #475569;
            margin-top: 2px;
        }
        .card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 6px;
            display: flex;
            flex-direction: column;
            gap: 3px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.02);
            text-align: left;
        }
        .card-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .card-title {
            font-size: 8.5px;
            font-weight: 600;
            color: #0f172a;
        }
        .card-meta {
            font-size: 7px;
            color: #94a3b8;
        }
        .badge {
            font-size: 6.5px;
            font-weight: 700;
            padding: 1px 4px;
            border-radius: 4px;
        }
        .badge-danger {
            background: #fee2e2;
            color: #991b1b;
        }
        .badge-warning {
            background: #fef9c3;
            color: #854d0e;
        }
        .badge-success {
            background: #dcfce7;
            color: #166534;
        }
        .segmented-control {
            display: flex;
            background: #e2e8f0;
            border-radius: 6px;
            padding: 2px;
        }
        .segment-btn {
            flex: 1;
            text-align: center;
            font-size: 7.5px;
            font-weight: 600;
            padding: 3px 0;
            border-radius: 4px;
            color: #64748b;
        }
        .segment-btn.active {
            background: #ffffff;
            color: #0f172a;
            box-shadow: 0 1px 2px rgba(0,0,0,0.05);
        }
        .action-row {
            display: flex;
            gap: 6px;
            margin-top: auto;
        }
        .btn-half {
            flex: 1;
            font-size: 8px;
            font-weight: 600;
            text-align: center;
            padding: 5px 0;
            border-radius: 6px;
        }
        .btn-half.primary {
            background: #2563eb;
            color: white;
        }
        .btn-half.secondary {
            background: #ffffff;
            border: 1px solid #cbd5e1;
            color: #475569;
        }
        .btn-half.danger {
            background: #ef4444;
            color: white;
        }
        .search-bar {
            background: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            padding: 4px 8px;
            font-size: 8px;
            color: #94a3b8;
            display: flex;
            align-items: center;
            gap: 6px;
            text-align: left;
        }
        .task-item {
            display: flex;
            align-items: flex-start;
            gap: 6px;
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 6px;
            text-align: left;
        }
        .task-checkbox {
            width: 10px;
            height: 10px;
            border: 1px solid #cbd5e1;
            border-radius: 2px;
            margin-top: 2px;
            flex-shrink: 0;
        }
        .task-checkbox.checked {
            background: #2563eb;
            border-color: #2563eb;
            position: relative;
        }
        .task-checkbox.checked::after {
            content: "✓";
            color: white;
            font-size: 7px;
            position: absolute;
            top: -2px;
            left: 1px;
        }
        .task-details {
            flex-grow: 1;
            display: flex;
            flex-direction: column;
            gap: 2px;
        }
        .task-desc {
            font-size: 8px;
            font-weight: 500;
            color: #334155;
        }
        .task-desc.checked {
            text-decoration: line-through;
            color: #94a3b8;
        }
        .bottom-nav {
            height: 34px;
            background: #ffffff;
            border-top: 1px solid #e2e8f0;
            display: flex;
            align-items: center;
            justify-content: space-around;
            padding: 0 4px;
            box-sizing: border-box;
        }
        .nav-item {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            color: #94a3b8;
            font-size: 7px;
            font-weight: 500;
            gap: 1px;
            flex: 1;
        }
        .nav-item.active {
            color: #2563eb;
            font-weight: 700;
        }
        .nav-icon {
            font-size: 11px;
        }
        .annotations-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            background: #f8fafc;
            border: 1px solid #cbd5e1;
            border-radius: 12px;
            padding: 12px;
            margin-top: 5px;
        }
        .annotation-section-title {
            font-size: 9.5px;
            font-weight: 700;
            color: #1e3a8a;
            border-bottom: 1.5px solid #cbd5e1;
            padding-bottom: 3px;
            margin-bottom: 6px;
            text-align: left;
        }
        .annotation-list {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }
        .annotation-item {
            display: flex;
            gap: 6px;
            font-size: 8.5px;
            line-height: 1.35;
            text-align: left;
        }
        .anno-num {
            background: #ef4444;
            color: white;
            font-weight: 700;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 7px;
            flex-shrink: 0;
            margin-top: 1px;
        }
        .anno-num.blue {
            background: #2563eb;
        }
        .item-desc {
            color: #334155;
        }
        .item-desc strong {
            color: #0f172a;
        }
    </style>
</head>
<body>
    <div class="header">
        <span class="header-left">MeetFlow AI — Graduation Project</span>
        <span class="header-right">Page 20</span>
    </div>

    <h2>Figure 5.3b: UI Wireframes — Meeting Details & Tasks List Screens</h2>
    <div class="description">These high-fidelity wireframes illustrate the user interface layout for viewing meeting results and managing aggregated action items. These screens highlight structured tab layouts, user actions (including delete), and checklist states.</div>

    <div class="wireframe-row">
        <!-- Meeting Details Screen -->
        <div class="mobile-device">
            <div class="notch"></div>
            <div class="status-bar">
                <span>09:45</span>
                <span>📶 🛜 🔋</span>
            </div>
            <div class="app-bar">
                <span>←</span>
                <span>Meeting Details</span>
                <span>✏️</span>
            </div>
            <div class="screen-content">
                <div class="card" style="background:#ffffff; border-color:#cbd5e1; border-style:dashed">
                    <span style="font-size:9px; font-weight:700; color:#0f172a">Graduation Project Alignment</span>
                    <span style="font-size:7px; color:#64748b">June 20, 2026 • 42 mins • 4 participants</span>
                </div>
                
                <div class="segmented-control" style="background:#e2e8f0">
                    <div class="segment-btn active">Summary</div>
                    <div class="segment-btn">Minutes</div>
                    <div class="segment-btn">Tasks</div>
                </div>
                
                <div class="card" style="flex-grow:1; gap:4px">
                    <span style="font-size:7.5px; font-weight:700; color:#475569">EXECUTIVE SUMMARY</span>
                    <span style="font-size:8px; line-height:1.3; color:#334155">This meeting resolved the key graduation project document layout. The group agreed to structure the UML diagrams sequentially.</span>
                    
                    <span style="font-size:7.5px; font-weight:700; color:#475569; margin-top:2px">KEY DECISIONS</span>
                    <ul style="margin:0; padding-left:10px; font-size:7.5px; color:#334155; line-height:1.3">
                        <li>ERD placed in Section 5.4.</li>
                        <li>Class diagram placed in Section 5.6.</li>
                    </ul>
                </div>
                
                <div class="action-row">
                    <div class="btn-half secondary">Email Tasks</div>
                    <div class="btn-half danger">Delete Meeting</div>
                </div>
            </div>
            <div style="position:absolute; left:14px; top:112px;" class="anno-num">1</div>
            <div style="position:absolute; left:14px; top:145px;" class="anno-num">2</div>
            <div style="position:absolute; left:140px; top:330px;" class="anno-num">3</div>
        </div>

        <!-- Tasks List Screen -->
        <div class="mobile-device">
            <div class="notch"></div>
            <div class="status-bar">
                <span>09:46</span>
                <span>📶 🛜 🔋</span>
            </div>
            <div class="app-bar">
                <span style="opacity:0">←</span>
                <span>My Tasks</span>
                <span>🔍</span>
            </div>
            <div class="screen-content">
                <div class="search-bar">
                    <span>🔍</span>
                    <span>Search tasks...</span>
                </div>
                
                <div class="segmented-control">
                    <div class="segment-btn active">All</div>
                    <div class="segment-btn">Pending</div>
                    <div class="segment-btn">Done</div>
                </div>
                
                <span class="section-title" style="text-align:left">TODAY'S ACTION ITEMS</span>
                
                <div class="task-item">
                    <div class="task-checkbox"></div>
                    <div class="task-details">
                        <span class="task-desc">Resolve Firestore indexing rules</span>
                        <div class="card-row">
                            <span class="badge badge-danger">High Priority</span>
                            <span style="font-size:6.5px; color:#64748b; font-weight:600">Assignee: AN</span>
                        </div>
                    </div>
                </div>

                <div class="task-item">
                    <div class="task-checkbox checked"></div>
                    <div class="task-details">
                        <span class="task-desc checked">Upload final Activity diagram</span>
                        <div class="card-row">
                            <span class="badge badge-success">Completed</span>
                            <span style="font-size:6.5px; color:#64748b; font-weight:600">Assignee: HD</span>
                        </div>
                    </div>
                </div>

                <div class="task-item">
                    <div class="task-checkbox"></div>
                    <div class="task-details">
                        <span class="task-desc">Verify App Store release build</span>
                        <div class="card-row">
                            <span class="badge badge-warning">Medium Priority</span>
                            <span style="font-size:6.5px; color:#64748b; font-weight:600">Assignee: AN</span>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="bottom-nav">
                <div class="nav-item">
                    <span class="nav-icon">🏠</span>
                    <span>Home</span>
                </div>
                <div class="nav-item">
                    <span class="nav-icon">📅</span>
                    <span>Meetings</span>
                </div>
                <div class="nav-item active">
                    <span class="nav-icon">✅</span>
                    <span>Tasks</span>
                </div>
                <div class="nav-item">
                    <span class="nav-icon">⚙️</span>
                    <span>Settings</span>
                </div>
            </div>
            <div style="position:absolute; left:14px; top:112px;" class="anno-num blue">4</div>
            <div style="position:absolute; left:14px; top:152px;" class="anno-num blue">5</div>
            <div style="position:absolute; left:178px; top:288px;" class="anno-num blue">6</div>
        </div>
    </div>

    <div class="annotations-grid">
        <div>
            <div class="annotation-section-title">Meeting Details Screen (Left)</div>
            <div class="annotation-list">
                <div class="annotation-item">
                    <div class="anno-num">1</div>
                    <div class="item-desc"><strong>Segmented Results Tabs:</strong> Tabs filter the parsed Gemini response into clean views for Summary, Minutes, and Decisions.</div>
                </div>
                <div class="annotation-item">
                    <div class="anno-num">2</div>
                    <div class="item-desc"><strong>Information Cards:</strong> Uses Material cards to group summaries and lists separate from metadata, increasing scannability.</div>
                </div>
                <div class="annotation-item">
                    <div class="anno-num">3</div>
                    <div class="item-desc"><strong>Delete Meeting Trigger:</strong> Styled red button allowing the authenticated user to invoke meeting deletion on Cloud Firestore.</div>
                </div>
            </div>
        </div>
        <div>
            <div class="annotation-section-title">Tasks List Screen (Right)</div>
            <div class="annotation-list">
                <div class="annotation-item">
                    <div class="anno-num blue">4</div>
                    <div class="item-desc"><strong>Fuzzy Title Search:</strong> Search bar allows immediate filtering of action items by name or keyword.</div>
                </div>
                <div class="annotation-item">
                    <div class="anno-num blue">5</div>
                    <div class="item-desc"><strong>Aggregated Action Items:</strong> Integrates tasks from all meetings into a single, unified checklist.</div>
                </div>
                <div class="annotation-item">
                    <div class="anno-num blue">6</div>
                    <div class="item-desc"><strong>Pill Status Badges:</strong> Visual indicators show urgency (High, Medium, Low) and assignee initials (e.g. AN, HD).</div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
"""

    # Combined HTML for Section 5.4 Data Model & ERD Diagram (Page 17)
    data_model_html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        @page {{
            size: A4 portrait;
            margin: 15mm 15mm 15mm 15mm;
        }}
        body {{
            font-family: 'Inter', sans-serif;
            margin: 0;
            color: #1e293b;
            background-color: white;
            line-height: 1.35;
            font-size: 9.8px;
        }}
        .header {{
            font-size: 9.5px;
            color: #64748b;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 4px;
            margin-bottom: 10px;
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
            padding-bottom: 6px;
            margin-top: 0;
            margin-bottom: 8px;
            text-align: left;
        }}
        p {{
            margin-top: 0;
            margin-bottom: 6px;
            text-align: justify;
        }}
        .path-table {{
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 10px;
            font-size: 8.8px;
        }}
        .path-table th {{
            background-color: #f1f5f9;
            color: #334155;
            font-weight: 700;
            text-align: left;
            padding: 4px 6px;
            border: 1px solid #cbd5e1;
        }}
        .path-table td {{
            padding: 4px 6px;
            border: 1px solid #cbd5e1;
            vertical-align: top;
        }}
        .path-table tr:nth-child(even) {{
            background-color: #f8fafc;
        }}
        .diagram-caption {{
            font-size: 10px;
            font-weight: 600;
            color: #1e3a8a;
            margin-top: 10px;
            margin-bottom: 4px;
            text-align: left;
        }}
        .diagram-container {{
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100mm;
            margin-top: 5px;
        }}
        .diagram-container img {{
            max-width: 100%;
            max-height: 100%;
            object-fit: contain;
            border: 1px solid #e2e8f0;
            padding: 6px;
            background: #fafbfd;
            border-radius: 6px;
        }}
    </style>
</head>
<body>
    <div class="header">
        <span class="header-left">MeetFlow AI — Graduation Project</span>
        <span class="header-right">Page 17</span>
    </div>

    <h2>5.4 Data Model</h2>
    <p>Data is stored in Cloud Firestore and namespaced per user. Raw media is never stored — only metadata and generated results. The collection structure is:</p>
    
    <table class="path-table">
        <thead>
            <tr>
                <th style="width: 35%;">Path</th>
                <th style="width: 65%;">Contents</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td><strong>users/{{userId}}</strong></td>
                <td>User profile (id, name, email, timestamps).</td>
            </tr>
            <tr>
                <td><strong>users/{{userId}}/meetings/{{meetingId}}</strong></td>
                <td>Meeting metadata + summaries, minutes, participants, follow-ups, status.</td>
            </tr>
            <tr>
                <td><strong>users/{{userId}}/meetings/{{meetingId}}/decisions/{{id}}</strong></td>
                <td>Extracted decisions (text, owner).</td>
            </tr>
            <tr>
                <td><strong>users/{{userId}}/meetings/{{meetingId}}/tasks/{{id}}</strong></td>
                <td>Action items scoped to the meeting.</td>
            </tr>
            <tr>
                <td><strong>users/{{userId}}/tasks/{{id}}</strong></td>
                <td>Same action items duplicated at user level for the global Tasks tab.</td>
            </tr>
        </tbody>
    </table>

    <p style="margin-bottom: 6px;">The principal entities and their key fields are AppUser (id, name, email), Meeting (id, userId, title, sourceType, status, summaries, minutesOfMeeting[], participants[]), Decision (id, text, owner), and MeetingTask (id, meetingId, title, description, assignee, dueDate, priority, status). Action items are written twice in an atomic batch—under the meeting and at the user level—to support direct global queries.</p>

    <div class="diagram-caption">Figure 5.2: Entity-Relationship Diagram (ERD)</div>
    <div class="diagram-container">
        <img src="file://{extracted_erd_img}">
    </div>
</body>
</html>
"""

    # 5. Define diagram pages settings (Shifted to match new 41-page structure)
    diagram_pages = [
        {
            "name": "class",
            "page_num": 23,
            "title": "UML Class Diagram — Data Model Classes",
            "img": str(extracted_class_img),
            "desc": "This diagram illustrates the Dart class structure representing the application data models, including fields, types, relationships, and enumerations."
        },
        {
            "name": "auth_sequence",
            "page_num": 24,
            "title": "Figure 5.4: Sequence Diagram — User Authentication and Session Management",
            "img": str(diagrams_dir / "AuthSequenceDiagram.jpeg"),
            "desc": "This diagram illustrates the sequence of actions for user registration and login, highlighting state transitions in the AuthNotifier, interactions with the Authentication Repository, and backend synchronization with Firebase Auth and Cloud Firestore."
        },
        {
            "name": "import_sequence",
            "page_num": 25,
            "title": "Figure 5.5: Sequence Diagram — Meeting Import and Upload Flow",
            "img": str(diagrams_dir / "MeetingImportSequenceDiagram.jpeg"),
            "desc": "This diagram shows the process of importing meetings, including picking files via the File Picker Service, creating a draft meeting document in Firestore, and updating state notifications during the upload process."
        },
        {
            "name": "ai_sequence",
            "page_num": 26,
            "title": "Figure 5.6: Sequence Diagram — AI Processing and Meeting Analysis",
            "img": str(diagrams_dir / "AiProccessignSequenceDiagram.jpeg"),
            "desc": "This diagram details the core AI processing flow, where the application reads media bytes, invokes the Gemini service via the Firebase AI SDK, parses the structured JSON response, and commits the final results to Firestore."
        },
        {
            "name": "details_sequence",
            "page_num": 27,
            "title": "Figure 5.7: Sequence Diagram — Meeting Details and Task Status Updates",
            "img": str(diagrams_dir / "MeetingDetailsAndTaskUpdateDiagram.jpeg"),
            "desc": "This diagram illustrates the interaction flow within the meeting details view, demonstrating how users update task status and assignees, and how changes are committed across local state and Cloud Firestore databases."
        },
        {
            "name": "email_sequence",
            "page_num": 28,
            "title": "Figure 5.8: Sequence Diagram — Email Task Sharing Flow",
            "img": str(diagrams_dir / "EmailSharingSequenceDiagram.jpeg"),
            "desc": "This diagram outlines the email distribution workflow, showing how the application composes a personalized task summary in the user's preferred language and uses a system mailto link to launch the native mail client."
        },
        {
            "name": "activity",
            "page_num": 29,
            "title": "Figure 5.9: UML Activity Diagram — Meeting Import and Processing Lifecycle",
            "img": str(diagrams_dir / "ActivityDiagram.jpeg"),
            "desc": "This activity diagram illustrates the workflow and decision paths for importing, uploading, and processing meeting recordings, including format/size validations and AI analysis error-handling logic."
        },
        {
            "name": "component",
            "page_num": 30,
            "title": "Figure 5.10: UML Component Diagram — System Architecture and Layer Integration",
            "img": str(extracted_comp_img),
            "desc": "This diagram details the logical components of the MeetFlow AI system, highlighting the layered architecture (Presentation, State Management, Domain, Core Services, Data Repositories) and their integrations with Firebase."
        },
        {
            "name": "deployment",
            "page_num": 31,
            "title": "Figure 5.11: UML Deployment Diagram — Environment Node Mapping",
            "img": str(extracted_deploy_img),
            "desc": "This diagram maps the hardware and execution environment deployment view of MeetFlow AI, showing the mobile client device, Firebase cloud services, and external Gemini AI service."
        }
    ]

    pdf_files = {}

    # Compile Cover Page Overlay (Page 1)
    html_cover_file = tmp_dir / "cover_overlay.html"
    html_cover_file.write_text(cover_overlay_html, encoding='utf-8')
    pdf_files["cover_overlay"] = tmp_dir / "cover_overlay.pdf"
    print("Compiling Cover page overlay...")
    subprocess.run([chrome_bin, "--headless", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf-no-header", f"--print-to-pdf={pdf_files['cover_overlay']}", str(html_cover_file)], check=True)

    # Compile Use Case Page (Page 16)
    html_usecase_file = tmp_dir / "usecase.html"
    html_usecase_file.write_text(usecase_html, encoding='utf-8')
    pdf_files["usecase"] = tmp_dir / "usecase.pdf"
    print("Compiling Use Case diagram...")
    subprocess.run([chrome_bin, "--headless", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf-no-header", f"--print-to-pdf={pdf_files['usecase']}", str(html_usecase_file)], check=True)

    # Compile Data Model & ERD Page (Page 17)
    html_datamodel_file = tmp_dir / "datamodel.html"
    html_datamodel_file.write_text(data_model_html, encoding='utf-8')
    pdf_files["datamodel"] = tmp_dir / "datamodel.pdf"
    print("Compiling Data Model & ERD page...")
    subprocess.run([chrome_bin, "--headless", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf-no-header", f"--print-to-pdf={pdf_files['datamodel']}", str(html_datamodel_file)], check=True)

    # Compile UI Design Text Page (Page 18)
    html_uitext_file = tmp_dir / "ui_design_text.html"
    html_uitext_file.write_text(ui_design_text_html, encoding='utf-8')
    pdf_files["ui_design_text"] = tmp_dir / "ui_design_text.pdf"
    print("Compiling UI Design Text page...")
    subprocess.run([chrome_bin, "--headless", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf-no-header", f"--print-to-pdf={pdf_files['ui_design_text']}", str(html_uitext_file)], check=True)

    # Compile Wireframe 1 (Page 19)
    html_wireframe_1_file = tmp_dir / "wireframe_1.html"
    html_wireframe_1_file.write_text(wireframe_1_html, encoding='utf-8')
    pdf_files["wireframe_1"] = tmp_dir / "wireframe_1.pdf"
    print("Compiling Wireframe Page 1...")
    subprocess.run([chrome_bin, "--headless", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf-no-header", f"--print-to-pdf={pdf_files['wireframe_1']}", str(html_wireframe_1_file)], check=True)

    # Compile Wireframe 2 (Page 20)
    html_wireframe_2_file = tmp_dir / "wireframe_2.html"
    html_wireframe_2_file.write_text(wireframe_2_html, encoding='utf-8')
    pdf_files["wireframe_2"] = tmp_dir / "wireframe_2.pdf"
    print("Compiling Wireframe Page 2...")
    subprocess.run([chrome_bin, "--headless", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf-no-header", f"--print-to-pdf={pdf_files['wireframe_2']}", str(html_wireframe_2_file)], check=True)

    # Compile all diagram pages (Pages 23 to 31)
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
        subprocess.run([
            chrome_bin,
            "--headless",
            "--disable-gpu",
            "--no-pdf-header-footer",
            "--print-to-pdf-no-header",
            f"--print-to-pdf={pdf_files[item['name']]}",
            str(html_file)
        ], check=True)

    # 6. Splicing they together with clean base PDF (32 pages)
    print(f"Reading from clean backup PDF {clean_bak_pdf}...")
    reader_bak = pypdf.PdfReader(clean_bak_pdf)
    writer = pypdf.PdfWriter()

    # Part 1: Page 1 (Original Cover page with updated Supervisor and Track overlaid)
    print("Writing Page 1 (Cover Page)...")
    cover_page = reader_bak.pages[0]
    overlay_reader = pypdf.PdfReader(pdf_files["cover_overlay"])
    cover_page.merge_page(overlay_reader.pages[0])
    writer.add_page(cover_page)

    # Part 2: Pages 2-15 (indices 2 to 15 from clean base PDF - skipping index 1 which was Document Control)
    print("Writing original pages 2-15...")
    for i in range(2, 16):
        writer.add_page(reader_bak.pages[i])

    # Part 3: Page 16 (compiled Use Case)
    print("Writing Page 16 (Use Case Diagram)...")
    writer.add_page(pypdf.PdfReader(pdf_files["usecase"]).pages[0])

    # Part 4: Page 17 (compiled Data Model + ERD)
    print("Writing Page 17 (Data Model & ERD Diagram)...")
    writer.add_page(pypdf.PdfReader(pdf_files["datamodel"]).pages[0])

    # Part 5: Page 18 (compiled UI Design Text)
    print("Writing Page 18 (UI Design Text)...")
    writer.add_page(pypdf.PdfReader(pdf_files["ui_design_text"]).pages[0])

    # Part 6: Page 19 (compiled Wireframes Page 1)
    print("Writing Page 19 (Wireframes Page 1)...")
    writer.add_page(pypdf.PdfReader(pdf_files["wireframe_1"]).pages[0])

    # Part 7: Page 20 (compiled Wireframes Page 2)
    print("Writing Page 20 (Wireframes Page 2)...")
    writer.add_page(pypdf.PdfReader(pdf_files["wireframe_2"]).pages[0])

    # Part 8: Pages 21-22 (indices 19-20 from clean base PDF - UI Screenshots)
    print("Writing Pages 21-22 (UI Screenshots)...")
    writer.add_page(reader_bak.pages[19])
    writer.add_page(reader_bak.pages[20])

    # Part 9: Page 23 (compiled UML Class)
    print("Writing Page 23 (UML Class Diagram)...")
    writer.add_page(pypdf.PdfReader(pdf_files["class"]).pages[0])

    # Part 10: Pages 24-31 (compiled Sequence, Activity, Component, Deployment diagrams)
    print("Writing Pages 24-31...")
    diagram_keys = [
        "auth_sequence",
        "import_sequence",
        "ai_sequence",
        "details_sequence",
        "email_sequence",
        "activity",
        "component",
        "deployment"
    ]
    for key in diagram_keys:
        p_reader = pypdf.PdfReader(pdf_files[key])
        writer.add_page(p_reader.pages[0])

    # Part 11: Pages 32-41 (indices 22 to 31 from clean base PDF - Chapter 6 and rest)
    print("Writing remaining pages 32-41...")
    for i in range(22, len(reader_bak.pages)):
        writer.add_page(reader_bak.pages[i])

    # Write merged PDF to the original location
    print(f"Writing merged PDF to {original_pdf}...")
    with open(original_pdf, "wb") as f:
        writer.write(f)

    # 7. Verify final page count
    final_reader = pypdf.PdfReader(original_pdf)
    final_pages = len(final_reader.pages)
    print(f"Successfully generated new PDF. Total pages: {final_pages}")
    
    if final_pages == 41:
        print("Page count verified (41 pages). Success!")
    else:
        print(f"Warning: Expected 41 pages, but got {final_pages}.")

    # Clean up temp files
    shutil.rmtree(tmp_dir)
    print("Cleanup done. Completed successfully!")

if __name__ == "__main__":
    main()
