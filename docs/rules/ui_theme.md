# UI Theme Rules

Use **Material 3**.

The app should feel modern, calm, professional, and suitable for productivity and business users.

---

## Brand Style

**App name:** MeetFlow AI

**Design feeling:**
- Clean
- Smart
- Minimal
- Professional
- Slightly futuristic
- Not childish or gamified

---

## Color Palette

### Primary Colors
| Name | Hex |
|------|-----|
| Primary (Indigo) | `#4F46E5` |
| Primary Dark (Deep Indigo) | `#3730A3` |
| Secondary (Cyan) | `#06B6D4` |

### Light Theme
| Name | Hex |
|------|-----|
| Background | `#F8FAFC` |
| Surface | `#FFFFFF` |
| Text Primary | `#0F172A` |
| Text Secondary | `#64748B` |

### Dark Theme
| Name | Hex |
|------|-----|
| Background | `#0F172A` |
| Surface | `#1E293B` |
| Text Primary | `#F8FAFC` |
| Text Secondary | `#CBD5E1` |

### Semantic Colors
| Name | Hex |
|------|-----|
| Success | `#22C55E` |
| Warning | `#F59E0B` |
| Error | `#EF4444` |
| Info | `#3B82F6` |

---

## Theme Requirements

### Create these three files:
- `core/theme/app_colors.dart`
- `core/theme/app_theme.dart`
- `core/theme/app_text_styles.dart`

### Support:
- ✅ Light theme
- ✅ Dark theme
- ✅ Material 3
- ✅ Rounded cards
- ✅ Soft shadows
- ✅ Large, clear buttons
- ✅ Clean, minimal input fields
- ✅ Responsive layout

---

## UI Rules

### Use:
- **Cards** for meeting summaries, tasks, and stats
- **Chips** for statuses (draft / processing / completed / failed) and priorities (low / medium / high)
- **Empty states** with illustration placeholder and helpful message
- **Loading states** with shimmer or spinner
- **Error states** with message and retry action
- **Clear CTAs** (Call to Action buttons) — large, labeled, with icons

### Avoid:
- Too many colors on one screen
- Heavy, distracting gradients
- Crowded, cluttered layouts
- Hardcoded text styles inline in widgets
- Hardcoded color values inline in widgets
- Deeply nested widget trees

---

## Screen-by-Screen Style Guide

### Auth Screens (Login / Register / Forgot Password)
- Centered layout
- App logo / title at the top
- Simple illustration placeholder (or icon)
- Clean input fields with labels
- Primary CTA button (full width)
- Secondary link (e.g., "Don't have an account? Register")

### Home Screen
- Dashboard layout with vertical scroll
- Header with welcome text and profile button
- Quick action cards in a 2×2 grid or horizontal scroll
- Stats cards in a row
- Recent meetings list
- Task overview section

### Import Meeting Screen
Two large tap cards:
1. 📁 Upload audio/video file
2. 🔗 Paste meeting link

Below: Optional title and date fields, then a "Generate" button.

### Meeting Details Screen
Scrollable page with expandable/collapsible sections:
- Summary (collapsed by default if long)
- Minutes of Meeting
- Decisions
- Tasks
- Participants
- Follow-ups

Each section has a section header, icon, and content area.

### Tasks Screen
- Filter chips row at the top (by status and priority)
- List of `TaskCard` widgets
- Each card shows: title, assignee, due date, priority chip, status badge, action button

### Settings Screen
- Profile card at the top (avatar, name, email)
- List tiles for: Theme, About, Logout
- API info note at the bottom (text only, no keys)

---

## Typography

Use a clean, modern sans-serif font from Google Fonts.

Recommended: **Inter** or **Outfit**

| Style | Usage |
|-------|-------|
| `headlineLarge` | Page titles |
| `headlineMedium` | Section titles |
| `titleLarge` | Card titles |
| `titleMedium` | List item titles |
| `bodyLarge` | Body text, summaries |
| `bodyMedium` | Secondary text, descriptions |
| `labelLarge` | Button labels |
| `labelSmall` | Chips, tags |
