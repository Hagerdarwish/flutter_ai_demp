from __future__ import annotations

import math
import shutil
import zipfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


SOURCE_DOCX = Path("/Users/hagerdarwish/Downloads/MeetFlow_AI_Graduation_Project.docx")
OUTPUT_DOCX = Path("/Users/hagerdarwish/Downloads/MeetFlow_AI_Graduation_Project_Improved.docx")
OUT_DIR = Path("/tmp/meetflow_diagram_updates")

FONT_REG = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

NAVY = "#1f3b6d"
BLUE = "#3467c2"
SKY = "#eaf2ff"
GREEN = "#2f5d3a"
MINT = "#edf7ee"
ORANGE = "#c96a17"
PEACH = "#fff4e8"
GRAY = "#5f6670"
LIGHT = "#f6f8fb"
BLACK = "#263238"
RED = "#c44646"
PINK = "#fff1f1"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_BOLD if bold else FONT_REG, size)


def wrapped_lines(draw: ImageDraw.ImageDraw, text: str, max_width: int, text_font: ImageFont.FreeTypeFont) -> list[str]:
    words = text.split()
    if not words:
        return [""]
    lines: list[str] = []
    current = words[0]
    for word in words[1:]:
        trial = f"{current} {word}"
        if draw.textbbox((0, 0), trial, font=text_font)[2] <= max_width:
            current = trial
        else:
            lines.append(current)
            current = word
    lines.append(current)
    return lines


def draw_centered_text(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    text: str,
    text_font: ImageFont.FreeTypeFont,
    fill: str = BLACK,
    spacing: int = 6,
) -> None:
    x1, y1, x2, y2 = box
    lines = wrapped_lines(draw, text, x2 - x1 - 10, text_font)
    heights = []
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=text_font)
        heights.append(bbox[3] - bbox[1])
    total_h = sum(heights) + spacing * (len(lines) - 1)
    y = y1 + ((y2 - y1) - total_h) / 2
    for line, h in zip(lines, heights):
        bbox = draw.textbbox((0, 0), line, font=text_font)
        w = bbox[2] - bbox[0]
        draw.text((x1 + ((x2 - x1) - w) / 2, y), line, font=text_font, fill=fill)
        y += h + spacing


