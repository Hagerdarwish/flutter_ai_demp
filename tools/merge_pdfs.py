import pypdf
import os
from pathlib import Path

def main():
    docs_path = Path("/Users/ahmednabil/StudioProjects/flutter_ai_demp/docs/grad_project_docs.pdf")
    diags_path = Path("/Users/ahmednabil/StudioProjects/flutter_ai_demp/docs/grad_project.pdf")
    temp_path = Path("/Users/ahmednabil/StudioProjects/flutter_ai_demp/docs/grad_project_docs_temp.pdf")

    if not docs_path.exists():
        print(f"Error: {docs_path} not found")
        return
    if not diags_path.exists():
        print(f"Error: {diags_path} not found")
        return

    print("Reading PDF files...")
    reader_docs = pypdf.PdfReader(docs_path)
    reader_diags = pypdf.PdfReader(diags_path)
    writer = pypdf.PdfWriter()

    # Total pages in docs: 32
    # We insert right after Page 21 (index 21), which is before Page 22 (index 21 in 0-indexed list)
    # Add pages 0 to 20 (first 21 pages)
    print("Adding first 21 pages from documentation...")
    for i in range(21):
        writer.add_page(reader_docs.pages[i])

    # Add 3 pages from sequence diagrams
    print("Inserting 3 pages of sequence diagrams...")
    for i in range(len(reader_diags.pages)):
        writer.add_page(reader_diags.pages[i])

    # Add remaining pages (index 21 to end)
    print("Adding remaining pages from documentation...")
    for i in range(21, len(reader_docs.pages)):
        writer.add_page(reader_docs.pages[i])

    print("Writing merged PDF...")
    with open(temp_path, "wb") as f:
        writer.write(f)

    # Replace original file safely
    temp_path.replace(docs_path)
    
    final_reader = pypdf.PdfReader(docs_path)
    print(f"Successfully merged! Total pages in new document: {len(final_reader.pages)}")

if __name__ == "__main__":
    main()
