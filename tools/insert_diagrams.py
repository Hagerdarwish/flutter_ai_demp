import base64
import json
import zlib
import urllib.request
import os
import subprocess
import pypdf
from pathlib import Path

# Mermaid ERD representing the database structure
erd_mermaid = """erDiagram
    AppUser ||--o{ Meeting : has
    AppUser ||--o{ Task : tracks
    AppUser ||--o{ SavedRecipient : saves
    Meeting ||--o{ Task : has
    Meeting ||--o{ Decision : has

    AppUser {
        string id PK
        string name
        string email
        datetime createdAt
        datetime updatedAt
    }

    Meeting {
        string meetingId PK
        string title
        string sourceType
        string sourceName
        string sourceUrl
        string fileType
        string status
        datetime createdAt
        string shortSummary
        string detailedSummary
        string_array minutesOfMeeting
        string_array participants
    }

    Task {
        string taskId PK
        string title
        string description
        string assignee
        string dueDate
        string priority
        string status
        datetime createdAt
        datetime updatedAt
        string meetingId FK
        string userId FK
    }

    Decision {
        string decisionId PK
        string text
        string owner
        datetime createdAt
        string meetingId FK
    }

    SavedRecipient {
        string recipientId PK
        string email
        string label
        datetime createdAt
        string userId FK
    }"""

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
    docs_dir = Path("/Users/ahmednabil/StudioProjects/flutter_ai_demp/docs")
    tmp_dir = Path("/tmp/meetflow_insert")
    tmp_dir.mkdir(parents=True, exist_ok=True)

    # 1. Download ERD
    print("Downloading ERD diagram...")
    erd_url = get_mermaid_ink_url(erd_mermaid)
    erd_svg_path = docs_dir / "diagram4.svg"
    req = urllib.request.Request(erd_url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response:
        erd_svg_path.write_bytes(response.read())

    # 2. Prepare HTML templates for each page
    pages_to_generate = [
        {
            "name": "erd",
            "title": "Figure 5.2: Entity-Relationship Diagram (ERD)",
            "img": str(erd_svg_path),
            "desc": "This diagram describes the database entities (User, Meeting, Task, Decision, SavedRecipient) and their structural relationships stored in Cloud Firestore."
        },
        {
            "name": "class",
            "title": "UML Class Diagram — Data Model Classes",
            "img": str(docs_dir / "diagram2.jpg"),
            "desc": "This diagram illustrates the Dart class structure representing the application data models, including fields, types, relationships, and enumerations."
        },
        {
            "name": "component",
            "title": "Figure 5.5: UML Component Diagram",
            "img": str(docs_dir / "diagram3.jpg"),
            "desc": "This diagram details the logical components of the MeetFlow AI system, highlighting the layered architecture (Presentation, State Management, Domain, Core Services, Data Repositories) and their integrations with Firebase."
        },
        {
            "name": "deployment",
            "title": "UML Deployment Diagram",
            "img": str(docs_dir / "diagram1.jpg"),
            "desc": "This diagram maps the hardware and execution environment deployment view of MeetFlow AI, showing the mobile client device, Firebase cloud services, and external Gemini AI service."
        }
    ]

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

    # Compile HTML and print to PDF for each diagram page
    pdf_paths = {}
    for item in pages_to_generate:
        html_content = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        @page {{
            size: A4 portrait;
            margin: 20mm 15mm 20mm 15mm;
        }}
        body {{
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            margin: 0;
            color: #1e293b;
            background-color: white;
            line-height: 1.5;
            text-align: center;
        }}
        h2 {{
            color: #1e3a8a;
            font-size: 18px;
            border-bottom: 2px solid #3b82f6;
            padding-bottom: 8px;
            margin-top: 0;
            margin-bottom: 12px;
            text-align: left;
        }}
        .description {{
            font-size: 12.5px;
            color: #475569;
            margin-bottom: 25px;
            text-align: justify;
        }}
        .diagram-container {{
            margin-top: 15px;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 190mm;
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
    <h2>{item["title"]}</h2>
    <div class="description">{item["desc"]}</div>
    <div class="diagram-container">
        <img src="file://{item["img"]}">
    </div>
</body>
</html>
"""
        html_file = tmp_dir / f"{item['name']}.html"
        html_file.write_text(html_content, encoding='utf-8')
        
        pdf_file = tmp_dir / f"{item['name']}.pdf"
        print(f"Generating PDF for {item['name']}...")
        cmd = [
            chrome_bin,
            "--headless",
            "--disable-gpu",
            "--no-pdf-header-footer",
            "--print-to-pdf-no-header",
            f"--print-to-pdf={pdf_file}",
            str(html_file)
        ]
        subprocess.run(cmd, check=True)
        pdf_paths[item['name']] = pdf_file

    # 3. Merge into grad_project_docs.pdf
    original_pdf_path = docs_dir / "grad_project_docs.pdf"
    if not original_pdf_path.exists():
        print(f"Error: {original_pdf_path} not found")
        return

    print("Merging PDF pages...")
    reader = pypdf.PdfReader(original_pdf_path)
    writer = pypdf.PdfWriter()

    # Original PDF has exactly 32 pages.
    # We will build a new PDF by inserting the diagrams at the correct offsets.

    # 1. Add pages 1 to 19 (index 0 to 18)
    print("Writing pages 1-19...")
    for i in range(19):
        writer.add_page(reader.pages[i])

    # Insert ERD & Class diagrams
    print("Inserting ERD and Class Diagrams...")
    writer.add_page(pypdf.PdfReader(pdf_paths["erd"]).pages[0])
    writer.add_page(pypdf.PdfReader(pdf_paths["class"]).pages[0])

    # 2. Add pages 20 to 21 (index 19 to 20)
    print("Writing pages 20-21...")
    for i in range(19, 21):
        writer.add_page(reader.pages[i])

    # Insert Sequence Diagrams (3 pages)
    print("Inserting 3 pages of Sequence Diagrams...")
    seq_reader = pypdf.PdfReader(docs_dir / "grad_project.pdf")
    for i in range(len(seq_reader.pages)):
        writer.add_page(seq_reader.pages[i])

    # 3. Add page 22 (index 21)
    print("Writing page 22...")
    writer.add_page(reader.pages[21])

    # Insert Component Diagram
    print("Inserting Component Diagram...")
    writer.add_page(pypdf.PdfReader(pdf_paths["component"]).pages[0])

    # Insert Deployment Diagram
    print("Inserting Deployment Diagram...")
    writer.add_page(pypdf.PdfReader(pdf_paths["deployment"]).pages[0])

    # 4. Add pages 23 to 32 (index 22 to 31)
    print("Writing remaining pages...")
    for i in range(22, len(reader.pages)):
        writer.add_page(reader.pages[i])

    # Write merged PDF
    output_pdf_path = docs_dir / "grad_project_docs_temp.pdf"
    with open(output_pdf_path, "wb") as f:
        writer.write(f)

    # Overwrite original
    output_pdf_path.replace(original_pdf_path)
    
    final_reader = pypdf.PdfReader(original_pdf_path)
    print(f"Successfully inserted all diagrams! Total pages now: {len(final_reader.pages)}")

if __name__ == "__main__":
    main()