def rounded_box(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    fill: str,
    outline: str,
    width: int = 3,
    radius: int = 22,
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def arrow(
    draw: ImageDraw.ImageDraw,
    start: tuple[int, int],
    end: tuple[int, int],
    fill: str = NAVY,
    width: int = 4,
    dashed: bool = False,
) -> None:
    if dashed:
        dash = 12
        gap = 8
        dx = end[0] - start[0]
        dy = end[1] - start[1]
        dist = max(1, math.hypot(dx, dy))
        ux = dx / dist
        uy = dy / dist
        pos = 0.0
        while pos < dist - 18:
            s = (start[0] + ux * pos, start[1] + uy * pos)
            e = (start[0] + ux * min(pos + dash, dist - 18), start[1] + uy * min(pos + dash, dist - 18))
            draw.line([s, e], fill=fill, width=width)
            pos += dash + gap
    else:
        draw.line([start, end], fill=fill, width=width)
    angle = math.atan2(end[1] - start[1], end[0] - start[0])
    head = 14
    left = (
        end[0] - head * math.cos(angle - math.pi / 6),
        end[1] - head * math.sin(angle - math.pi / 6),
    )
    right = (
        end[0] - head * math.cos(angle + math.pi / 6),
        end[1] - head * math.sin(angle + math.pi / 6),
    )
    draw.polygon([end, left, right], fill=fill)


def actor(draw: ImageDraw.ImageDraw, center: tuple[int, int], color: str, label: str) -> None:
    x, y = center
    draw.ellipse((x - 22, y, x + 22, y + 44), outline=color, width=4, fill="white")
    draw.line((x, y + 44, x, y + 112), fill=color, width=4)
    draw.line((x - 38, y + 67, x + 38, y + 67), fill=color, width=4)
    draw.line((x, y + 112, x - 32, y + 158), fill=color, width=4)
    draw.line((x, y + 112, x + 32, y + 158), fill=color, width=4)
    draw_centered_text(draw, (x - 70, y + 175, x + 70, y + 228), label, font(28, bold=True), fill=color)


def ellipse_label(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    text: str,
    outline: str = BLUE,
    fill: str = "#f8fbff",
    text_fill: str = BLACK,
) -> None:
    draw.ellipse(box, outline=outline, fill=fill, width=3)
    draw_centered_text(draw, box, text, font(24), fill=text_fill)


def add_title(draw: ImageDraw.ImageDraw, size: tuple[int, int], title: str) -> None:
    draw_centered_text(draw, (0, 16, size[0], 70), title, font(34, bold=True), fill=NAVY)


def create_use_case(path: Path) -> None:
    size = (1541, 1112)
    img = Image.new("RGBA", size, "white")
    draw = ImageDraw.Draw(img)
    add_title(draw, size, "Figure 5.1: MeetFlow AI - Use Case Diagram")

    actor(draw, (112, 480), NAVY, "Primary User")
    actor(draw, (1430, 200), GREEN, "Firebase Auth")
    actor(draw, (1430, 510), GREEN, "Cloud Firestore")
    actor(draw, (1430, 820), BLUE, "Gemini AI\nvia Firebase AI")

    boundary = (250, 92, 1275, 1080)
    rounded_box(draw, boundary, fill=LIGHT, outline=NAVY, width=4, radius=20)
    draw_centered_text(draw, (500, 102, 1025, 148), "MeetFlow AI System", font(30, bold=True), fill=NAVY)

    left_cases = [
        ("Register Account", 420, 180),
        ("Log In", 420, 285),
        ("Reset Password", 420, 390),
        ("Import Meeting\nfrom File", 420, 505),
        ("Import Meeting\nfrom Link", 420, 650),
        ("View Meeting History", 420, 785),
        ("View Meeting Details", 420, 890),
        ("Update Task Status", 420, 995),
    ]
    right_cases = [
        ("Validate Credentials", 940, 180, MINT, GREEN),
        ("Persist User Profile", 940, 300, MINT, GREEN),
        ("Analyze Meeting\nContent", 940, 470, PEACH, ORANGE),
        ("Detect Meeting\nLanguage", 940, 620, PEACH, ORANGE),
        ("Save Meeting,\nDecisions and Tasks", 940, 800, SKY, BLUE),
        ("Delete Meeting", 940, 940, SKY, BLUE),
    ]

    for text, x, y in left_cases:
        ellipse_label(draw, (x, y, x + 290, y + 76), text, outline=BLUE, fill="#f7fbff")
    for text, x, y, fill_color, outline in right_cases:
        ellipse_label(draw, (x, y, x + 290, y + 84), text, outline=outline, fill=fill_color)

    user_anchor = (160, 560)
    for _, x, y in left_cases:
        arrow(draw, user_anchor, (x, y + 38), fill=GRAY, width=3)

    import_file_mid = (710, 543)
    import_link_mid = (710, 688)
    analyze_anchor = (940, 512)
    detect_anchor = (940, 662)
    save_anchor = (940, 842)

    for start in [import_file_mid, import_link_mid]:
        arrow(draw, start, analyze_anchor, fill=BLUE, width=3, dashed=True)
        arrow(draw, start, detect_anchor, fill=ORANGE, width=3, dashed=True)
        arrow(draw, start, save_anchor, fill=GREEN, width=3, dashed=True)

    arrow(draw, (1230, 222), (1385, 220), fill=GREEN, width=3)
    arrow(draw, (1230, 342), (1385, 355), fill=GREEN, width=3)
    arrow(draw, (1230, 840), (1385, 555), fill=GREEN, width=3)
    arrow(draw, (1230, 512), (1385, 865), fill=BLUE, width=3)
    arrow(draw, (1230, 662), (1385, 865), fill=BLUE, width=3)

    note_font = font(20)
    draw.text((760, 558), "<<include>>", font=note_font, fill=BLUE)
    draw.text((760, 703), "<<include>>", font=note_font, fill=BLUE)

    img.save(path)


def entity_box(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    title: str,
    lines: list[str],
    header_fill: str,
    outline: str,
) -> None:
    x1, y1, x2, y2 = box
    rounded_box(draw, box, fill="white", outline=outline, width=3, radius=16)
    draw.rounded_rectangle((x1, y1, x2, y1 + 58), radius=16, fill=header_fill, outline=outline, width=3)
    draw.rectangle((x1, y1 + 34, x2, y1 + 58), fill=header_fill, outline=header_fill)
    draw_centered_text(draw, (x1, y1 + 6, x2, y1 + 52), title, font(24, bold=True), fill="white")
    y = y1 + 78
    for line in lines:
        draw.text((x1 + 18, y), line, font=font(18), fill=BLACK)
        y += 36


def create_data_model(path: Path) -> None:
    size = (1541, 1032)
    img = Image.new("RGBA", size, "white")
    draw = ImageDraw.Draw(img)
    add_title(draw, size, "Figure 5.2: MeetFlow AI Data Model and Firestore Paths")

    entity_box(
        draw,
        (80, 110, 450, 372),
        "AppUser",
        ["id : String", "name : String", "email : String", "createdAt : Timestamp", "updatedAt : Timestamp"],
        NAVY,
        NAVY,
    )
    entity_box(
        draw,
        (540, 110, 980, 600),
        "Meeting",
        [
            "id : String",
            "userId : String (FK)",
            "title : String",
            "sourceType : file | link",
            "status : draft | processing | completed | failed",
            "shortSummary : String",
            "detailedSummary : String",
            "minutesOfMeeting : String[]",
            "participants : String[]",
            "followUps : String[]",
            "createdAt / updatedAt / processedAt",
        ],
        BLUE,
        BLUE,
    )
    entity_box(
        draw,
        (80, 625, 450, 900),
        "Decision",
        ["id : String", "text : String", "owner : String", "createdAt : Timestamp"],
        GREEN,
        GREEN,
    )
    entity_box(
        draw,
        (580, 625, 1040, 980),
        "MeetingTask",
        [
            "id : String",
            "meetingId : String (FK)",
            "meetingTitle : String",
            "title : String",
            "description : String",
            "assignee : String",
            "dueDate : String",
            "priority : low | medium | high",
            "status : pending | inProgress | completed",
            "createdAt / updatedAt",
        ],
        ORANGE,
        ORANGE,
    )

    draw.line((450, 320, 540, 320), fill=BLUE, width=4)
    draw.text((470, 285), "1 user owns many meetings", font=font(19, bold=True), fill=BLUE)
    draw.text((505, 332), "1..*", font=font(17), fill=BLUE)

    draw.line((760, 600, 760, 625), fill=GREEN, width=4)
    draw.line((760, 625, 450, 760), fill=GREEN, width=4)
    draw.text((500, 700), "1 meeting has many decisions", font=font(19, bold=True), fill=GREEN)

    draw.line((840, 600, 840, 625), fill=ORANGE, width=4)
    draw.line((840, 625, 1040, 760), fill=ORANGE, width=4)
    draw.text((930, 700), "1 meeting has many tasks", font=font(19, bold=True), fill=ORANGE)

    notes = [
        ("users/{uid}", 1010, 170, GREEN),
        ("users/{uid}/meetings/{mid}", 1010, 335, GREEN),
        ("users/{uid}/meetings/{mid}/decisions/{id}", 1010, 520, GREEN),
        ("users/{uid}/meetings/{mid}/tasks/{id}", 1010, 675, GREEN),
        ("users/{uid}/tasks/{id}   duplicated for global Tasks tab", 1010, 835, ORANGE),
    ]
    for text, x, y, color in notes:
        rounded_box(draw, (x, y, 1500, y + 62), fill="#f9fcf7", outline=color, width=3, radius=12)
        draw_centered_text(draw, (x + 10, y + 6, 1490, y + 56), text, font(20), fill=BLACK)

    draw.text((1110, 925), "Batch write keeps meeting tasks and user tasks synchronized.", font=font(18), fill=ORANGE)
    img.save(path)


def lifeline(draw: ImageDraw.ImageDraw, x: int, title: str, subtitle: str, color: str, top: int, bottom: int) -> None:
    rounded_box(draw, (x - 110, top, x + 110, top + 72), fill="#f8fbff", outline=color, width=3, radius=12)
    draw_centered_text(draw, (x - 100, top + 8, x + 100, top + 38), title, font(20, bold=True), fill=BLACK)
    draw_centered_text(draw, (x - 100, top + 34, x + 100, top + 64), subtitle, font(16), fill=GRAY)
    arrow(draw, (x, top + 72), (x, bottom), fill=color, width=2, dashed=True)


def message(draw: ImageDraw.ImageDraw, x1: int, x2: int, y: int, text: str, color: str = NAVY, dashed: bool = False) -> None:
    arrow(draw, (x1, y), (x2, y), fill=color, width=3, dashed=dashed)
    draw.text((min(x1, x2) + 10, y - 28), text, font=font(18), fill=color)


def create_sequence(path: Path) -> None:
    size = (1657, 1228)
    img = Image.new("RGBA", size, "white")
    draw = ImageDraw.Draw(img)
    add_title(draw, size, "Figure 5.4: Sequence Diagram - Import Meeting from File")

    xs = [120, 390, 650, 930, 1220, 1490]
    labels = [
        ("User", "actor", GRAY),
        ("Import Page", "UI", BLUE),
        ("MeetingImportNotifier", "Riverpod provider", NAVY),
        ("MeetingsRepository", "Firestore repository", BLUE),
        ("GeminiService", "Firebase AI Logic", ORANGE),
        ("Cloud Firestore", "database", GREEN),
    ]
    for x, (title, subtitle, color) in zip(xs, labels):
        lifeline(draw, x, title, subtitle, color, 104, 1140)

    success_box = (520, 180, 1580, 770)
    rounded_box(draw, success_box, fill="#fbfdff", outline=BLUE, width=2, radius=14)
    draw.text((538, 190), "Success path", font=font(20, bold=True), fill=BLUE)

    y = 210
    step = 78
    message(draw, xs[0], xs[1], y, "1. pickFile()", NAVY)
    y += step
    message(draw, xs[1], xs[2], y, "2. processFile(file, title, date)", NAVY)
    y += step
    message(draw, xs[2], xs[3], y, "3. createDraftMeeting(draft)", BLUE)
    y += step
    message(draw, xs[3], xs[5], y, "4. set meeting status = processing", GREEN)
    y += step
    message(draw, xs[2], xs[4], y, "5. processMeetingFile(file)", ORANGE)
    y += step
    message(draw, xs[4], xs[2], y, "6. aiResult JSON", ORANGE, dashed=True)
    y += step
    message(draw, xs[2], xs[3], y, "7. saveMeetingResult(aiResult)", BLUE)
    y += step
    message(draw, xs[3], xs[5], y, "8. batch update meeting + decisions + tasks", GREEN)
    y += step
    message(draw, xs[5], xs[1], y, "9. snapshots() update UI", GREEN, dashed=True)
    y += step
    message(draw, xs[2], xs[1], y, "10. done", NAVY, dashed=True)

    error_box = (520, 845, 1220, 1090)
    rounded_box(draw, error_box, fill=PINK, outline=RED, width=3, radius=16)
    draw.text((545, 860), "Alternative error path", font=font(20, bold=True), fill=RED)
    draw.text((545, 905), "If Gemini or persistence fails after the draft meeting is created:", font=font(18), fill=BLACK)
    message(draw, xs[2], xs[3], 960, "markMeetingFailed(meetingId)", RED)
    message(draw, xs[3], xs[5], 1025, "update status = failed", RED)
    message(draw, xs[2], xs[1], 1080, "state = error message", RED, dashed=True)

    img.save(path)


def layer_band(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    title: str,
    fill: str,
    outline: str,
) -> None:
    rounded_box(draw, box, fill=fill, outline=outline, width=3, radius=18)
    draw.text((box[0] + 20, box[1] + 18), title, font=font(28, bold=True), fill=outline)


def small_box(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], title: str, subtitle: str, outline: str) -> None:
    rounded_box(draw, box, fill="white", outline=outline, width=3, radius=12)
    draw_centered_text(draw, (box[0] + 8, box[1] + 6, box[2] - 8, box[1] + 36), title, font(19, bold=True), fill=BLACK)
    draw_centered_text(draw, (box[0] + 8, box[1] + 32, box[2] - 8, box[3] - 6), subtitle, font(15), fill=GRAY)


