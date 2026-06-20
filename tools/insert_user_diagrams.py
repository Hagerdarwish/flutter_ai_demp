import os
import shutil
import subprocess
from pathlib import Path
import pypdf

def main():
    project_dir = Path("/Users/ahmednabil/StudioProjects/flutter_ai_demp")
    docs_dir = project_dir / "docs"
    diagrams_dir = project_dir / "diagrams"
    
    original_pdf_path = docs_dir / "MeetFlow_AI_Graduation_Project_Final.pdf"
    backup_pdf_path = docs_dir / "MeetFlow_AI_Graduation_Project_Final.pdf.bak"
    sequence_pdf_path = docs_dir / "grad_project.pdf"
    
    # 1. Back up the original PDF
    print(f"Creating backup of original PDF to {backup_pdf_path}...")
    shutil.copyfile(original_pdf_path, backup_pdf_path)

    # 2. Check if browser is available for rendering HTML to PDF
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
        print("Error: Headless Chrome or Brave Browser not found!")
        return

    # 3. Create temp directory for generating PDFs
    tmp_dir = Path("/tmp/meetflow_insert_user")
    tmp_dir.mkdir(parents=True, exist_ok=True)

    # Define the 4 pages to generate
    pages_to_generate = [
        {
            "name": "erd",
            "title": "Figure 5.2: Entity-Relationship Diagram (ERD)",
            "img": str(diagrams_dir / "ERD.jpeg"),
            "desc": "This diagram describes the database entities (User, Meeting, Task, Decision, SavedRecipient) and their structural relationships stored in Cloud Firestore."
        },
        {
            "name": "class",
            "title": "UML Class Diagram — Data Model Classes",
            "img": str(diagrams_dir / "uml_class.jpeg"),
            "desc": "This diagram illustrates the Dart class structure representing the application data models, including fields, types, relationships, and enumerations."
        },
        {
            "name": "component",
            "title": "Figure 5.5: UML Component Diagram",
            "img": str(diagrams_dir / "uml_component.jpeg"),
            "desc": "This diagram details the logical components of the MeetFlow AI system, highlighting the layered architecture (Presentation, State Management, Domain, Core Services, Data Repositories) and their integrations with Firebase."
        },
        {
            "name": "deployment",
            "title": "UML Deployment Diagram",
            "img": str(diagrams_dir / "deployemnt.jpeg"),
            "desc": "This diagram maps the hardware and execution environment deployment view of MeetFlow AI, showing the mobile client device, Firebase cloud services, and external Gemini AI service."
        }
    ]

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

    # 4. Merge PDF files
    print("Reading and merging PDF files...")
    reader = pypdf.PdfReader(backup_pdf_path)
    writer = pypdf.PdfWriter()

    # Original PDF has exactly 32 pages.
    # Add pages 1 to 19 (index 0 to 18)
    print("Writing original pages 1-19...")
    for i in range(19):
        writer.add_page(reader.pages[i])

    # Insert ERD & Class diagrams
    print("Inserting ERD and Class Diagrams...")
    writer.add_page(pypdf.PdfReader(pdf_paths["erd"]).pages[0])
    writer.add_page(pypdf.PdfReader(pdf_paths["class"]).pages[0])

    # Add pages 20 to 21 (index 19 to 20)
    print("Writing original pages 20-21...")
    for i in range(19, 21):
        writer.add_page(reader.pages[i])

    # Insert Sequence Diagrams (3 pages)
    print("Inserting Sequence Diagrams...")
    seq_reader = pypdf.PdfReader(sequence_pdf_path)
    for i in range(len(seq_reader.pages)):
        writer.add_page(seq_reader.pages[i])

    # Add page 22 (index 21)
    print("Writing original page 22...")
    writer.add_page(reader.pages[21])

    # Insert Component and Deployment diagrams
    print("Inserting Component and Deployment Diagrams...")
    writer.add_page(pypdf.PdfReader(pdf_paths["component"]).pages[0])
    writer.add_page(pypdf.PdfReader(pdf_paths["deployment"]).pages[0])

    # Add remaining pages 23 to 32 (index 22 to 31)
    print("Writing remaining pages...")
    for i in range(22, len(reader.pages)):
        writer.add_page(reader.pages[i])

    # Write merged PDF to the original location
    print(f"Writing merged PDF to {original_pdf_path}...")
    with open(original_pdf_path, "wb") as f:
        writer.write(f)

    # 5. Verify the merged PDF page count
    final_reader = pypdf.PdfReader(original_pdf_path)
    final_pages = len(final_reader.pages)
    print(f"Successfully generated new PDF. Total pages: {final_pages}")
    
    if final_pages == 39:
        print("Page count verified (39 pages). Success!")
    else:
        print(f"Warning: Expected 39 pages, but got {final_pages}.")

if __name__ == "__main__":
    main()
