# Apricot: Window Snapper (+ other tools soon) for macOS

I used mac for most of my life, but then got a windows PC for my work laptop. They have this great too where if you press the windows key +arrow key, it will snap the window you are working on to the top / bottom of your screen or other monitor. 

I'd never built anything for MacOS so I thought it would be cool to do, and I knew I would use it. Feel free to use. 

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