def create_component(path: Path) -> None:
    size = (1657, 1112)
    img = Image.new("RGBA", size, "white")
    draw = ImageDraw.Draw(img)
    add_title(draw, size, "Figure 5.5: Layered Component Diagram - Feature-First Clean Architecture")

    layer_band(draw, (26, 100, 1630, 350), "Presentation Layer", SKY, BLUE)
    layer_band(draw, (26, 380, 1630, 635), "Domain Layer", MINT, GREEN)
    layer_band(draw, (26, 665, 1630, 955), "Data Layer", PEACH, ORANGE)
    layer_band(draw, (26, 980, 1630, 1085), "Shared App and Core", "#f4f5f7", GRAY)

    cols = [
        ("auth", 170, NAVY),
        ("meeting_import", 420, NAVY),
        ("meetings", 670, BLUE),
        ("tasks", 920, ORANGE),
        ("settings", 1170, GRAY),
    ]

    for name, x, color in cols:
        rounded_box(draw, (x - 80, 76, x + 80, 108), fill="white", outline=color, width=2, radius=10)
        draw_centered_text(draw, (x - 70, 80, x + 70, 104), f"feature/{name}", font(18, bold=True), fill=color)

        small_box(draw, (x - 110, 170, x + 110, 245), "Pages", "screens and widgets", color)
        small_box(draw, (x - 110, 265, x + 110, 340), "Providers", "Riverpod state", color)
        arrow(draw, (x, 340), (x, 430), fill=color, width=3)

        small_box(draw, (x - 110, 455, x + 110, 530), "Entities", "business models", GREEN)
        small_box(draw, (x - 110, 545, x + 110, 620), "Repository Contract", "domain-facing API", GREEN)
        arrow(draw, (x, 620), (x, 715), fill=color, width=3)

        data_title = "Repository Impl"
        data_subtitle = "Firebase / persistence"
        if name == "meeting_import":
            data_title = "Services + Repos"
            data_subtitle = "Gemini + file picker + meetings repo"
        small_box(draw, (x - 110, 730, x + 110, 810), data_title, data_subtitle, ORANGE)
        small_box(draw, (x - 110, 845, x + 110, 920), "DTO / Firestore Mapping", "toFirestore / fromFirestore", ORANGE)

    small_box(draw, (1310, 170, 1510, 245), "GoRouter", "app_router.dart", NAVY)
    small_box(draw, (1310, 275, 1510, 350), "MeetFlowApp", "MaterialApp.router", NAVY)
    arrow(draw, (1410, 350), (1410, 430), fill=GRAY, width=3)
    small_box(draw, (1310, 455, 1510, 530), "AppUser", "shared auth identity", GREEN)
    small_box(draw, (1310, 730, 1510, 810), "FirebaseAuth / Firestore", "backend services", ORANGE)

    core_items = [
        ("app/router", 270),
        ("core/services", 560),
        ("core/theme", 850),
        ("core/errors", 1140),
        ("core/widgets + utils", 1415),
    ]
    for label, x in core_items:
        small_box(draw, (x - 120, 1008, x + 120, 1068), label, "", GRAY)

    img.save(path)


def replace_media(docx_path: Path, output_path: Path, replacements: dict[str, Path]) -> None:
    shutil.copyfile(docx_path, output_path)
    temp_path = output_path.with_suffix(".tmp.docx")
    with zipfile.ZipFile(output_path, "r") as zin, zipfile.ZipFile(temp_path, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename in replacements:
                data = replacements[item.filename].read_bytes()
            zout.writestr(item, data)
    temp_path.replace(output_path)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    use_case = OUT_DIR / "image2.png"
    data_model = OUT_DIR / "image13.png"
    sequence = OUT_DIR / "image1.png"
    component = OUT_DIR / "image5.png"

    create_use_case(use_case)
    create_data_model(data_model)
    create_sequence(sequence)
    create_component(component)

    replace_media(
        SOURCE_DOCX,
        OUTPUT_DOCX,
        {
            "word/media/image2.png": use_case,
            "word/media/image13.png": data_model,
            "word/media/image1.png": sequence,
            "word/media/image5.png": component,
        },
    )
    print(OUTPUT_DOCX)


if __name__ == "__main__":
    main()
