import os
import shutil
import subprocess
from pathlib import Path

def main():
    project_dir = Path("/Users/ahmednabil/StudioProjects/flutter_ai_demp")
    docs_dir = project_dir / "docs"
    presentation_src_dir = docs_dir / "presentation"
    
    # Target presentation folder at the root of the workspace
    target_dir = project_dir / "presentation"
    target_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"Creating presentation folder at {target_dir}...")
    
    # 1. Copy the images directory
    src_images = presentation_src_dir / "images"
    dest_images = target_dir / "images"
    if src_images.exists():
        if dest_images.exists():
            shutil.rmtree(dest_images)
        shutil.copytree(src_images, dest_images)
        print("Copied images folder successfully.")
    else:
        print("Warning: Source images folder not found!")

    # 2. Copy the interactive HTML presentation
    src_html = presentation_src_dir / "index.html"
    dest_html = target_dir / "interactive_presentation.html"
    
    if src_html.exists():
        content = src_html.read_text(encoding='utf-8')
        # Update diagram image paths from ../../diagrams/ to ../diagrams/
        # since the target file is now 1 level deep (presentation/) instead of 2 (docs/presentation/)
        updated_content = content.replace("../../diagrams/", "../diagrams/")
        dest_html.write_text(updated_content, encoding='utf-8')
        print(f"Created {dest_html.name} and updated diagram paths.")
    else:
        print("Error: Source index.html not found!")
        return

    # 3. Run Marp CLI to compile docs/presentation/presentation.md to:
    #    - presentation/presentation.html
    #    - presentation/presentation.pptx
    md_slides = presentation_src_dir / "presentation.md"
    if not md_slides.exists():
        print("Error: Source presentation.md not found!")
        return

    out_html = target_dir / "presentation.html"
    out_pptx = target_dir / "presentation.pptx"

    # We need to find Chrome or Brave for Marp
    chrome_bin = None
    chrome_paths = [
        "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    ]
    for p in chrome_paths:
        if os.path.exists(p):
            chrome_bin = p
            break

    env = os.environ.copy()
    if chrome_bin:
        env["CHROME_PATH"] = chrome_bin
        print(f"Using browser for Marp export: {chrome_bin}")

    # Compile HTML
    print("Compiling Marp slides to HTML...")
    subprocess.run([
        "npx", "-y", "@marp-team/marp-cli@latest",
        "--no-stdin",
        "--html",
        "--allow-local-files",
        str(md_slides),
        "-o", str(out_html)
    ], check=True, env=env)
    
    # Compile PPTX
    print("Compiling Marp slides to PowerPoint (.pptx)...")
    subprocess.run([
        "npx", "-y", "@marp-team/marp-cli@latest",
        "--no-stdin",
        "--html",
        "--allow-local-files",
        str(md_slides),
        "-o", str(out_pptx)
    ], check=True, env=env)

    print("\nVerification of built files:")
    print(f"1. {out_pptx.relative_to(project_dir)} exists: {out_pptx.exists()} ({out_pptx.stat().st_size if out_pptx.exists() else 0} bytes)")
    print(f"2. {out_html.relative_to(project_dir)} exists: {out_html.exists()} ({out_html.stat().st_size if out_html.exists() else 0} bytes)")
    print(f"3. {dest_html.relative_to(project_dir)} exists: {dest_html.exists()} ({dest_html.stat().st_size if dest_html.exists() else 0} bytes)")
    print("\nPresentation files generated successfully!")

if __name__ == "__main__":
    main()
