# Beacon

**Live accessibility health monitor that lives in your MacBook notch.**

Beacon is a macOS app (no dock icon) that watches the frontmost application and displays a real-time accessibility health indicator inside the MacBook Pro notch. Switch apps and Beacon instantly tells you whether the new app has accessibility gaps — visible text that screen readers can't see.

## The Four-Way Chimera

Beacon combines ideas from four open-source projects into something new:

| Source | What we borrowed |
|--------|-----------------|
| **[AXray](https://github.com/deamonseed1973/axray)** | Visitor-pattern AX tree walking with cycle detection, parallel Vision OCR pipeline |
| **[Peekaboo](https://github.com/steipete/Peekaboo)** | AcceleratedTextDetector (Sobel edge detection via Accelerate/vImage for fast CPU text presence), SmartLabelPlacer (non-overlapping label annotation) |
| **[boring.notch](https://github.com/TheBoredTeam/boring.notch)** | Notch geometry calculation using `auxiliaryTopLeftArea`/`auxiliaryTopRightArea`, hover-triggered open/closed state machine |
| **[Atoll](https://github.com/Ebullioscopic/Atoll)** | Compact ↔ expanded transitions, NSWindow anchored to the notch cutout |

No code is imported from these projects — Beacon is a clean-room reimplementation inspired by their designs.

## How It Works

When you switch to a new app, Beacon:

1. **Walks the AX accessibility tree** of the frontmost application
2. **Captures on-screen bounds** of each element that lacks AX text labels
3. **Runs a fast Sobel edge detector** (AcceleratedTextDetector) as a pre-pass — much faster than Vision
4. **Runs Vision OCR** (`VNRecognizeTextRequest`) only on regions that pass the edge density check
5. **Displays a health dot** in the notch:
   - 🟢 **Green** — no accessibility gaps found
   - 🟡 **Yellow** — minor gaps (< 5% of elements)
   - 🔴 **Red** — critical gaps
6. **On hover**, expands below the notch showing the app name, issue count, and an annotated screenshot thumbnail
7. **Export** saves an annotated PNG + JSON report to `~/Desktop/beacon-reports/`

## Building

Beacon is a Swift Package (not an Xcode project). It uses only system frameworks — no external dependencies.

```bash
swift build -c release
```

Run the built binary:

```bash
.build/release/Beacon
```

### Requirements

- macOS 13.0 (Ventura) or later
- MacBook Pro with notch (works on non-notch Macs too, with a slim menu-bar widget)
- **Accessibility permission** — System Settings → Privacy & Security → Accessibility → add Beacon
- **Screen Recording permission** — System Settings → Privacy & Security → Screen Recording → add Beacon

## Architecture

```
Sources/Beacon/
├── main.swift                      — NSApplication + .accessory policy
├── App/
│   └── AppDelegate.swift           — creates NotchWindow, sets up AppMonitor
├── Notch/
│   ├── NotchGeometry.swift         — measures actual notch from auxiliaryTopLeftArea/Right
│   ├── NotchWindow.swift           — NSWindow subclass pinned to notch
│   └── NotchHostingController.swift — bridges SwiftUI into the NSWindow
├── Views/
│   ├── NotchView.swift             — root SwiftUI view: compact/expanded states
│   ├── NotchViewModel.swift        — observable state for the notch UI
│   ├── CompactView.swift           — colored health dot + issue count
│   └── ExpandedView.swift          — app name, summary, screenshot, export button
├── Core/
│   ├── AXElement.swift             — AXUIElement wrapper (role/title/value/frame/children)
│   ├── AXTreeWalker.swift          — visitor-pattern traversal with cycle detection
│   └── AppMonitor.swift            — watches NSWorkspace.didActivateApplication
├── Scanner/
│   ├── AccessibilityScanner.swift  — orchestrates AX walk → TextDetector → Vision
│   ├── ElementCapture.swift        — captures CGImage for an element's screen bounds
│   └── TextDetector.swift          — Sobel edge detection (Accelerate/vImage)
├── Annotator/
│   └── ScreenAnnotator.swift       — draws labeled bounding boxes (SmartLabelPlacer)
└── Report/
    ├── AuditReport.swift           — Codable model with health scoring
    └── ReportExporter.swift        — saves JSON + annotated PNG to ~/Desktop
```

## Why This Combination Is Interesting

Most accessibility tools are batch auditors — you run them, wait, read a report. Beacon is **ambient**. By living in the notch, it gives you continuous awareness of accessibility health as you work, the way a battery indicator shows charge level.

The pipeline is fast because of the two-stage detection: the Accelerate-based Sobel edge detector filters out blank regions in microseconds, so the expensive Vision OCR only runs on elements that likely contain visible text. This makes real-time monitoring feasible.

The combination of **AX structural knowledge** (what the accessibility system *thinks* is there) with **Vision visual reading** (what's actually *visible* on screen) catches the exact gaps that matter: text that sighted users can see but screen reader users cannot.

## License

MIT
