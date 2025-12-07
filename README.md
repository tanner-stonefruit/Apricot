# Apricot 🍑 — Stonefruit Window Snapper for macOS

A tiny **menubar** app that snaps the frontmost window into clean layouts via global hotkeys. Built to scratch the “Magnet-lite” itch and practice native macOS patterns (SwiftUI + AppKit + Carbon hotkeys + AX).

---

## Features (v1)

- **Halves:** `⌘⌥←` / `⌘⌥→` / `⌘⌥↑` / `⌘⌥↓`
- **Corners:** `⌘⌥⇧←` / `⌘⌥⇧→` / `⌘⌥⇧↓` / `⌘⌥⇧↑`
- **Maximize (fit visible frame):** `⌘⌥⏎`
- **Center 70%:** `⌘⌥C`
- **Multi-monitor aware:** snaps on the **screen under the mouse**
- **Preferences window:**
  - Choose **modifier combo** (⌘⌥ / ⌘⌃ / ⌘⇧⌥ / ⌘⌥⌃)
  - Toggle **corner snaps**
  - Buttons: **Grant Accessibility…**, **Open Login Items…**
- **Menubar icon:** template-tinted stonefruit glyph

> Some apps (fullscreen, special overlays) may ignore Accessibility window moves — that’s normal.

---

## Requirements

- macOS Ventura or newer recommended
- Accessibility permission (granted on first run)
- Xcode (Swift + SwiftUI + AppKit; uses Carbon hotkeys)

---

## Dev: Build & Run

1. Open in Xcode → **Run (⌘R)**.
2. On first launch, macOS will prompt for **Accessibility**. Enable:
   - **System Settings → Privacy & Security → Accessibility → Apricot**.
3. Menubar shows the stonefruit icon. Click → **Preferences…** to configure.

**Menubar app setup notes**
